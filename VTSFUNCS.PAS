unit VTSFUNCS;

(************************************************)
(* VTSFUNCS.PAS                                 *)
(* Author:   Daniel Marschall                   *)
(* Revision: 2022-02-13                         *)
(* License:  Apache 2.0                         *)
(* This file contains:                          *)
(* - Various functions                          *)
(************************************************)

interface

function CompareEqualLengthString(a, b: string): integer;
function CompareNumericString(a, b: string): integer;
procedure Beep;
function Trim(s: string): string;
function IsNumeric(s: string): boolean;
function ZeroPad(i: LongInt; n: integer): string;
procedure DeleteFile(filename: string);
function FileExists(filename: string): boolean;
function StrToInt(s: string): Integer;
function IntToStr(Value: Integer): string;

implementation

uses
  Crt;

function CompareEqualLengthString(a, b: string): integer;
var
  ao, bo, i: integer;
begin
  CompareEqualLengthString := 0;
  for i := 1 to Length(a) do
  begin
    ao := Ord(a[i]);
    bo := Ord(b[i]);
    if ao > bo then
    begin
      CompareEqualLengthString := 1;
      break;
    end;
    if ao < bo then
    begin
      CompareEqualLengthString := -1;
      break;
    end;
  end;
end;

function CompareNumericString(a, b: string): integer;
var
  i, maxlen: integer;
  prefix_a, prefix_b: string;
begin
  maxlen := Length(a);
  if Length(b) > maxlen then maxlen := Length(b);

  prefix_a := '';
  for i := 1 to maxlen-Length(a) do
  begin
    prefix_a := prefix_a + '0';
 end;

  prefix_b := '';
  for i := 1 to maxlen-Length(b) do
  begin
    prefix_b := prefix_b + '0';
 end;

 CompareNumericString := CompareEqualLengthString(prefix_a+a, prefix_b+b);
end;

procedure Beep;
begin
  Sound(220); (*220Hz*)
  Delay(200); (*200ms*)
  NoSound;
end;

function Trim(s: string): string;
begin
  while Length(s) > 0 do
  begin
    if s[1] in [#9,#10,#13,' '] then
      Delete(s,1,1)
    else
      break;
  end;
  while Length(s) > 0 do
  begin
    if s[Length(s)] in [#9,#10,#13,' '] then
      Delete(s,Length(s),1)
    else
      break;
  end;
  Trim := s;
end;

function IsNumeric(s: string): boolean;
var
  i: integer;
begin
  IsNumeric := false;

  if Length(s) = 0 then exit;
  if (s[1] = '0') and (s <> '0') then exit;
  for i := 1 to Length(s) do
  begin
    if not (s[i] in ['0'..'9']) then exit;
  end;

  IsNumeric := true;
end;

function ZeroPad(i: LongInt; n: integer): string;
var
  s: string;
begin
  Str(i, s);
  while Length(s) < n do
  begin
    s := '0' + s;
  end;
  ZeroPad := s;
end;

procedure DeleteFile(filename: string);
var
 F:  file;
 Ch: Char;
begin
 { Get file to delete from command line }
 Assign(F, filename);
 {$I-}
 Reset(F);
 {$I+}
 (*
 if IOResult <> 0 then
   Writeln('Cannot find ', filename)
 else
 begin
 *)
   Close(F);
   (*
   Write('Erase ', filename, '? ');
   Readln(Ch);
   if UpCase(CH) = 'Y' then
   *)
     Erase(F);
 (*
 end;
 *)
end;

function FileExists(filename: string): boolean;
var
  F: Text;
begin
  Assign(F, filename);
  {$I-}
  Reset(F);
  {$I+}
  FileExists := IoResult = 0;
end;

function StrToInt(s: string): Integer;
var
  i, Error: Integer;
begin
  Val(s, i, Error);
  StrToInt := i;
end;

function IntToStr(Value: Integer): string;
var
  s: string;
begin
  Str(Value, s);
  IntToStr := s;
end;

end.
