unit OIDFILE;

(************************************************)
(* OIDFILE.PAS                                  *)
(* Author:   Daniel Marschall                   *)
(* Revision: 2022-02-14                         *)
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
    Description: string;
    SubIds: PStringList; (* first 8 chars are FileId, followed by Dot-Notation *)
    Parent: string; (* First 8 chars are FileId, followed by Dot-Notation *)
  end;

procedure CreateOidDef(var oid: POid);
procedure FreeOidDef(oid: POid);
procedure ClearOidDef(oid: POid);
procedure WriteOidFile(filename: string; oid: POid);
procedure ReadOidFile(filename: string; oid: POid);

(* For the fields "SubIds" and "Parent" *)
function FileIdPart(s: string): string;
function DotNotationPart(s: string): string;

implementation

uses
  VtsFuncs;

const
  WANT_VERS = '2022';

procedure CreateOidDef(var oid: POid);
begin
  GetMem(oid, SizeOf(TOID));
  oid^.FileId := '';
  oid^.DotNotation := '';
  oid^.Description := '';
  oid^.Parent := '';
  CreateList(oid^.ASNIds);
  CreateList(oid^.SubIds);
end;

procedure FreeOidDef(oid: POid);
begin
  FreeList(oid^.ASNIds);
  FreeList(oid^.SubIds);
  FreeMem(oid, SizeOf(TOID));
end;

procedure ClearOidDef(oid: POid);
begin
  FreeOidDef(oid);
  CreateOidDef(oid);
end;

procedure WriteOidFile(filename: string; oid: POid);
var
  f: Text;
  i: integer;
  lines: PStringList;
  sTmp: string;
  desc: string;
begin
  Assign(f, filename);
  Rewrite(f);

  WriteLn(f,'VERS' + WANT_VERS);

  WriteLn(f,'SELF' + oid^.FileId + oid^.DotNotation);

  WriteLn(f,'SUPR' + oid^.Parent);

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
end;

procedure ReadOidFile(filename: string; oid: POid);
var
  f: Text;
  line, cmd: string;
  version: string;
begin
  ClearOidDef(oid);
  version := '';

  Assign(f, filename);
  Reset(f);
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
      oid^.Parent := line;
    end;

    if cmd = 'CHLD' then
    begin
      ListAppend(oid^.SubIds, line);
    end;

    if cmd = 'ASN1' then
    begin
      ListAppend(oid^.ASNIds, line);
    end;

    if cmd = 'DESC' then
    begin
      oid^.Description := oid^.Description + line + #13#10;
    end;
  end;

  (* Remove last CRLF *)
  oid^.Description := Copy(oid^.Description, 1, Length(oid^.Description)-Length(#13#10));

  (* Check if something is not correct *)
  if (version <> WANT_VERS) or (oid^.FileId = '') then
  begin
    (* Invalidate everything *)
    ClearOidDef(oid);
  end;

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
