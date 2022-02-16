unit VTSFUNCS;

(************************************************)
(* VTSFUNCS.PAS                                 *)
(* Author:   Daniel Marschall                   *)
(* Revision: 2022-02-16                         *)
(* License:  Apache 2.0                         *)
(* This file contains:                          *)
(* - Various functions                          *)
(************************************************)

interface

function Max(a, b: integer): integer;
function Min(a, b: integer): integer;

function CompareEqualLengthString(a, b: string): integer;
function CompareNumericString(a, b: string): integer;

procedure Beep;

function Trim(s: string): string;
function TrimLineToWidth(s: string; width: integer): string;
function ZeroPad(i: LongInt; n: integer): string;
function LeftPadStr(s: string; n: integer; ch: char): string;
function RightPadStr(s: string; n: integer; ch: char): string;
function RepeatStr(ch: char; n: integer): string;

function DeleteFile(filename: string): boolean;
function FileExists(filename: string): boolean;

function IsPositiveIntegerOrZero(s: string): boolean;
function StrToInt(s: string): Integer;
function IntToStr(Value: Integer): string;

function StringReplace(s, search, replace: string): string;

implementation

uses
  Crt;

function Max(a, b: integer): integer;
begin
  if a > b then
    Max := a
  else
    Max := b;
end;

function Min(a, b: integer): integer;
begin
  if a < b then
    Min := a
  else
    Min := b;
end;

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
  EqualLength: integer;
begin
  EqualLength := Max(Length(a), Length(b));
  a := LeftPadStr(a, EqualLength, '0');
  b := LeftPadStr(b, EqualLength, '0');
  CompareNumericString := CompareEqualLengthString(a, b);
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

function TrimLineToWidth(s: string; width: integer): string;
begin
  if Length(s) > width then
  begin
    s := Copy(s, 1, width-3) + '...';
  end;
  TrimLineToWidth := s;
end;

function ZeroPad(i: LongInt; n: integer): string;
var
  s: string;
begin
  s := IntToStr(i);
  ZeroPad := LeftPadStr(s, n, '0');
end;

function LeftPadStr(s: string; n: integer; ch: char): string;
begin
  while Length(s) < n do
  begin
    s := ch + s;
  end;
  LeftPadStr := s;
end;

function RightPadStr(s: string; n: integer; ch: char): string;
begin
  while Length(s) < n do
  begin
    s := s + ch;
  end;
  RightPadStr := s;
end;

function RepeatStr(ch: char; n: integer): string;
var
  i: integer;
  res: string;
begin
  res := '';
  for i := 1 to n do
  begin
    res := res + ch;
  end;
  RepeatStr := res;
end;

function DeleteFile(filename: string): boolean;
var
  F:  file;
  Ch: Char;
begin
  Assign(F, filename);
  {$I-}
  Reset(F);
  {$I+}
  if IOResult <> 0 then
  begin
    DeleteFile := false; (* cannot find file *)
  end
  else
  begin
    Close(F);
    {$I-}
    Erase(F);
    {$I+}
    DeleteFile := IOResult = 0;
  end;
end;

function FileExists(filename: string): boolean;
var
  F: Text;
begin
  Assign(F, filename);
  {$I-}
  Reset(F);
  {$I+}
  if IoResult = 0 then
  begin
    Close(F);
    FileExists := true;
  end
  else
  begin
    FileExists := false;
  end;
end;

function IsPositiveIntegerOrZero(s: string): boolean;
var
  i: integer;
begin
  IsPositiveIntegerOrZero := false;

  if Length(s) = 0 then exit;
  if (s[1] = '0') and (s <> '0') then exit;
  for i := 1 to Length(s) do
  begin
    if not (s[i] in ['0'..'9']) then exit;
  end;

  IsPositiveIntegerOrZero := true;
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

function StringReplace(s, search, replace: string): string;
var
  i: integer;
  output: string;
begin
  if s = '' then exit;
  if search = '' then exit; (* invalid arg *)

  output := '';
  while s <> '' do
  begin
    if Copy(s, 1, Length(search)) = search then
    begin
      output := output + replace;
      Delete(s, 1, Length(search));
    end
    else
    begin
      output := output + Copy(s, 1, 1);
      Delete(s, 1, 1);
    end;
  end;

  StringReplace := output;
end;

end.
