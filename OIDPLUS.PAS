program OIDPLUS;

(************************************************)
(* OIDPLUS.PAS                                  *)
(* Author:   Daniel Marschall                   *)
(* Revision: 2022-02-19                         *)
(* License:  Apache 2.0                         *)
(* This file contains:                          *)
(* - "OIDplus for DOS" program                  *)
(************************************************)

(* IMPORTANT:                                                  *)
(* When you compile this code with Turbo Pascal 7.01,          *)
(* it won't run on fast PCs (Runtime Error 200).               *)
(* The built EXE file needs to be patched.                     *)
(* The program "PatchCRT" by Kennedy Software                  *)
(* WON'T work because it somehow breaks our "_Pause" function. *)
(* Instead, use the tool "TPPATCH" by Andreas Bauer.           *)

uses
  Dos, Crt, Drivers, StrList, VtsFuncs, VtsCui, OidFile, OidUtils,
  Weid;

const
  VERSIONINFO            = 'Revision: 2022-02-19';
  DEFAULT_STATUSBAR      = '(C)2020-2022 ViaThinkSoft. Licensed under the terms of the Apache 2.0 license.';
  TITLEBAR_LEFT_TEXT     = 'OIDplus';
  DISKIO_SOUND_DEBUGGING = false;
  DISKIO_SOUND_DELAY     = 500;
  ASNEDIT_LINES          = 10;
  DESCEDIT_LINES         = 10;
  DESCEDIT_PADDING       = 3;
  ACTIONMENU_SIZE        = 5;
  MAINMENU_WIDTH         = 15;
  MAINMENU_HEIGHT        = 3;
  MAINMENU_ALLOW_ESC     = false;
  TREEVIEW_INDENT        = 0;
  TREEVIEW_INCLUDE_DESC  = true;
  TREEVIEW_WIDTH         = 80;
  OID_EXTENSION          = '.OID';
  TREEVIEW_FILENAME      = 'OIDTREE.TXT';

procedure _Pause;
begin
  DrawStatusBar('Press any key to continue');
  CursorOn;
  ReadKey;
  CursorOff;
  DrawStatusBar(DEFAULT_STATUSBAR);
end;

function _WriteOidFile(filename: string; oid: POid; ShowErrorMessage: boolean): boolean;
var
  res: boolean;
begin
  DrawStatusBar('Write file ' + filename + '...');
  res := WriteOidFile(filename, oid);
  if DISKIO_SOUND_DEBUGGING then
  begin
    Sound(70);
    Delay(DISKIO_SOUND_DELAY - 10);
    NoSound;
    Delay(10);
  end;
  DrawStatusBar(DEFAULT_STATUSBAR);

  _WriteOidFile := res;

  if ShowErrorMessage and not res then
  begin
    ShowMessage('Cannot write to file ' + filename, 'ERROR', true);
    _Pause;
  end;
end;

function _ReadOidFile(filename: string; oid: POid; ShowErrorMessage: boolean): boolean;
var
  res: boolean;
begin
  DrawStatusBar('Read file ' + filename + '...');
  res := ReadOidFile(filename, oid);
  if DISKIO_SOUND_DEBUGGING then
  begin
    Sound(50);
    Delay(DISKIO_SOUND_DELAY - 10);
    NoSound;
    Delay(10);
  end;
  DrawStatusBar(DEFAULT_STATUSBAR);

  _ReadOidFile := res;

  if ShowErrorMessage and not res then
  begin
    ShowMessage('Cannot read file ' + filename, 'ERROR', true);
    _Pause;
  end;
end;

function _ShowASNIds(childOID: POID): string;
var
  j, jmax: integer;
  sTmp: string;
begin
  sTmp := '';
  jmax := ListCount(childOID^.ASNIds)-1;
  for j := 0 to jmax do
  begin
    if j = 0 then sTmp := sTmp + ' (';
    sTmp := sTmp + ListGetElement(childOID^.ASNIds, j);
    if j = jmax then
      sTmp := sTmp + ')'
    else
      sTmp := sTmp + ', ';
  end;
  _ShowASNIds := sTmp;
end;

function AsnAlreadyExisting(oid: POID; asnid: string): boolean;
begin
  AsnAlreadyExisting := ListContains(oid^.AsnIds, asnid);
end;

function AsnEditor(oid: POID): boolean;
var
  asnList: PStringList;
  i: integer;
  x, y, w, h: integer;
  res: integer;
  sInput: string;
  menuIdNew, menuIdSave, menuIdExit: integer;
begin
  AsnEditor := false;

  repeat
    CreateList(asnList);

    for i := 0 to ListCount(oid^.ASNIds)-1 do
    begin
      ListAppend(asnList, ListGetElement(oid^.ASNIDs, i));
    end;
    menuIdNew  := ListAppend(asnList, '<NEW>');
    menuIdSave := ListAppend(asnList, '<SAVE>');
    menuIdExit := ListAppend(asnList, '<CANCEL>');

    DrawStatusBar(DEFAULT_STATUSBAR);
    x := SINGLE_LINE_BOX_PADDING;
    y := ScreenHeight div 2 - ASNEDIT_LINES div 2;
    w := ScreenWidth - (SINGLE_LINE_BOX_PADDING-1)*2;
    h := ASNEDIT_LINES;
    res := DrawSelectionList(x, y, w, h,
                             asnList, true,
                             'EDIT ASN.1 IDENTIFIERS',
                             2);
    FreeList(asnList);

    (* Change double-border to thin-border *)
    DrawThinBorder(x-1, y-1, w+2, h+2);
    GoToXY(x+1, y-1);
    Write('EDIT ASN.1 IDENTIFIERS');

    if res = -1 then
    begin
      exit;
    end
    else if res = menuIdNew then
    begin
      (* "NEW" item was selected *)
      sInput := '';
      CursorOn;
      repeat
        if QueryVal(sInput,
                    SINGLE_LINE_BOX_PADDING_INNER,
                    ScreenHeight div 2,
                    ScreenWidth - (SINGLE_LINE_BOX_PADDING_INNER-1)*2,
                    1,
                    'ADD SINGLE ASN.1 ID',
                    2) then
        begin
          if sInput = '' then continue;
          if not ASN1IDValid(sInput) then
          begin
            ShowMessage('Invalid ASN1.ID! (Require -, a..z, A..Z, 0..9, begin with a-z)', 'ERROR', true);
            _Pause;
          end
          else if AsnAlreadyExisting(oid, sInput) then
          begin
            ShowMessage('ASN.1 identifier is already existing on this arc', 'ERROR', true);
            _Pause;
          end
          else
          begin
            ListAppend(oid^.ASNIDs, sInput);
            break;
          end;
        end
        else break;
      until false;
      CursorOff;
    end
    else if res = menuIdSave then
    begin
      (* "SAVE" item was selected *)
      AsnEditor := true;
      Exit;
    end
    else if res = menuIdExit then
    begin
      (* "CANCEL" item was selected *)
      AsnEditor := false;
      Exit;
    end
    else
    begin
      DrawStatusBar('Note: Remove the text to delete the ASN.1 identifier');
      sInput := ListGetElement(oid^.ASNIDs, res);
	  CursorOn;
      repeat
        if QueryVal(sInput,
                    SINGLE_LINE_BOX_PADDING_INNER,
                    ScreenHeight div 2,
                    ScreenWidth - (SINGLE_LINE_BOX_PADDING_INNER-1)*2,
                    1,
                    'EDIT SINGLE ASN.1 ID',
                    2) then
        begin
          if sInput = '' then
          begin
            (* Empty input = Delete ASN.1 ID *)
            ListDeleteElementByIndex(oid^.ASNIDs, res);
            break;
          end
          else if not ASN1IDValid(sInput) then
          begin
            ShowMessage('Invalid ASN1.ID! (Require -, a..z, A..Z, 0..9, begin with a-z)', 'ERROR', true);
            _Pause;
          end
          else if AsnAlreadyExisting(oid, sInput) and
              not (ListGetElement(oid^.ASNIDs, res) = sInput) then
          begin
            ShowMessage('ASN.1 identifier is already existing on this arc', 'ERROR', true);
            _Pause;
          end
          else
          begin
            ListSetElement(oid^.ASNIDs, res, sInput);
            break;
          end;
        end
        else break;
      until false;
	  CursorOff;
    end;
  until false;
end;

function UnicodeLabelAlreadyExisting(oid: POID; unicodeLabel: string): boolean;
begin
  UnicodeLabelAlreadyExisting := ListContains(oid^.UnicodeLabels, unicodeLabel);
end;

function IriEditor(oid: POID): boolean;
var
  iriList: PStringList;
  i: integer;
  x, y, w, h: integer;
  res: integer;
  sInput: string;
  menuIdNew, menuIdSave, menuIdExit: integer;
begin
  IriEditor := false;

  repeat
    CreateList(iriList);

    for i := 0 to ListCount(oid^.UnicodeLabels)-1 do
    begin
      ListAppend(iriList, ListGetElement(oid^.UnicodeLabels, i));
    end;
    menuIdNew  := ListAppend(iriList, '<NEW>');
    menuIdSave := ListAppend(iriList, '<SAVE>');
    menuIdExit := ListAppend(iriList, '<CANCEL>');

    DrawStatusBar(DEFAULT_STATUSBAR);
    x := SINGLE_LINE_BOX_PADDING;
    y := ScreenHeight div 2 - ASNEDIT_LINES div 2;
    w := ScreenWidth - (SINGLE_LINE_BOX_PADDING-1)*2;
    h := ASNEDIT_LINES;
    res := DrawSelectionList(x, y, w, h,
                             iriList, true,
                             'EDIT UNICODE LABELS',
                             2);
    FreeList(iriList);

    (* Change double-border to thin-border *)
    DrawThinBorder(x-1, y-1, w+2, h+2);
    GoToXY(x+1, y-1);
    Write('EDIT UNICODE LABELS');

    if res = -1 then
    begin
      exit;
    end
    else if res = menuIdNew then
    begin
      (* "NEW" item was selected *)
      sInput := '';
      CursorOn;
      repeat
        if QueryVal(sInput,
                    SINGLE_LINE_BOX_PADDING_INNER,
                    ScreenHeight div 2,
                    ScreenWidth - (SINGLE_LINE_BOX_PADDING_INNER-1)*2,
                    1,
                    'ADD SINGLE UNICODE LABEL',
                    2) then
        begin
          if sInput = '' then continue;
          if not UnicodeLabelValid(sInput) then
          begin
            ShowMessage('Invalid Unicode Label!', 'ERROR', true);
            _Pause;
          end
          else if UnicodeLabelAlreadyExisting(oid, sInput) then
          begin
            ShowMessage('Unicode Label is already existing on this arc', 'ERROR', true);
            _Pause;
          end
          else
          begin
            ListAppend(oid^.UnicodeLabels, sInput);
            break;
          end;
        end
        else break;
      until false;
      CursorOff;
    end
    else if res = menuIdSave then
    begin
      (* "SAVE" item was selected *)
      IriEditor := true;
      Exit;
    end
    else if res = menuIdExit then
    begin
      (* "CANCEL" item was selected *)
      IriEditor := false;
      Exit;
    end
    else
    begin
      DrawStatusBar('Note: Remove the text to delete the Unicode Label');
      sInput := ListGetElement(oid^.UnicodeLabels, res);
	  CursorOn;
      repeat
        if QueryVal(sInput,
                    SINGLE_LINE_BOX_PADDING_INNER,
                    ScreenHeight div 2,
                    ScreenWidth - (SINGLE_LINE_BOX_PADDING_INNER-1)*2,
                    1,
                    'EDIT SINGLE UNICODE LABEL',
                    2) then
        begin
          if sInput = '' then
          begin
            (* Empty input = Delete Unicode label *)
            ListDeleteElementByIndex(oid^.UnicodeLabels, res);
            break;
          end
          else if not UnicodeLabelValid(sInput) then
          begin
            ShowMessage('Invalid Unicode Label!', 'ERROR', true);
            _Pause;
          end
          else if UnicodeLabelAlreadyExisting(oid, sInput) and
              not (ListGetElement(oid^.UnicodeLabels, res) = sInput) then
          begin
            ShowMessage('Unicode Label is already existing on this arc', 'ERROR', true);
            _Pause;
          end
          else
          begin
            ListSetElement(oid^.UnicodeLabels, res, sInput);
            break;
          end;
        end
        else break;
      until false;
	  CursorOff;
    end;
  until false;
end;

function DescEditor(oid: POID): boolean;
var
  sInput: string;
begin
  DescEditor := false;

  DrawStatusBar('Note: Press Ctrl+Return for a line-break.');
  sInput := oid^.description;
  CursorOn;
  if QueryVal(sInput,
              DESCEDIT_PADDING,
              ScreenHeight div 2 - DESCEDIT_LINES div 2,
              ScreenWidth - (DESCEDIT_PADDING-1)*2,
              DESCEDIT_LINES,
              'EDIT DESCRIPTION',
              2) then
  begin
    oid^.description := sInput;
    DescEditor := true; (* request caller to save <oid> *)
  end;
  CursorOff;
end;

function NextPossibleFileID: string;
var
  DirInfo: SearchRec;
  list: PStringList;
  iId: LongInt;
  sId: string;
begin
  (* Put all found files into a list *)
  CreateList(list);
  FindFirst(RepeatStr('?',8)+OID_EXTENSION, Archive, DirInfo);
  while DosError = 0 do
  begin
    sId := Copy(DirInfo.Name, 1, 8);
    ListAppend(list, sId);
    FindNext(DirInfo);
  end;

  (* Search for the first non existing item in the list *)
  sId := '';
  for iId := 0 to 99999999 do
  begin
    sId := ZeroPad(iId, 8);
    if not ListContains(list, sId) then break;
  end;
  NextPossibleFileId := sId;
  FreeList(list);
end;

function NumIdAlreadyExisting(parentOID: POID; sInput: string): boolean;
var
  searchDotNotation: string;
  sTmp: string;
  i: integer;
begin
  if parentOID^.DotNotation = '' then
    searchDotNotation := sInput
  else
    searchDotNotation := parentOID^.DotNotation + '.' + sInput;
  for i := 0 to ListCount(parentOID^.SubIds)-1 do
  begin
    sTmp := ListGetElement(parentOID^.SubIds, i);
    if DotNotationPart(sTmp) = searchDotNotation then
    begin
      NumIdAlreadyExisting := true;
      exit;
    end;
  end;
  NumIdAlreadyExisting := false;
end;

function NumIdEditor(oid: POID; parentOID: POID): boolean;
var
  sInput: string;
begin
  NumIdEditor := false;
  sInput := '';

  CursorOn;
  repeat
    if QueryVal(sInput,
                SINGLE_LINE_BOX_PADDING_INNER,
                ScreenHeight div 2,
                ScreenWidth - (SINGLE_LINE_BOX_PADDING_INNER-1)*2,
                1,
                'ENTER NUMERIC ID',
                2) then
    begin
      if sInput = '' then continue;
      if not IsPositiveIntegerOrZero(sInput) then
      begin
        ShowMessage('Invalid numeric ID (must be a positive integer)', 'ERROR', true);
        _Pause;
      end
      else if (parentOID^.DotNotation='') and (StrToInt(sInput) > 2) then
      begin
        ShowMessage('Invalid numeric ID (root arc can only be 0, 1, or 2)', 'ERROR', true);
        _Pause;
      end
      else if ((parentOID^.DotNotation='0') or (parentOID^.DotNotation='1')) and (StrToInt(sInput) > 39) then
      begin
        ShowMessage('Invalid numeric ID (root 0 and 1 must have sub-arc of 0..39)', 'ERROR', true);
        _Pause;
      end
      else if NumIdAlreadyExisting(parentOID, sInput) then
      begin
        ShowMessage('This numeric ID is already used in this arc', 'ERROR', true);
        _Pause;
      end
      else
      begin
        if parentOID^.DotNotation = '' then
          oid^.DotNotation := sInput
        else
          oid^.DotNotation := parentOID^.DotNotation + '.' + sInput;
        NumIdEditor := true; (* request caller to save <oid> *)
        Break;
      end;
    end
    else
    begin
      Break;
    end;
  until false;
  CursorOff;
end;

function NewOidEditor(oid: POID): boolean;
var
  newfilename: string;
  newOID: POID;
begin
  NewOidEditor := false;

  CreateOidDef(newOID);
  newOID^.FileId := NextPossibleFileID;
  newOID^.ParentFileId := oid^.FileId;
  newOID^.ParentDotNotation := oid^.DotNotation;
  if NumIdEditor(newOID, oid) and
     AsnEditor(newOID) and
     IriEditor(newOID) and
     DescEditor(newOID) then
  begin
    newfilename := newOID^.FileId + OID_EXTENSION;
    if _WriteOidFile(newfilename, newOID, true) then
    begin
      (* Add link to original file and enable the saving of it *)
      ListAppend(oid^.SubIds, newOID^.FileId + newOID^.DotNotation);
      NewOidEditor := true; (* request caller to save <oid> *)
    end;
  end;
  FreeOidDef(newOID);
end;

procedure DeleteChildrenRecursive(oid: POID);
var
  i: integer;
  childOID: POID;
  filenameChild: string;
begin
  for i := 0 to ListCount(oid^.SubIds)-1 do
  begin
    filenameChild := FileIdPart(ListGetElement(oid^.SubIds, i)) + OID_EXTENSION;
    if FileExists(filenameChild) then
    begin
      CreateOidDef(childOID);
      if _ReadOidFile(filenameChild, childOID, false) and
         (childOID^.ParentFileId = oid^.FileId) and
         (childOID^.ParentDotNotation = oid^.DotNotation) then
      begin
        DeleteChildrenRecursive(childOID);
      end;
      FreeOidDef(childOID);
      DeleteFile(filenameChild);
    end;
  end;
  ListClear(oid^.SubIds);
end;

procedure DeleteOidRecursive(selfOID: POID);
var
  i: integer;
  parentOID: POID;
  filenameSelf, filenameParent: string;
begin
  (* Remove all children and their files recursively *)
  DeleteChildrenRecursive(selfOID);

  (* Remove forward reference in parent OID *)
  (* (this is the most important part)      *)
  filenameParent := selfOID^.ParentFileId + OID_EXTENSION;
  if FileExists(filenameParent) then
  begin
    CreateOidDef(parentOID);
    if _ReadOidFile(filenameParent, parentOID, true) then
    begin
      if ListDeleteElementByValue(parentOID^.SubIds, selfOID^.FileId + selfOID^.DotNotation) then
      begin
        _WriteOidFile(filenameParent, parentOID, true);
      end;
    end;
    FreeOidDef(parentOID);
  end;

  (* Delete own file *)
  filenameSelf := selfOID^.FileId + OID_EXTENSION;
  if FileExists(filenameSelf) then
  begin
    DeleteFile(filenameSelf);
  end;
end;

function _DeleteConfirmation: boolean;
var
  sc: Char;
begin
  repeat
    ShowMessage('Are you sure you want to delete this OID? (Y/N)', 'DELETE OID', true);
    DrawStatusBar('Y=Yes, N=No');

    CursorOn;
    sc := ReadKey;
    CursorOff;
    if sc = #0 then
    begin
      (* Extended key. Nothing we care about. *)
      ReadKey;
      continue;
    end;

    if UpCase(sc) = 'Y' then
    begin
      _DeleteConfirmation := true;
      break;
    end
    else if UpCase(sc) = 'N' then
    begin
      _DeleteConfirmation := false;
      break;
    end;
  until false;
end;

procedure _DrawOidTitleBar(filename: string; oid: POID);
begin
  if oid^.DotNotation = '' then
    DrawTitleBar('OID ROOT', TITLEBAR_LEFT_TEXT, filename)
  else
    DrawTitleBar('OID ' + oid^.DotNotation, TITLEBAR_LEFT_TEXT, filename);
end;

function DotNotation(oid: POid): string;
var
  res: string;
begin
  res := oid^.DotNotation;
  if res = '' then res := '.'; (* root *)
  DotNotation := res;
end;

function OidLastArc(oid: POid): string;
var
  s: string;
  p: integer;
begin
  s := oid^.DotNotation;

  while true do
  begin
    p := Pos('.', s);
    if p = 0 then break;
    Delete(s, 1, p);
  end;

  OidLastArc := s;
end;

function AsnNotation(oid: POid): string;
var
  prevOid, curOid: POid;
  res: string;
begin
  CreateOidDef(curOid);
  prevOid := oid;
  res := '';

  while true do
  begin
    (* Note: BackRef is not checked yet! Infinite loop is possible! (TODO) *)
    ReadOidFile(prevOid^.ParentFileId + '.OID', curOid);
    if curOid^.ParentFileId = '' then break;
    if curOid^.ParentFileId = curOid^.FileId then break;
    if ListCount(curOid^.AsnIds) > 0 then
      res := ListGetElement(curOid^.AsnIds, 0) + '('+OidLastArc(curOid)+') ' + res
    else
      res := OidLastArc(curOid) + ' ' + res;
    prevOid := curOid;
  end;
  FreeOidDef(curOid);
  if ListCount(oid^.AsnIds) > 0 then
    res := res + ListGetElement(oid^.AsnIds, 0) + '('+OidLastArc(oid)+')'
  else
    res := res + OidLastArc(oid);
  if res = '' then
    AsnNotation := ''
  else
    AsnNotation := '{ ' + res + ' }';
end;

function IriNotation(oid: POid): string;
var
  prevOid, curOid: POid;
  res: string;
begin
  CreateOidDef(curOid);
  prevOid := oid;
  res := '';

  while true do
  begin
    (* Note: BackRef is not checked yet! Infinite loop is possible! (TODO) *)
    ReadOidFile(prevOid^.ParentFileId + '.OID', curOid);
    if curOid^.ParentFileId = '' then break;
    if curOid^.ParentFileId = curOid^.FileId then break;
    if ListCount(curOid^.UnicodeLabels) > 0 then
      res := ListGetElement(curOid^.UnicodeLabels, 0) + '/' + res
    else
      res := OidLastArc(curOid) + '/' + res;
    prevOid := curOid;
  end;
  FreeOidDef(curOid);
  if ListCount(oid^.UnicodeLabels) > 0 then
    res := res + ListGetElement(oid^.UnicodeLabels, 0)
  else
    res := res + OidLastArc(oid);
  IriNotation := '/' + res;
end;

function WeidNotation(oid: POid): string;
begin
  WeidNotation := OidToWeid(oid^.DotNotation);
end;

procedure DisplayOIDFile(filename: string);
var
  isRoot: boolean;
  oid, tmpOID: POID;
  i: integer;
  sTmp, subfile: string;
  subsel, subfiles: PStringList;
  subselres: integer;
  exitRequest: boolean;
  menuIdExit, menuIdAsnEdit, menuIdIriEdit, menuIdDescEdit, menuIdAdd, menuIdDelete: integer;
  menuX, menuY: integer;
begin
  exitRequest := false;
  repeat
    CreateOidDef(oid);

    if not _ReadOidFile(filename, oid, true) then
    begin
      FreeOidDef(oid);
      exit;
    end;

    (* Print OID information *)

    ClrScr;
    _DrawOidTitleBar(filename, oid);
    DrawStatusBar(DEFAULT_STATUSBAR);
    GotoXY(1,2);

    (*if oid^.DotNotation <> '' then*)
    begin
      Write('Dot notation:   ');
      WriteLnKeepX(DotNotation(oid));
      Write('IRI notation:   ');
      WriteLnKeepX(IriNotation(oid));
      Write('ASN.1 notation: ');
      WriteLnKeepX(AsnNotation(oid));
      Write('WEID notation:  ');
      WriteLnKeepX(WeidNotation(oid));
      WriteLn('');
    end;

    if Trim(oid^.Description) <> '' then
    begin
      (* WriteLn('Description:'); *)
      WriteLn(oid^.Description);
      WriteLn('');
    end
    else
    begin
      WriteLn('(No description has been added to this OID.)');
      WriteLn('');
    end;

    (* Now prepare the menu entries *)

    CreateList(subsel);   (* Contains the human-readable OID name *)
    CreateList(subfiles); (* Contains the file name               *)

    if oid^.ParentFileId = '' then
    begin
      isRoot := true;
    end
    else
    begin
      isRoot := oid^.ParentDotNotation = oid^.DotNotation;
    end;

    if (oid^.ParentFileId <> '') and not isRoot then
    begin
      subfile := oid^.ParentFileId + OID_EXTENSION;
      if FileExists(subfile) then
      begin
        CreateOidDef(tmpOID);
        if not _ReadOidFile(subfile, tmpOID, true) then
        begin
          ListAppend(subsel, 'Go to parent ' + oid^.ParentDotNotation + ' (READ ERROR)');
          ListAppend(subfiles, 'ERROR: '+subfile+' Read error or file invalid');
        end
        else
        begin
          ListAppend(subsel, 'Go to parent ' + oid^.ParentDotNotation + _ShowASNIds(tmpOID));
          ListAppend(subfiles, subfile);
        end;
        FreeOidDef(tmpOID);
      end
      else
      begin
        ListAppend(subsel, 'Go to parent ' + oid^.ParentDotNotation + ' (FILE NOT FOUND)');
        ListAppend(subfiles, 'ERROR: File '+subfile+' was not found');
      end;
    end;

    if isRoot then
    begin
      menuIdExit := ListAppend(subsel, 'Back to main menu');
      ListAppend(subfiles, '');
    end
    else menuIdExit := -99;

    for i := 0 to ListCount(oid^.SubIds)-1 do
    begin
      sTmp := ListGetElement(oid^.SubIds, i);
      subfile := FileIdPart(sTmp) + OID_EXTENSION;
      if FileExists(subfile) then
      begin
        CreateOidDef(tmpOID);
        if not _ReadOidFile(subfile, tmpOID, true) then
        begin
          ListAppend(subsel, 'Go to child  ' + DotNotationPart(sTmp) + ' (READ ERROR)');
          ListAppend(subfiles, 'ERROR: Read error at file '+subfile+', or file is invalid.');
        end
        else if (tmpOID^.ParentFileId <> oid^.FileId) or
                (tmpOID^.ParentDotNotation <> oid^.DotNotation) then
        begin
          ListAppend(subsel, 'Go to child  ' + DotNotationPart(sTmp) + ' (BAD BACKREF)');
          ListAppend(subfiles, 'ERROR: File '+subfile+' has a wrong back-reference.');
        end
        else
        begin
          ListAppend(subsel, 'Go to child  ' + DotNotationPart(sTmp) + _ShowASNIds(tmpOID));
          ListAppend(subfiles, subfile);
        end;
        FreeOidDef(tmpOID);
      end
      else
      begin
        ListAppend(subsel, 'Go to child  ' + DotNotationPart(sTmp) + ' (FILE NOT FOUND)');
        ListAppend(subfiles, 'ERROR: File '+subfile+' was not found');
      end;
    end;

    if oid^.DotNotation <> '' then
    begin
      menuIdAsnEdit := ListAppend(subsel, 'View/Edit ASN.1 identifiers');
      ListAppend(subfiles, '');
    end
    else menuIdAsnEdit := -99;

    if oid^.DotNotation <> '' then
    begin
      menuIdIriEdit := ListAppend(subsel, 'View/Edit Unicode Labels');
      ListAppend(subfiles, '');
    end
    else menuIdIriEdit := -99;

    menuIdDescEdit := ListAppend(subsel, 'Edit description');
    ListAppend(subfiles, '');

    menuIdAdd := ListAppend(subsel, 'Add child');
    ListAppend(subfiles, '');

    if not isRoot then
    begin
      menuIdDelete := ListAppend(subsel, 'Delete OID');
      ListAppend(subfiles, '');
    end
    else menuIdDelete := -99;

    (* Show menu *)

    menuX := WhereX + 1;
    menuY := ScreenHeight - ACTIONMENU_SIZE - 1;
    subselres := DrawSelectionList(menuX, menuY,
                                   ScreenWidth-2,
                                   ACTIONMENU_SIZE,
                                   subsel,
                                   true,
                                   'SELECT ACTION',
                                   1);

    (* Process user selection *)

    if subselres = -1 then
    begin
      exitRequest := true;
    end
    else if subselres = menuIdAsnEdit then
    begin
      if AsnEditor(oid) then
        _WriteOidFile(filename, oid, true);
    end
    else if subselres = menuIdIriEdit then
    begin
      if IriEditor(oid) then
        _WriteOidFile(filename, oid, true);
    end
    else if subselres = menuIdDescEdit then
    begin
      if DescEditor(oid) then
        _WriteOidFile(filename, oid, true);
    end
    else if subselres = menuIdAdd then
    begin
      if NewOidEditor(oid) then
        _WriteOidFile(filename, oid, true);
    end
    else if subselres = menuIdDelete then
    begin
      if _DeleteConfirmation then
      begin
        sTmp := oid^.ParentFileId + OID_EXTENSION;
        DeleteOidRecursive(oid);
        if FileExists(sTmp) then
        begin
          filename := sTmp;
        end
        else
        begin
          ShowMessage('Parent file ' + sTmp + ' was not found', 'ERROR', true);
          _Pause;
          exitRequest := true;
        end;
      end;
    end
    else if subselres = menuIdExit then
    begin
      exitRequest := true;
    end
    else
    begin
      (* Normal OID *)
      (* Above we already checked if the files are valild and existing *)
      sTmp := ListGetElement(subfiles, subselres);
      if Copy(sTmp, 1, Length('ERROR: ')) = 'ERROR: ' then
      begin
        Delete(sTmp, 1, Length('ERROR: '));
        ShowMessage(sTmp, 'ERROR', true);
        _Pause;
      end
      else
      begin
        filename := sTmp;
      end;
    end;
    FreeList(subsel);
    FreeList(subfiles);

    FreeOidDef(oid);
  until exitRequest;
end;

function CreateRootOIDFile(filename: string; ShowErrorMessage: boolean): boolean;
var
  oid: POID;
begin
  CreateOidDef(oid);
  oid^.Description  := 'This is the root of the OID tree.' +#13#10 +
                       #13#10 +
                       'Valid subsequent arcs are per definition:' + #13#10 +
                       '- 0 (itu-t)' + #13#10 +
                       '- 1 (iso)' + #13#10 +
                       '- 2 (joint-iso-itu-t)';
  oid^.FileId       := ZeroPad(0, 8);
  oid^.DotNotation  := '';
  oid^.ParentFileId := ZeroPad(0, 8);
  oid^.ParentDotNotation := '';
  CreateRootOIDFile := _WriteOidFile(filename, oid, ShowErrorMessage);
  FreeOidDef(oid);
end;

function _GetRootFile(ShowErrorMessage: boolean): string;
var
  rootFile: string;
begin
  rootFile := ZeroPad(0, 8) + OID_EXTENSION;
  _GetRootFile := rootFile;
  if not FileExists(rootFile) then
  begin
    if not CreateRootOIDFile(rootFile, ShowErrorMessage) then
    begin
      _GetRootFile := '';
    end;
  end;
end;

procedure OP_ManageOIDs;
var
  rootfile: string;
begin
  ClrScr;
  DrawTitleBar('Manage Object Identifiers', TITLEBAR_LEFT_TEXT, '');
  DrawStatusBar('Loading data... please wait...');

  (* This will try creating a new root file if it does not exist *)
  rootfile := _GetRootFile(true);
  if rootfile = '' then Exit;

  DisplayOIDFile(rootfile);
end;

procedure OP_ReturnToMSDOS;
begin
  (* Note: These two lines don't seem to be necessary if you use DoneVideo *)
  ResetDefaultDosColors;
  ClrScr; (*Important, so that the DOS command prompt is also LightGray *)

  WriteLn('Thank you for using OIDplus for DOS.');
  WriteLn('');
end;

function _GetTreeViewLine(oid: POID; indent: integer): string;
var
  i: integer;
  sTmp, sTmp2: string;
begin
  (* Build line *)
  sTmp := RepeatStr(' ', indent*TREEVIEW_INDENT);
  if oid^.DotNotation = '' then
    sTmp := sTmp + 'Object Identifiers'
  else
    sTmp := sTmp + oid^.DotNotation;
  sTmp := sTmp + _ShowAsnIds(oid);
  if TREEVIEW_INCLUDE_DESC then
  begin
    if Trim(oid^.Description) <> '' then
    begin
      sTmp := sTmp + ': ' + oid^.Description;
    end;
  end;

  sTmp := StringReplace(sTmp, #13#10, ' ');
  repeat
    sTmp2 := sTmp;
    sTmp := StringReplace(sTmp, '  ', ' ');
  until sTmp = sTmp2;

  sTmp := TrimLineToWidth(sTmp, TREEVIEW_WIDTH);
  _GetTreeViewLine := sTmp;
end;

procedure _RecTreeExport(oid: POID; var F: Text; indent: integer);
var
  i: integer;
  sTmp: string;
  suboid: POID;
  childFilename: string;
begin
  sTmp := _GetTreeViewLine(oid, indent);
  sTmp := TrimLineToWidth(sTmp, TREEVIEW_WIDTH);
  WriteLn(F, sTmp);

  (* Recursively call children *)
  for i := 0 to ListCount(oid^.SubIds)-1 do
  begin
    sTmp := ListGetElement(oid^.SubIds, i);
    CreateOidDef(suboid);
    childFilename := FileIdPart(sTmp) + OID_EXTENSION;
    if not FileExists(childFilename) then
    begin
      sTmp := 'ERROR: MISSING ' + childFilename + ' (SHALL CONTAIN ' + DotNotationPart(sTmp) + ')!';
      sTmp := TrimLineToWidth(sTmp, TREEVIEW_WIDTH);
      WriteLn(F, sTmp);
    end
    else if not _ReadOidFile(childFilename, suboid, false) then
    begin
      sTmp := 'ERROR: READ ERROR AT ' + childFilename + ' (SHALL CONTAIN ' + DotNotationPart(sTmp) + ')!';
      sTmp := TrimLineToWidth(sTmp, TREEVIEW_WIDTH);
      WriteLn(F, sTmp);
    end
    else if (suboid^.ParentFileId <> oid^.FileId) or
            (suboid^.ParentDotNotation <> oid^.DotNotation) then
    begin
      (* This can happen if a file is missing, and then another OID gets this filename since the number seems to be free *)
      sTmp := 'ERROR: BAD BACKREF AT ' + childFilename + ' (SHALL CONTAIN ' + DotNotationPart(sTmp) + ')!';
      sTmp := TrimLineToWidth(sTmp, TREEVIEW_WIDTH);
      WriteLn(F, sTmp);
    end
    else
    begin
      _RecTreeExport(suboid, F, indent+1);
      FreeOidDef(suboid);
    end
  end;
end;

procedure TreeViewPreview;
var
  list: PStringList;
begin
  ClrScr;
  DrawTitleBar('TreeView Export', TITLEBAR_LEFT_TEXT, TREEVIEW_FILENAME);
  DrawStatusBar('Press ESC to return to the main menu');

  CreateList(list);

  ListLoadFromFile(list, TREEVIEW_FILENAME);
  DrawSelectionList(2, 3, ScreenWidth-2, ScreenHeight-4,
                    list, true, 'PREVIEW OF '+TREEVIEW_FILENAME, 2);
  (* TODO: Jump to selected OID *)

  DrawStatusBar(DEFAULT_STATUSBAR);

  FreeList(list);
end;

procedure OP_TreeView;
var
  F: Text;
  rootoid: POID;
  rootfile: string;
  res: boolean;
begin
  ClrScr;
  DrawTitleBar('TreeView Export', TITLEBAR_LEFT_TEXT, '');
  DrawStatusBar('Exporting data... please wait...');

  (* This will try creating a new root file if it does not exist *)
  rootfile := _GetRootFile(true);
  if rootfile = '' then
  begin
    DrawStatusBar(DEFAULT_STATUSBAR);
    Exit;
  end;

  Assign(F, TREEVIEW_FILENAME);
  {$I-}
  Rewrite(F);
  {$I+}
  if IoResult <> 0 then
  begin
    (* Can happen if disk is read-only (Runtime Error 150) *)
    ShowMessage('Cannot open '+TREEVIEW_FILENAME+' for writing.', 'ERROR', true);
    _Pause;
    DrawStatusBar(DEFAULT_STATUSBAR);
    Exit;
  end;

  res := false;
  CreateOidDef(rootoid);
  if _ReadOidFile(rootfile, rootoid, true) then
  begin
    _RecTreeExport(rootoid, F, 0);
    res := true;
  end;
  FreeOidDef(rootoid);

  Close(F);

  DrawStatusBar(DEFAULT_STATUSBAR);
  if res then
  begin
    ShowMessage('TreeView successfully exported as '+TREEVIEW_FILENAME, 'TREEVIEW EXPORT', true);
    _Pause;
  end;

  TreeViewPreview;
end;

procedure OP_MainMenu;
var
  menu: PStringList;
  menuRes, menuLeft, menuTop: integer;
  menuIdOID, menuIdTree, menuIdExit: integer;
begin
  repeat
    ClrScr;

    DrawTitleBar('Welcome to OIDplus for DOS', '', '');
    DrawStatusBar(DEFAULT_STATUSBAR);
    GoToXY(ScreenWidth-Length(VERSIONINFO), ScreenHeight-1);
    Write(VERSIONINFO);

    CreateList(menu);

    menuIdOID  := ListAppend(menu, 'Manage OIDs');
    menuIdTree := ListAppend(menu, 'Export TreeView');
    menuIdExit := ListAppend(menu, 'Return to DOS');

    menuLeft := round(ScreenWidth/2 -MAINMENU_WIDTH/2);
    menuTop  := round(ScreenHeight/2-MAINMENU_HEIGHT/2);
    menuRes  := DrawSelectionList(menuLeft, menuTop,
                                  MAINMENU_WIDTH, MAINMENU_HEIGHT,
                                  menu, true, 'MAIN MENU', 2);
    FreeList(menu);

    if menuRes = menuIdOID then
    begin
      OP_ManageOIDs;
    end
    else if menuRes = menuIdTree then
    begin
      OP_Treeview;
    end;
  until (menuRes = menuIdExit) or (MAINMENU_ALLOW_ESC and (menuRes = -1));

  OP_ReturnToMSDOS;
end;

begin
  InitVideo; (* sets ScreenWidth and ScreenHeight *)
  CursorOff;
  OP_MainMenu;
  CursorOn;
  DoneVideo;
end.
