program OIDPLUS;

(************************************************)
(* OIDPLUS.PAS                                  *)
(* Author:   Daniel Marschall                   *)
(* Revision: 2022-02-14                         *)
(* License:  Apache 2.0                         *)
(* This file contains:                          *)
(* - "OIDplus for DOS" program                  *)
(************************************************)

uses
  Dos, Crt, StrList, VtsFuncs, VtsCui, OidFile, OidUtils;

const
  VERSIONINFO            = 'Revision: 2022-02-14';
  DEFAULT_STATUSBAR      = '(C)2020-2022 ViaThinkSoft. Licensed under the terms of the Apache 2.0 license.';
  DISKIO_SOUND_DEBUGGING = false;
  DISKIO_SOUND_DELAY     = 500;
  ASNEDIT_LINES          = 10;
  DESCEDIT_LINES         = 10;
  DESCEDIT_PADDING       = 3;
  ACTIONMENU_SIZE        = 5;
  MAINMENU_WIDTH         = 15;
  MAINMENU_HEIGHT        = 3;
  MAINMENU_ALLOW_ESC     = false;

procedure _WriteOidFile(filename: string; oid: POid);
begin
  DrawStatusBar('Write file ' + filename + '...');
  WriteOidFile(filename, oid);

  if DISKIO_SOUND_DEBUGGING then
  begin
    Sound(70);
    Delay(DISKIO_SOUND_DELAY - 10);
    NoSound;
    Delay(10);
  end;

  DrawStatusBar(DEFAULT_STATUSBAR);
end;

procedure _ReadOidFile(filename: string; oid: POid);
begin
  DrawStatusBar('Read file ' + filename + '...');
  ReadOidFile(filename, oid);

  if DISKIO_SOUND_DEBUGGING then
  begin
    Sound(50);
    Delay(DISKIO_SOUND_DELAY - 10);
    NoSound;
    Delay(10);
  end;

  DrawStatusBar(DEFAULT_STATUSBAR);
end;

procedure _Pause;
var
  bakX, bakY: integer;
begin
  bakX := WhereX;
  bakY := WhereY;
  DrawStatusBar('Press any key to continue');
  GoToXY(bakX, bakY);
  ReadKey;
  DrawStatusBar(DEFAULT_STATUSBAR);
end;

function _ShowASNIds(subfile: string): string;
var
  childOID: POID;
  j, jmax: integer;
  sTmp: string;
begin
  sTmp := '';
  CreateOidDef(childOID);
  _ReadOidFile(subfile, childOID);
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
  FreeOidDef(childOID);
  _ShowASNIds := sTmp;
end;

function AsnAlreadyExisting(oid: POID; asnid: string): boolean;
var
  sTmp: string;
  i: integer;
begin
  for i := 0 to ListCount(oid^.AsnIds)-1 do
  begin
    sTmp := ListGetElement(oid^.AsnIds, i);
    if sTmp = asnid then
    begin
      AsnAlreadyExisting := true;
      exit;
    end;
  end;
  AsnAlreadyExisting := false;
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
  if QueryVal(sInput,
              DESCEDIT_PADDING,
              ScreenHeight div 2 - DESCEDIT_LINES div 2,
              ScreenWidth - (DESCEDIT_PADDING-1)*2,
              DESCEDIT_LINES,
              'EDIT DESCRIPTION',
              2) then
  begin
    oid^.description := sInput;
    DescEditor := true; (* request caller to save @oid *)
  end;
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
  FindFirst('????????.OID', Archive, DirInfo);
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
      if not IsNumeric(sInput) then
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
        NumIdEditor := true; (* request caller to save @oid *)
        Exit;
      end;
    end
    else
    begin
      Exit;
    end;
  until false;
end;

function NewOidEditor(oid: POID): boolean;
var
  newfilename: string;
  newOID: POID;
begin
  NewOidEditor := false;

  CreateOidDef(newOID);
  newOID^.FileId := NextPossibleFileID;
  newOID^.Parent := oid^.FileId + oid^.DotNotation;
  if NumIdEditor(newOID, oid) and
     AsnEditor(newOID) and
     DescEditor(newOID) then
  begin
    newfilename := newOID^.FileId + '.OID';
    _WriteOidFile(newfilename, newOID);

    (* Add link to original file and enable the saving of it *)
    ListAppend(oid^.SubIds, newOID^.FileId + newOID^.DotNotation);
    NewOidEditor := true; (* request caller to save @oid *)
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
    filenameChild := FileIdPart(ListGetElement(oid^.SubIds, i)) + '.OID';
    CreateOidDef(childOID);
    _ReadOidFile(filenameChild, childOID);
    DeleteChildrenRecursive(childOID);
    FreeOidDef(childOID);
    DeleteFile(filenameChild);
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
  filenameParent := FileIdPart(selfOID^.Parent) + '.OID';
  CreateOidDef(parentOID);
  _ReadOidFile(filenameParent, parentOID);
  if ListDeleteElementByValue(parentOID^.SubIds, selfOID^.FileId + selfOID^.DotNotation) then
  begin
    _WriteOidFile(filenameParent, parentOID);
  end;
  FreeOidDef(parentOID);

  (* Delete own file *)
  filenameSelf := selfOID^.FileId + '.OID';
  DeleteFile(filenameSelf);
end;

function _DeleteConfirmation: boolean;
var
  sc: Char;
begin
  repeat
    ShowMessage('Are you sure you want to delete this OID? (Y/N)', 'DELETE OID', true);
    DrawStatusBar('Y=Yes, N=No');

    sc := ReadKey;
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
    DrawTitleBar('OID ROOT')
  else
    DrawTitleBar('OID ' + oid^.DotNotation);

  (* Put loaded filename into the title bar *)
  GotoXY(ScreenWidth-Length(filename)+1,1);
  TextBackground(White);
  TextColor(Black);
  WriteLn(filename);
  TextBackground(Black);
  TextColor(White);
end;

procedure DisplayOIDFile(filename: string);
var
  isRoot: boolean;
  oid: POID;
  i, menuX, menuY: integer;
  linesLeft, linesRequired: integer;
  sTmp, subfile: string;
  subsel, subfiles: PStringList;
  subselres: integer;
  exitRequest: boolean;
  menuIdExit, menuIdAsnEdit, menuIdDescEdit, menuIdAdd, menuIdDelete: integer;
begin
  exitRequest := false;
  repeat
    CreateOidDef(oid);
    _ReadOidFile(filename, oid);

    (* Print OID information *)

    ClrScr;
    _DrawOidTitleBar(filename, oid);
    DrawStatusBar(DEFAULT_STATUSBAR);
    GotoXY(1,2);

    if oid^.DotNotation <> '' then
    begin
      WriteLn('Dot-Notation:');
      WriteLn(oid^.DotNotation);
      WriteLn('');
    end;

    if Trim(oid^.Description) <> '' then
    begin
      WriteLn('Description:');
      WriteLn(oid^.Description);
      WriteLn('');
    end;

    menuX := WhereX + 1;
    menuY := ScreenHeight - ACTIONMENU_SIZE - 1;

    if ListCount(oid^.ASNIDs) > 0 then
    begin
      linesLeft := menuY - WhereY - 1;
      linesRequired := 1 + ListCount(oid^.ASNIds);

      if LinesLeft < LinesRequired then
      begin
        (* Compact display of ASN.1 identifiers *)
        Write('ASN.1-Identifiers: ');
        for i := 0 to ListCount(oid^.ASNIds)-1 do
        begin
          if i > 0 then Write(', ');
          Write(ListGetElement(oid^.ASNIds, i));
        end;
        WriteLn('');
      end
      else
      begin
        (* Long display of ASN.1 identifiers *)
        WriteLn('ASN.1-Identifiers:');
        for i := 0 to ListCount(oid^.ASNIds)-1 do
        begin
          WriteLn('- '+ListGetElement(oid^.ASNIds, i));
        end;
        WriteLn('');
      end;
    end;

    (* Now prepare the menu entries *)

    CreateList(subsel);   (* Contains the human readable OID name *)
    CreateList(subfiles); (* Contains the file name               *)

    if oid^.Parent = '' then
    begin
      isRoot := true;
    end
    else
    begin
      isRoot := DotNotationPart(oid^.Parent) = oid^.DotNotation;
    end;

    if (oid^.Parent <> '') and not isRoot then
    begin
      sTmp := oid^.Parent;
      subfile := FileIdPart(sTmp) + '.OID';
      ListAppend(subsel, 'Go to parent ' + DotNotationPart(sTmp) + _ShowASNIds(subfile));
      ListAppend(subfiles, subfile);
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
      subfile := FileIdPart(sTmp) + '.OID';
      ListAppend(subsel, 'Go to child  ' + DotNotationPart(sTmp) + _ShowASNIds(subfile));
      ListAppend(subfiles, subfile);
    end;

    if oid^.DotNotation <> '' then
    begin
      menuIdAsnEdit := ListAppend(subsel, 'Edit ASN.1 identifiers');
      ListAppend(subfiles, '');
    end
    else menuIdAsnEdit := -99;

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
        _WriteOidFile(filename, oid);
    end
    else if subselres = menuIdDescEdit then
    begin
      if DescEditor(oid) then
        _WriteOidFile(filename, oid);
    end
    else if subselres = menuIdAdd then
    begin
      if NewOidEditor(oid) then
        _WriteOidFile(filename, oid);
    end
    else if subselres = menuIdDelete then
    begin
      if _DeleteConfirmation then
      begin
        filename := FileIdPart(oid^.Parent) + '.OID';
        DeleteOidRecursive(oid);
      end;
    end
    else if subselres = menuIdExit then
    begin
      exitRequest := true;
    end
    else
    begin
      (* Normal OID *)
      filename := ListGetElement(subfiles, subselres);
    end;
    FreeList(subsel);
    FreeList(subfiles);

    FreeOidDef(oid);
  until exitRequest;
end;

procedure CreateInitOIDFile(filename: string);
var
  oid: POID;
begin
  CreateOidDef(oid);
  oid^.Description := 'This is the root of the OID tree.' +#13#10 +
                      #13#10 +
                      'Valid subsequent arcs are per definition:' + #13#10 +
                      '- 0 (itu-t)' + #13#10 +
                      '- 1 (iso)' + #13#10 +
                      '- 2 (joint-iso-itu-t)';
  oid^.FileId      := ZeroPad(0, 8);
  oid^.DotNotation := '';
  oid^.Parent      := ZeroPad(0, 8);
  _WriteOidFile(filename, oid);
  FreeOidDef(oid);
end;

procedure OP_ManageOIDs;
var
  initFile: string;
begin
  ClrScr;
  DrawTitleBar('Manage Object Identifiers');
  DrawStatusBar('');

  initFile := ZeroPad(0, 8) + '.OID';
  if not FileExists(initFile) then
  begin
    CreateInitOIDFile(initFile);
  end;
  DisplayOIDFile(initFile);
end;

procedure OP_ManageRAs;
begin
  ClrScr;
  DrawTitleBar('Manage Registration Authorities');
  DrawStatusBar('');

  (* TODO: Implement "Manage RAs" feature *)
end;

procedure OP_ReturnToMSDOS;
begin
  ClrScr;
end;

procedure OP_MainMenu;
var
  menu: PStringList;
  menuRes, menuLeft, menuTop: integer;
  menuIdOID, menuIdRA, menuIdExit: integer;
begin
  repeat
    ClrScr;

    DrawTitleBar('Welcome to OIDplus for DOS');
    DrawStatusBar(DEFAULT_STATUSBAR);
    GoToXY(ScreenWidth-Length(VERSIONINFO), ScreenHeight-1);
    Write(VERSIONINFO);

    CreateList(menu);

    menuIdOID  := ListAppend(menu, 'Manage OIDs');
    menuIdRA   := -99; (*ListAppend(menu, 'Manage RAs');*)
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
    else if menuRes = menuIdRA then
    begin
      OP_ManageRAs;
    end;
  until (menuRes = menuIdExit) or (MAINMENU_ALLOW_ESC and (menuRes = -1));

  OP_ReturnToMSDOS;
end;

begin
  OP_MainMenu;
end.
