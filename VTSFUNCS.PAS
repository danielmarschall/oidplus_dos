unit VTSFUNCS;

(************************************************)
(* VTSFUNCS.PAS                                 *)
(* Author:   Daniel Marschall                   *)
(* Revision: 2022-10-11                         *)
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

function StripLeadingZeros(s: string): string;
function IsPositiveIntegerOrZero(s: string): boolean;
function IsBase36String(s: string): boolean;
function TryStrToInt(s: string; var i: LongInt): boolean;
function StrToInt(s: string): LongInt;
function IntToStr(Value: LongInt): string;

function StringReplace(s, search, replace: string): string;

function LastCharPos(const S: string; const Chr: char): integer;
function LowerCase(s: string): string;
function UpperCase(s: string): string;
function base_convert_bigint(numstring: string; frombase, tobase: integer): string;

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

function StripLeadingZeros(s: string): string;
begin
  while (s <> '0') and (Copy(s,1,1) = '0') do
    Delete(s,1,1);

  StripLeadingZeros := s;
end;

function IsPositiveIntegerOrZero(s: string): boolean;
var
  i: integer;
begin
  IsPositiveIntegerOrZero := false;

  if Length(s) = 0 then exit;
  (*if (s[1] = '0') and (s <> '0') then exit;*)
  for i := 1 to Length(s) do
  begin
    if not (s[i] in ['0'..'9']) then exit;
  end;

  IsPositiveIntegerOrZero := true;
end;

function IsBase36String(s: string): boolean;
var
  i: integer;
begin
  IsBase36String := false;

  if Length(s) = 0 then exit;
  (*if (s[1] = '0') and (s <> '0') then exit;*)
  for i := 1 to Length(s) do
  begin
    if not (s[i] in ['0'..'9', 'A'..'Z']) then exit;
  end;

  IsBase36String := true;
end;

function TryStrToInt(s: string; var i: LongInt): boolean;
begin
  if IsPositiveIntegerOrZero(s) then
  begin
    TryStrToInt := true;
    i := StrToInt(s);
  end
  else
  begin
    TryStrToInt := false;
  end;
end;

function StrToInt(s: string): LongInt;
var
  i, Error: Integer;
begin
  Val(s, i, Error);
  StrToInt := i;
end;

function IntToStr(Value: LongInt): string;
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
  if s = '' then
  begin
    StringReplace := '';
    Exit;
  end;
  if search = '' then
  begin
    StringReplace := s;
    exit; (* invalid arg *)
  end;

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

function LastCharPos(const S: string; const Chr: char): integer;
var
  i: Integer;
begin
  for i := length(S) downto 1 do
  begin
    if S[i] = Chr then
    begin
      LastCharPos := i;
      Exit;
    end;
  end;
  LastCharPos := 0;
  Exit;
end;

function LowerCase(s: string): string;
var
  res: string;
  i: integer;
begin
  res := '';
  for i := 1 to Length(s) do
  begin
    if s[i] in ['A'..'Z'] then
    begin
      res := res + Chr(Ord('a')+(Ord(s[i])-Ord('A')));
    end
    else
    begin
      res := res + s[i];
    end;
  end;
  LowerCase := res;
end;

function UpperCase(s: string): string;
var
  res: string;
  i: integer;
begin
  res := '';
  for i := 1 to Length(s) do
  begin
    if s[i] in ['a'..'z'] then
    begin
      res := res + Chr(Ord('A')+(Ord(s[i])-Ord('a')));
    end
    else
    begin
      res := res + s[i];
    end;
  end;
  UpperCase := res;
end;

function base_convert_bigint(numstring: string; frombase, tobase: integer): string;
var
  i: Integer;
  frombase_str: string;
  tobase_str: string;
  len: Integer;
  number: string;
  divide: Integer;
  newlen: Integer;
  res: string;
begin
  frombase_str := '';
  for i := 0 to frombase-1 do
  begin
    if i < 10 then
      frombase_str := frombase_str + IntToStr(i)
    else
      frombase_str := frombase_str + Chr(Ord('A') + (i-10));
  end;

  tobase_str := '';
  for i := 0 to tobase-1 do
  begin
    if i < 10 then
      tobase_str := tobase_str + IntToStr(i)
    else
      tobase_str := tobase_str + Chr(Ord('A') + (i-10));
  end;

  len := Length(numstring);
  base_convert_bigint := '';
  number := numstring; (* this is a fake "Int8" array (implemented with chars) *)
  for i := 0 to len-1 do
  begin
    number[i+1] := Chr(Pos(UpCase(numstring[i+1]), frombase_str)-1);
  end;
  res := '';
  repeat (* Loop until whole number is converted *)
    divide := 0;
    newlen := 0;
    for i := 0 to len-1 do (* Perform division manually (which is why this works with big numbers) *)
    begin
      divide := divide * frombase + Ord(number[i+1]);
      if (divide >= tobase) then
      begin
        number[newlen+1] := Chr(divide div tobase);
        Inc(newlen);
        divide := divide mod tobase;
      end
      else if newlen > 0 then
      begin
        number[newlen+1] := #0;
        Inc(newlen);
      end;
    end;
    len := newlen;
    res := tobase_str[divide+1] + res; (* Divide is basically "numstring mod tobase" (i.e. the new character) *)
  until newlen = 0;
  base_convert_bigint := res;
end;

end.
