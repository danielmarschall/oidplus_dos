program OIDPLUS;

(************************************************)
(* OIDPLUS.PAS                                  *)
(* Author:   Daniel Marschall                   *)
(* Revision: 2022-02-13                         *)
(* License:  Apache 2.0                         *)
(* This file contains:                          *)
(* - "OIDplus for DOS" program                  *)
(************************************************)

uses
  Dos, Crt, StrList, VtsFuncs, VtsCui, OidFile, OidUtils;

const
  VERSIONINFO = 'Revision: 2022-02-13';
  DEFAULT_STATUSBAR = '(C)2020-2022 ViaThinkSoft. Licensed under the terms of the Apache 2.0 license.';
  DISKIO_SOUND_DEBUGGING = false;
  DISKIO_SOUND_DELAY = 500;
  ASNEDIT_LINES = 10;
  DESCEDIT_LINES = 10;
  DESCEDIT_PADDING = 3;

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
  coid: TOID;
  j, jmax: integer;
  sTmp: string;
begin
  sTmp := '';
  InitOidDef(@coid);
  _ReadOidFile(subfile, @coid);
  jmax := ListCount(coid.ASNIds)-1;
  for j := 0 to jmax do
  begin
    if j = 0 then sTmp := sTmp + ' (';
    sTmp := sTmp + ListGetElement(coid.ASNIds, j);
    if j = jmax then
      sTmp := sTmp + ')'
    else
      sTmp := sTmp + ', ';
  end;
  FreeOidDef(@coid);
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
begin
  AsnEditor := false;

  repeat
    InitList(asnList);

    for i := 0 to ListCount(oid^.ASNIds)-1 do
    begin
      ListAppend(asnList, ListGetElement(oid^.ASNIDs, i));
    end;
    ListAppend(asnList, '<NEW>');
    ListAppend(asnList, '<SAVE>');
    ListAppend(asnList, '<CANCEL>');

    DrawStatusBar(DEFAULT_STATUSBAR);
    x := SINGLE_LINE_BOX_PADDING;
    y := ScreenHeight div 2 - ASNEDIT_LINES div 2;
    w := ScreenWidth - (SINGLE_LINE_BOX_PADDING-1)*2;
    h := ASNEDIT_LINES;
    res := DrawSelectionList(x, y, w, h,
                             asnList, true,
                             'EDIT ASN.1 IDENTIFIERS',
                             2);

    (* Change double-border to thin-border *)
    DrawThinBorder(x-1, y-1, w+2, h+2);
    GoToXY(x+1, y-1);
    Write('EDIT ASN.1 IDENTIFIERS');

    if res = -1 then
    begin
      exit;
    end
    else if res = ListCount(oid^.ASNIDs) then
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
    else if res = ListCount(oid^.ASNIDs)+1 then
    begin
      (* "SAVE" item was selected *)
      AsnEditor := true;
      Exit;
    end
    else if res = ListCount(oid^.ASNIDs)+2 then
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
            ListDeleteElement(oid^.ASNIDs, res);
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
    DescEditor := true; (* enable write file *)
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
  InitList(list);
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
    Delete(sTmp, 1, 8);
    if sTmp = searchDotNotation then
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
        NumIdEditor := true;
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
  newoid: TOID;
begin
  NewOidEditor := false;

  InitOidDef(@newoid);
  newoid.FileId := NextPossibleFileID;
  newoid.Parent := oid^.FileId + oid^.DotNotation;
  if not NumIdEditor(@newoid, oid) then exit;
  if not AsnEditor(@newoid) then exit;
  if not DescEditor(@newoid) then exit;

  newfilename := newoid.FileId + '.OID';
  _WriteOidFile(newfilename, @newoid);

  (* Add link to original file and enable the saving of it *)
  ListAppend(oid^.SubIds, newoid.FileId + newoid.DotNotation);
  NewOidEditor := true;
end;

procedure DeleteChildrenRecursive(oid: POID);
var
  i: integer;
  childOID: TOID;
  filenameChild: string;
begin
  for i := 0 to ListCount(oid^.SubIds)-1 do
  begin
    filenameChild := Copy(ListGetElement(oid^.SubIds, i), 1, 8) + '.OID';
    InitOidDef(@childOID);
    _ReadOidFile(filenameChild, @childOID);
    DeleteChildrenRecursive(@childOID);
    FreeOidDef(@childOID);
    DeleteFile(filenameChild);
  end;
  ListClear(oid^.SubIds);
end;

procedure DeleteOidRecursive(selfOID: POID);
var
  i: integer;
  parentOID: TOID;
  filenameSelf, filenameParent: string;
  fileIdToDelete: string;
begin
  (* Remove all children and their files recursively *)
  DeleteChildrenRecursive(selfOID);

  (* Remove forward reference in parent OID *)
  filenameParent := Copy(selfOID^.Parent, 1, 8)+'.OID';
  InitOidDef(@parentOID);
  _ReadOidFile(filenameParent, @parentOID);
  for i := 0 to ListCount(parentOID.SubIds)-1 do
  begin
    if Copy(ListGetElement(parentOID.SubIds, i), 1, 8) = selfOID^.FileId then
    begin
      ListDeleteElement(parentOID.SubIds, i);
      _WriteOidFile(filenameParent, @parentOID);
      break;
    end;
  end;
  FreeOidDef(@parentOID);

  (* Delete own file *)
  fileIdToDelete := selfOID^.FileId;
  filenameSelf := fileIdToDelete+'.OID';
  DeleteFile(filenameSelf);
end;

procedure DisplayOIDFile(filename: string);
const
  ID_EXIT     = '?EXIT';
  ID_ASNEDIT  = '?ASN1';
  ID_DESCEDIT = '?DESC';
  ID_ADDCHILD = '?ADDC';
  ID_DELETE   = '?DELE';
  NAVBAR_SIZE = 5;
var
  isRoot: boolean;
  f: Text;
  line, cmd: string;
  oid: TOID;
  i, menuX, menuY: integer;
  linesLeft, linesRequired: integer;
  sTmp, subfile: string;
  sAsn: string;
  subsel, subfiles: PStringList;
  subselres: integer;
  sTmp1: string;
begin
  repeat
    InitOidDef(@oid);
    _ReadOidFile(filename, @oid);

    (* Print OID information *)

    ClrScr;

    if oid.DotNotation = '' then
      DrawTitleBar('OID ROOT')
    else
      DrawTitleBar('OID ' + oid.DotNotation);
    GotoXY(ScreenWidth-Length(filename)+1,1);
    TextBackground(White);
    TextColor(Black);
    WriteLn(filename);
    TextBackground(Black);
    TextColor(White);
    DrawStatusBar(DEFAULT_STATUSBAR);
    GotoXY(1,2);

    if oid.DotNotation <> '' then
    begin
      WriteLn('Dot-Notation:');
      WriteLn(oid.DotNotation);
      WriteLn('');
    end;

    if Trim(oid.Description) <> '' then
    begin
      WriteLn('Description:');
      WriteLn(oid.Description);
      WriteLn('');
    end;

    menuX := WhereX + 1;
    menuY := ScreenHeight - NAVBAR_SIZE - 1;

    if ListCount(oid.ASNIDs) > 0 then
    begin
      linesLeft := menuY - WhereY - 1;
      linesRequired := 1 + ListCount(oid.ASNIds);

      if LinesLeft < LinesRequired then
      begin
        (* Compact display of ASN.1 identifiers *)
        Write('ASN.1-Identifiers: ');
        for i := 0 to ListCount(oid.ASNIds)-1 do
        begin
          if i > 0 then Write(', ');
          Write(ListGetElement(oid.ASNIds, i));
        end;
        WriteLn('');
      end
      else
      begin
        (* Long display of ASN.1 identifiers *)
        WriteLn('ASN.1-Identifiers:');
        for i := 0 to ListCount(oid.ASNIds)-1 do
        begin
          WriteLn('- '+ListGetElement(oid.ASNIds, i));
        end;
        WriteLn('');
      end;
    end;

    (* Now prepare the menu entries *)

    InitList(subsel);
    InitList(subfiles);

    sTmp := oid.Parent;
    if sTmp = '' then
    begin
      isRoot := true;
    end
    else
    begin
      Delete(sTmp, 1, 8);
      isRoot := sTmp = oid.DotNotation;
    end;

    if (oid.Parent <> '') and not isRoot then
    begin
      sTmp := oid.Parent;
      subfile := Copy(sTmp, 1, 8)+'.OID';
      Delete(sTmp, 1, 8);
      sTmp := sTmp + _ShowASNIds(subfile);
      ListAppend(subsel, 'Go to parent ' + sTmp);
      ListAppend(subfiles, subfile);
    end;

    if isRoot then
    begin
      ListAppend(subsel, 'Back to main menu');
      ListAppend(subfiles, ID_EXIT);
    end;

    for i := 0 to ListCount(oid.SubIds)-1 do
    begin
      sTmp := ListGetElement(oid.SubIds, i);
      subfile := Copy(sTmp, 1, 8)+'.OID';
      Delete(sTmp, 1, 8);
      sTmp := sTmp + _ShowASNIds(subfile);
      ListAppend(subsel, 'Go to child  ' + sTmp);
      ListAppend(subfiles, subfile);
    end;

    if oid.DotNotation <> '' then
    begin
      ListAppend(subsel, 'Edit ASN.1 identifiers');
      ListAppend(subfiles, ID_ASNEDIT);
    end;

    ListAppend(subsel, 'Edit description');
    ListAppend(subfiles, ID_DESCEDIT);

    ListAppend(subsel, 'Add child');
    ListAppend(subfiles, ID_ADDCHILD);

    if not isRoot then
    begin
      ListAppend(subsel, 'Delete OID');
      ListAppend(subfiles, ID_DELETE);
    end;

    subselres := DrawSelectionList(menuX, menuY,
                                   ScreenWidth-2,
                                   NAVBAR_SIZE,
                                   subsel,
                                   true,
                                   'SELECT ACTION',
                                   1);
    if subselres = -1 then
    begin
      exit;
    end
    else
    begin
      sTmp1 := ListGetElement(subfiles, subselres);
      if sTmp1 = ID_ASNEDIT then
      begin
        if AsnEditor(@oid) then
          _WriteOidFile(filename, @oid);
      end
      else if sTmp1 = ID_DESCEDIT then
      begin
        if DescEditor(@oid) then
          _WriteOidFile(filename, @oid);
      end
      else if sTmp1 = ID_ADDCHILD then
      begin
        if NewOidEditor(@oid) then
        begin
          _WriteOidFile(filename, @oid);
        end;
      end
      else if sTmp1 = ID_DELETE then
      begin
        ShowMessage('Are you sure you want to delete this OID?', 'DELETE OID', true);
        DrawStatusBar('Y = Yes; any other key = No');
        if UpCase(ReadKey) = 'Y' then
        begin
          filename := Copy(oid.Parent,1,8)+'.OID';
          DeleteOidRecursive(@oid);
        end;
      end
      else if sTmp1 = ID_EXIT then
      begin
        exit;
      end
      else
      begin
        filename := sTmp1;
      end;
    end;
    FreeList(subsel);
    FreeList(subfiles);

    FreeOidDef(@oid);
  until false;
end;

procedure CreateInitOIDFile(filename: string);
var
  oid: TOID;
begin
  InitOidDef(@oid);
  oid.Description := 'This is the root of the OID tree.' +#13#10 +
                     #13#10 +
                     'Valid subsequent arcs are per definition:' + #13#10 +
                     '- 0 (itu-t)' + #13#10 +
                     '- 1 (iso)' + #13#10 +
                     '- 2 (joint-iso-itu-t)';
  oid.FileId      := '00000000';
  oid.DotNotation := '';
  oid.Parent      := '00000000';
  _WriteOidFile(filename, @oid);
  FreeOidDef(@oid);
end;

procedure OP_ManageOIDs;
begin
  ClrScr;
  DrawTitleBar('Manage Object Identifiers');
  DrawStatusBar('');

  if not FileExists('00000000.OID') then
  begin
    CreateInitOIDFile('00000000.OID');
  end;
  DisplayOIDFile('00000000.OID');
end;

procedure OP_ManageRAs;
begin
  ClrScr;
  DrawTitleBar('Manage Registration Authorities');
  DrawStatusBar('');

  (* TODO: Implement "Manage RAs" feature *)
  ShowMessage('This feature has not yet been implemented!', 'NOTICE', true);
  _Pause;
end;

procedure OP_ReturnToMSDOS;
begin
  ClrScr;
end;

procedure OP_MainMenu;
const
  MenuWidth = 15;
  MenuHeight = 3;
var
  menu: PStringList;
  menuRes, menuLeft, menuTop: integer;
begin
  repeat
    ClrScr;

    DrawTitleBar('Welcome to OIDplus for DOS');
    DrawStatusBar(DEFAULT_STATUSBAR);
    GoToXY(ScreenWidth-Length(VERSIONINFO), ScreenHeight-1);
    Write(VERSIONINFO);

    InitList(menu);
    ListAppend(menu, 'Manage OIDs');
    ListAppend(menu, 'Manage RAs');
    ListAppend(menu, 'Return to DOS');
    menuLeft := round(ScreenWidth/2 -MenuWidth/2);
    menuTop  := round(ScreenHeight/2-MenuHeight/2);
    menuRes  := DrawSelectionList(menuLeft, menuTop, MenuWidth, MenuHeight, menu, true, 'MAIN MENU', 2);
    FreeList(menu);

    if menuRes = 0 then
    begin
      OP_ManageOIDs;
    end;

    if menuRes = 1 then
    begin
      OP_ManageRAs;
    end;
  until (menuRes = 2) or (menuRes = -1);

  OP_ReturnToMSDOS;
end;

begin
  OP_MainMenu;
end.
