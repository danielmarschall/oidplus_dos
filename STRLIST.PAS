unit STRLIST;

(************************************************)
(* STRLIST.PAS                                  *)
(* Author:   Daniel Marschall                   *)
(* Revision: 2022-10-10                         *)
(* License:  Apache 2.0                         *)
(* This file contains:                          *)
(* - StringList implementation for Turbo Pascal *)
(************************************************)

interface

type
  PStringList = ^TStringList;
  TStringList = record
    init: boolean;
    element: string;
    next: PStringList;
  end;

procedure CreateList(var list: PStringList);
procedure FreeList(list: PStringList);
function ListContains(list: PStringList; val: string): boolean;
procedure ListClear(list: PStringList);
function ListAppend(list: PStringList; str: string): integer;
function ListCount(list: PStringList): integer;
function ListDeleteElementByIndex(list: PStringlist; idx: integer): boolean;
function ListDeleteElementByValue(list: PStringlist; val: string): boolean;
function ListGetElement(list: PStringList; idx: integer): string;
procedure ListSetElement(list: PStringList; idx: integer; value: string);
procedure ListInsert(list: PStringlist; str: string; idx: integer);
procedure ListSwapElement(list: PStringList; i, j: integer);
procedure SplitStrToList(str: string; list: PStringList; separator: string);
procedure OIDtoArcList(oid: string; list: PStringList);
procedure ListBubbleSortNumericString(list: PStringList);
function ListLoadFromFile(list: PStringList; filename: string): boolean;
function ListSaveToFile(list: PStringList; filename: string): boolean;

implementation

uses
  VtsFuncs;

procedure CreateList(var list: PStringList);
begin
  GetMem(list, SizeOf(TStringList));
  list^.init := false;
  list^.element := '';
  list^.next := nil;
end;

procedure FreeList(list: PStringList);
begin
  if list^.next <> nil then
    FreeList(list^.Next);
  FreeMem(list, SizeOf(TStringList));
end;

function ListContains(list: PStringList; val: string): boolean;
var
  i: integer;
begin
  ListContains := false;
  for i := 0 to ListCount(list)-1 do
  begin
    if ListGetElement(list, i) = val then
    begin
      ListContains := true;
      break;
    end;
  end;
end;

procedure ListClear(list: PStringList);
begin
  while ListCount(list) > 0 do
  begin
    ListDeleteElementByIndex(list, 0);
  end;
end;

function ListAppend(list: PStringList; str: string): integer;
var
  new: PStringList;
  tmp: PStringList;
  cnt: integer;
begin
  cnt := 0;
  if not list^.init then
  begin
   list^.element := str;
   list^.init := true;
  end
  else
  begin
    Inc(cnt);
    GetMem(new, sizeof(TStringList));
    new^.element := str;
    new^.next := nil;
    new^.init := true;

    tmp := list;
    while tmp^.next <> nil do
    begin
      tmp := tmp^.next;
      Inc(cnt);
    end;

    tmp^.next := new;
  end;

  ListAppend := cnt; (* Return the index where the new element was put *)
end;

function ListCount(list: PStringList): integer;
var
  cnt: integer;
  tmp: PStringList;
begin
  tmp := list;
  cnt := 0;

  if tmp^.init then
  begin
    repeat
      Inc(cnt);
      tmp := tmp^.next;
    until tmp = nil;
  end;

  ListCount := cnt;
end;

function ListDeleteElementByIndex(list: PStringlist; idx: integer): boolean;
var
  tmp, tmp2, prev: PStringList;
  i: integer;
begin
  ListDeleteElementByIndex := false;
  if idx < 0 then exit;
  if idx > ListCount(list)-1 then exit;

  tmp := list;
  prev := nil;
  i := 0;
  while i < idx do
  begin
    prev := tmp;
    tmp := tmp^.next;
    inc(i);
  end;
  if prev = nil then
  begin
    if tmp^.next = nil then
    begin
      tmp^.init := false;
    end
    else
    begin
      tmp^.init := true;
      tmp^.element := tmp^.next^.element;
      tmp2 := tmp^.next;
      tmp^.next := tmp^.next^.next;
      FreeMem(tmp2, SizeOf(TStringList));
    end;
  end
  else
  begin
    prev^.next := tmp^.next;
    FreeMem(tmp, SizeOf(TStringList));
  end;

  ListDeleteElementByIndex := true;
end;

function ListDeleteElementByValue(list: PStringlist; val: string): boolean;
var
  i: integer;
begin
  ListDeleteElementByValue := false;
  for i := 0 to ListCount(list)-1 do
  begin
    if ListGetElement(list, i) = val then
    begin
      ListDeleteElementByValue := ListDeleteElementByIndex(list, i);
      exit;
    end;
  end;
end;

function ListGetElement(list: PStringList; idx: integer): string;
var
  tmp: PStringList;
  i: integer;
begin
 if (idx < 0) or (idx > ListCount(list)-1) then
  begin
    ListGetElement := '';
    Exit;
  end;

  tmp := list;
  i := 0;
  while i < idx do
  begin
    tmp := tmp^.next;
    inc(i);
  end;

  ListGetElement := tmp^.element;
end;

procedure ListSetElement(list: PStringList; idx: integer; value: string);
var
  tmp: PStringList;
  i: integer;
begin
  if idx < 0 then exit;
  if idx > ListCount(list)-1 then exit;

  tmp := list;
  i := 0;
  while i < idx do
  begin
    tmp := tmp^.next;
    inc(i);
  end;

  tmp^.element := value;
end;

procedure ListInsert(list: PStringlist; str: string; idx: integer);
var
  tmp, new: PStringList;
  i: integer;
begin
  if idx < 0 then exit;
  if idx > ListCount(list)-1 then exit;

  tmp := list;
  i := 0;
  while i < idx do
  begin
    tmp := tmp^.next;
    inc(i);
  end;

  GetMem(new, sizeof(TStringList));
  new^.init := true;
  new^.next := tmp^.next;
  new^.element := tmp^.element;

  tmp^.element := str;
  tmp^.next := new;
  tmp^.init := true;
end;

procedure ListSwapElement(list: PStringList; i, j: integer);
var
  a, b: string;
begin
  a := ListGetElement(list, i);
  b := ListGetElement(list, j);
  ListSetElement(list, i, b);
  ListSetElement(list, j, a);
end;

procedure SplitStrToList(str: string; list: PStringList; separator: string);
var
  p: integer;
begin
  repeat
    p := Pos(separator, str);
    if p = 0 then
    begin
      ListAppend(list, str);
      Exit;
    end
    else
    begin
      ListAppend(list, Copy(str, 1, p-1));
      str := copy(str, p+Length(separator), Length(str)-p);
    end;
  until str = '';
end;

procedure OIDtoArcList(oid: string; list: PStringList);
begin
  SplitStrToList(oid, list, '.');
end;

procedure ListBubbleSortNumericString(list: PStringList);
var
  n, i: integer;
  a, b: string;
  swapped: boolean;
begin
  n := ListCount(list);
  while n>1 do
  begin
    i := 0;
    swapped := false;
    while i<n-1 do
    begin
      a := ListGetElement(list, i);
      b := ListGetElement(list, i+1);
      if CompareNumericString(a, b) > 0 then
      begin
        ListSwapElement(list, i, i+1);
        swapped := true;
      end;
      Inc(i);
    end;
    if not swapped then break;
    Dec(n);
  end;
end;

function ListLoadFromFile(list: PStringList; filename: string): boolean;
var
  f: Text;
  s: string;
begin
  Assign(f, filename);

  {$I-}
  Reset(f);
  {$I+}
  if IoResult <> 0 then
  begin
    ListLoadFromFile := false;
    (* Must not call Close(f) if file was never opened *)
    Exit;
  end;

  ListClear(list);

  while not EOF(f) do
  begin
    ReadLn(f, s);
    ListAppend(list, s);
  end;

  Close(f);
  ListLoadFromFile := true;
end;

function ListSaveToFile(list: PStringList; filename: string): boolean;
var
  f: Text;
  i: integer;
  s: string;
begin
  Assign(f, filename);

  {$I-}
  Rewrite(f);
  {$I+}
  if IoResult <> 0 then
  begin
    ListSaveToFile := false;
    (* Must not call Close(f) if file was never opened *)
    Exit;
  end;

  for i := 0 to ListCount(list)-1 do
  begin
    s := ListGetElement(list, i);
    WriteLn(f, s);
  end;

  Close(f);
  ListSaveToFile := true;
end;

end.
