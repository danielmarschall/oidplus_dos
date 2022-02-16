program LISTTEST;

(************************************************)
(* LISTTEST.PAS                                 *)
(* Author:   Daniel Marschall                   *)
(* Revision: 2022-02-16                         *)
(* License:  Apache 2.0                         *)
(* This file contains:                          *)
(* - Example how to use lists and selection CUI *)
(************************************************)

uses
  Crt, Drivers, StrList, VtsCui;

var
  items: PStringList;
  i, itemIndex: integer;
  sTmp: string;
begin
  InitVideo;
  CursorOff;

  CreateList(items);

  (* Fill the list for testing *)
  for i := 1 to 5 do
  begin
    str(i, sTmp);
    ListAppend(items, 'list item '+sTmp);
  end;

  (* Do inserts and deletions to test their functionality *)
  ListInsert(items, 'TEST', 0);
  ListDeleteElementByIndex(items, 0);
  ListDeleteElementByIndex(items, 0);
  ListInsert(items, 'FirstElement', 0);

  (* Test the selection GUI unit *)
  ClrScr;
  itemIndex := DrawSelectionList(3, 5, 15, 10, items, true, '', 0);
  ResetDefaultDosColors;
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

  CursorOn;
  DoneVideo;
end.
