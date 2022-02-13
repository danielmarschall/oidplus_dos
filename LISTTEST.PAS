program LISTTEST;

(************************************************)
(* LISTTEST.PAS                                 *)
(* Author:   Daniel Marschall                   *)
(* Revision: 2020-09-09                         *)
(* License:  Apache 2.0                         *)
(* This file contains:                          *)
(* - Example how to use lists and selection CUI *)
(************************************************)

uses
  Crt, StrList, VtsCui;

var
  items: PStringList;
  i, itemIndex: integer;
  sTmp: string;
begin
  InitList(items);

  (* Fill the list for testing *)
  for i := 1 to 5 do
  begin
    str(i, sTmp);
    ListAppend(items, 'list item '+sTmp);
  end;

  (* Do inserts and deletions to test their functionality *)
  ListInsert(items, 'TEST', 0);
  ListDeleteElement(items, 0);
  ListDeleteElement(items, 0);
  ListInsert(items, 'FirstElement', 0);

  (* Test the selection GUI unit *)
  ClrScr;
  itemIndex := DrawSelectionList(3, 5, 15, 10, items, true, 0);
  ClrScr;
  if itemIndex = -1 then
  begin
    WriteLn('Nothing was selected.');
  end
  else
  begin
    WriteLn('Following element was selected: "'+ListGetElement(items,itemIndex)+'"');
  end;
  WriteLn('Press RETURN to return to DOS.');

  FreeList(items);

  ReadLn;
end.
