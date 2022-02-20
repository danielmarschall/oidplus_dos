unit OIDFILE;

(************************************************)
(* OIDFILE.PAS                                  *)
(* Author:   Daniel Marschall                   *)
(* Revision: 2022-02-19                         *)
(* License:  Apache 2.0                         *)
(* This file contains:                          *)
(* - Functions to handle an OID ASCII format    *)
(************************************************)

interface

uses
  StrList;

type
  POID = ^TOID;
  TOID = record
    FileId: string;
    DotNotation: string;
    ASNIds: PStringList;
    UnicodeLabels: PStringList;
    Description: string;
    SubIds: PStringList; (* first 8 chars are FileId, followed by DotNotation *)
    ParentFileId: string;
    ParentDotNotation: string;
  end;

procedure CreateOidDef(var oid: POid);
procedure FreeOidDef(oid: POid);
procedure ClearOidDef(oid: POid);
function WriteOidFile(filename: string; oid: POid): boolean;
function ReadOidFile(filename: string; oid: POid): boolean;

(* For the strings in the list "SubIds": *)
function FileIdPart(s: string): string;
function DotNotationPart(s: string): string;

implementation

uses
  VtsFuncs, OidUtils, Crt;

const
  WANT_VERS = '2022';

procedure CreateOidDef(var oid: POid);
begin
  oid := nil;
  GetMem(oid, SizeOf(TOID));

  if oid <> nil then
  begin
    oid^.FileId := '';
    oid^.DotNotation := '';
    oid^.Description := '';
    oid^.ParentFileId := '';
    oid^.ParentDotNotation := '';
    CreateList(oid^.ASNIds);
    CreateList(oid^.UnicodeLabels);
    CreateList(oid^.SubIds);
  end
  else
  begin
    Beep;
    WriteLn('CreateOidDef failed! (GetMem returned nil)');
    ReadKey;
  end;
end;

procedure FreeOidDef(oid: POid);
begin
  if oid <> nil then
  begin
    FreeList(oid^.ASNIds);
    FreeList(oid^.UnicodeLabels);
    FreeList(oid^.SubIds);
    FreeMem(oid, SizeOf(TOID));
    oid := nil;
  end
  else
  begin
    Beep;
    WriteLn('FreeOidDef failed! (Argument is nil)');
    ReadKey;
  end;
end;

procedure ClearOidDef(oid: POid);
begin
  oid^.FileId := '';
  oid^.DotNotation := '';
  oid^.Description := '';
  oid^.ParentFileId := '';
  oid^.ParentDotNotation := '';
  ListClear(oid^.ASNIds);
  ListClear(oid^.UnicodeLabels);
  ListClear(oid^.SubIds);
end;

procedure ListBubbleSortSubIds(oid: POid);
var
  n, i: integer;
  a, b: string;
  swapped: boolean;
begin
  n := ListCount(oid^.SubIds);
  while n>1 do
  begin
    i := 0;
    swapped := false;
    while i<n-1 do
    begin
      a := DotNotationPart(ListGetElement(oid^.SubIds, i));
      b := DotNotationPart(ListGetElement(oid^.SubIds, i+1));
      if CompareOID(a, b) > 0 then
      begin
        ListSwapElement(oid^.SubIds, i, i+1);
        swapped := true;
      end;
      Inc(i);
    end;
    if not swapped then break;
    Dec(n);
  end;
end;

function WriteOidFile(filename: string; oid: POid): boolean;
var
  f: Text;
  i: integer;
  lines: PStringList;
  sTmp: string;
  desc: string;
begin
  Assign(f, filename);

  {$I-}
  Rewrite(f);
  {$I+}
  if IoResult <> 0 then
  begin
    WriteOidFile := false;
    (* Must not call Close(f) if file was never opened *)
    Exit;
  end;

  WriteLn(f, 'VERS' + WANT_VERS);

  WriteLn(f, 'SELF' + oid^.FileId + oid^.DotNotation);

  WriteLn(f, 'SUPR' + oid^.ParentFileId + oid^.ParentDotNotation);

  (* Sort sub IDs *)
  ListBubbleSortSubIds(oid);

  for i := 0 to ListCount(oid^.SubIds)-1 do
  begin
    sTmp := ListGetElement(oid^.SubIds, i);
    WriteLn(f, 'CHLD' + sTmp);
  end;

  for i := 0 to ListCount(oid^.AsnIds)-1 do
  begin
    sTmp := ListGetElement(oid^.AsnIds, i);
    WriteLn(f, 'ASN1' + sTmp);
  end;

  for i := 0 to ListCount(oid^.UnicodeLabels)-1 do
  begin
    sTmp := ListGetElement(oid^.UnicodeLabels, i);
    WriteLn(f, 'UNIL' + sTmp);
  end;

  desc := Trim(oid^.Description);
  if desc <> '' then
  begin
    CreateList(lines);
    SplitStrToList(desc, lines, #13#10);
    for i := 0 to ListCount(lines)-1 do
    begin
      sTmp := ListGetElement(lines, i);
      WriteLn(f, 'DESC' + sTmp);
    end;
    FreeList(lines);
  end;

  Close(f);

  WriteOidFile := true;
end;

function ReadOidFile(filename: string; oid: POid): boolean;
var
  f: Text;
  line, cmd: string;
  version: string;
begin
  ClearOidDef(oid);
  version := '';

  Assign(f, filename);
  {$I-}
  Reset(f);
  {$I+}
  if IoResult <> 0 then
  begin
    ReadOidFile := false;
    (* Must not call Close(f) if file was never opened *)
    Exit;
  end;

  while not EOF(f) do
  begin
    ReadLn(f, line);
    cmd := Copy(line,1,4);
    Delete(line,1,4);

    if cmd = 'VERS' then
    begin
      version := line;
    end;

    if cmd = 'SELF' then
    begin
      oid^.FileId := Copy(line,1,8);
      Delete(line,1,8);
      oid^.DotNotation := line;
    end;

    if cmd = 'SUPR' then
    begin
      oid^.ParentFileId := FileIdPart(line);
      oid^.ParentDotNotation := DotNotationPart(line);
    end;

    if cmd = 'CHLD' then
    begin
      ListAppend(oid^.SubIds, line);
    end;

    if cmd = 'ASN1' then
    begin
      ListAppend(oid^.ASNIds, line);
    end;

    if cmd = 'UNIL' then
    begin
      ListAppend(oid^.UnicodeLabels, line);
    end;

    if cmd = 'DESC' then
    begin
      oid^.Description := oid^.Description + line + #13#10;
    end;
  end;

  (* Sort sub IDs *)
  ListBubbleSortSubIds(oid);

  (* Remove last CRLF *)
  oid^.Description := Copy(oid^.Description, 1, Length(oid^.Description)-Length(#13#10));

  (* Check if everything is correct *)
  ReadOidFile := (version = WANT_VERS) and (oid^.FileId <> '');

  Close(f);
end;

function FileIdPart(s: string): string;
begin
  FileIdPart := Copy(s,1,8);
end;

function DotNotationPart(s: string): string;
begin
  Delete(s,1,8);
  DotNotationPart := s;
end;

end.
