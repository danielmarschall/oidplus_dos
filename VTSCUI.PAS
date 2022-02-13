unit VTSCUI;

(************************************************)
(* VTSCUI.PAS                                   *)
(* Author:   Daniel Marschall                   *)
(* Revision: 2022-02-12                         *)
(* License:  Apache 2.0                         *)
(* This file contains:                          *)
(* - ViaThinkSoft CUI (Console User Interface)  *)
(************************************************)

interface

uses
  StrList;

const
  ScreenWidth = 80;
  ScreenHeight = 25;
  SINGLE_LINE_BOX_PADDING = 3;
  SINGLE_LINE_BOX_PADDING_INNER = 10;

procedure DrawThinBorder(x, y, width, height: integer);
procedure DrawDoubleBorder(x, y, width, height: integer);
procedure DrawTextBar(str: string; line: integer);
procedure DrawTitleBar(str: string);
procedure DrawStatusBar(str: string);
function DrawSelectionList(X, Y, ListWidth, ListHeight: integer;
                           items: PStringList; allowESC: boolean;
                           Title: string; borderStrength: integer): integer;
procedure ClearSection(x, y, width, height: integer);
function QueryVal(var s: string; initX, initY, width, height: integer;
                  Title: string; borderStrength: integer): boolean;
procedure ShowMessage(msg: string; title: string; dobeep: boolean);

implementation

uses
  Crt, Drivers, VtsFuncs;

type
  TCharDefs = array[0..7] of char;

const
  ThinLineChars: TCharDefs =
    ( #$DA, #$C4, #$BF,
      #$B3,       #$B3,
      #$C0, #$C4, #$D9
    );
  DoubleLineChars: TCharDefs =
    ( #$C9, #$CD, #$BB,
      #$BA,       #$BA,
      #$C8, #$CD, #$BC
    );

function FillRight(str: string; len: integer; c: char): string;
var
  s: string;
  i: integer;
begin
  s := str;
  for i := Length(str) to len-1 do
  begin
    s := s + c;
  end;
  FillRight := s;
end;

procedure DrawBorder(x, y, width, height, thickness: integer);
var
  ix,iy: integer;
  chars: TCharDefs;
begin
  if thickness = 1 then
    chars := ThinLineChars;
  if thickness = 2 then
    chars := DoubleLineChars;

  (* Top line *)
  if y >= 1 then
  begin
    (* Top left corner *)
    if x >= 1 then
    begin
      GotoXY(x,y);
      Write(chars[0]);
    end
    else
    begin
      GotoXY(1,y);
    end;

    (* Top edge *)
    for ix := 1 to width-2 do
      Write(chars[1]);

    (* Top right corner *)
    if x+width-1 <= ScreenWidth then
      Write(chars[2]);
  end;

  (* Left edge *)
  for iy := 1 to height-2 do
  begin
    if (x    >= 1) and (x    <= ScreenWidth) and
       (y+iy >= 1) and (y+iy <= ScreenHeight) then
    begin
      GotoXY(x,y+iy);
      Write(chars[3]);
    end;
  end;

  (* Right edge *)
  for iy := 1 to height-2 do
  begin
    if (x+width-1 >= 1) and (x+width-1 <= ScreenWidth) and
       (y+iy      >= 1) and (y+iy      <= ScreenHeight) then
    begin
      GotoXY(x+width-1,y+iy);
      Write(chars[4]);
    end;
  end;

  (* Bottom line *)
  if y+height-1 <= ScreenHeight then
  begin
    (* Bottom left corner *)
    if x >= 1 then
    begin
      GotoXY(x,y+height-1);
      Write(chars[5]);
    end
    else
    begin
      GotoXY(1,y+height-1);
    end;

    (* Bottom edge *)
    for ix := 1 to width-2 do
      Write(chars[6]);

    (* Bottom right corner *)
    if x+width-1 <= ScreenWidth then
      Write(chars[7]);
  end;
end;

procedure DrawThinBorder(x, y, width, height: integer);
begin
  DrawBorder(x, y, width, height, 1);
end;

procedure DrawDoubleBorder(x, y, width, height: integer);
begin
  DrawBorder(x, y, width, height, 2);
end;

procedure DrawTextBar(str: string; line: integer);
var
  i, left, right: integer;
  len: integer;
begin
  GotoXY(1,line);

  TextBackground(White);
  TextColor(Black);
  len := Length(str);

  left := round((ScreenWidth-len)/2);
  right := ScreenWidth - left - len;

  for i := 1 to left do
  begin
    Write(' ');
  end;

  Write(str);

  (* TODO: If we do "for i := 1 to right", then the console will scroll *)
  (*       since the char in the right bottom corner is written!        *)
  for i := 1 to right-1 do
  begin
    Write(' ');
  end;

  TextBackground(Black);
  TextColor(White);
end;

procedure DrawTitleBar(str: string);
begin
  DrawTextBar(str, 1);
end;

procedure DrawStatusBar(str: string);
begin
  DrawTextBar(str, ScreenHeight);
end;

function DrawSelectionList(X, Y, ListWidth, ListHeight: integer;
                           items: PStringList; allowESC: boolean;
                           Title: string; borderStrength: integer): integer;
var
  i: integer;
  itemIndex: integer;
  sc: char;
  iStartScope, iEndScope: integer;
label
  doAgain;
begin
  if borderStrength = 1 then
  begin
    DrawThinBorder(X-1, Y-1, ListWidth+2, ListHeight+2);
  end;

  if borderStrength = 2 then
  begin
    DrawDoubleBorder(X-1, Y-1, ListWidth+2, ListHeight+2);
  end;

  if Title <> '' then
  begin
    if borderStrength > 0 then
      GoToXY(X+1, Y-1)
    else
      GoToXY(X, Y-1);
    Write(Title);
  end;

  (*CursorOff;*)

  itemIndex := 0;
  iStartScope := itemIndex;
  iEndScope := itemIndex + ListHeight;

doAgain:

  if itemIndex < 0 then
    itemIndex := 0;
  if itemIndex > ListCount(items)-1 then
    itemIndex := ListCount(items)-1;

  if itemIndex < iStartScope then
  begin
    Dec(iEndScope);
    Dec(iStartScope);
  end;

  if itemIndex > iEndScope-1 then
  begin
    Inc(iEndScope);
    Inc(iStartScope);
  end;

  if borderStrength > 0 then
  begin
    (* Show scroll arrows *)
    GotoXY(X+ListWidth, Y);
    if iStartScope > 0 then
    begin
      TextBackground(White);
      TextColor(Black);
      WriteLn(#$18(*ArrowUp*));
      TextBackground(Black);
      TextColor(White);
    end
    else if borderStrength = 1 then
      WriteLn(ThinLineChars[4])
    else if borderStrength = 2 then
      WriteLn(DoubleLineChars[4]);

    GotoXY(X+ListWidth, Y+ListHeight-1);
    if ListCount(items) > iEndScope then
    begin
      TextBackground(White);
      TextColor(Black);
      WriteLn(#$19(*ArrowDown*));
      TextBackground(Black);
      TextColor(White);
    end
    else if borderStrength = 1 then
      WriteLn(ThinLineChars[4])
    else if borderStrength = 2 then
      WriteLn(DoubleLineChars[4]);
  end;

  for i := iStartScope to iEndScope-1 do
  begin
    if itemIndex = i then
    begin
      TextColor(Black);
      TextBackground(White);
    end
    else
    begin
      TextColor(White);
      TextBackground(Black);
    end;
    GotoXY(x,y+i-iStartScope);
    if i > ListCount(items)-1 then
      Write(FillRight('', ListWidth, ' '))
    else
      Write(FillRight(ListGetElement(items, i), ListWidth, ' '));
    TextColor(White);
    TextBackground(Black);
  end;

  repeat
    GotoXY(ScreenWidth, ScreenHeight);

    sc := ReadKey;
    if sc = #$00(*ExtendedKeyCode*) then
    begin
      sc := ReadKey;
      if sc = #$48(*UpKey*) then
      begin
        dec(itemIndex);
        goto doAgain;
      end
      else if sc = #$50(*DownKey*) then
      begin
        inc(itemIndex);
        goto doAgain;
      end
      else if sc = #$47(*POS1*) then
      begin
        itemIndex := 0;
        goto doAgain;
      end
      else if sc = #$4F(*END*) then
      begin
        itemIndex := ListCount(items);
        goto doAgain;
      end;
    end;

    if sc = #13(*Return*) then
    begin
      DrawSelectionList := itemIndex;
      break;
    end;

    if allowESC and (sc = #27(*ESC*)) then
    begin
      DrawSelectionList := -1;
      break;
    end;
  until false;

  (*CursorOn;*)
end;

procedure ClearSection(x, y, width, height: integer);
var
  ix, iy: integer;
begin
  for iy := y to y+height-1 do
  begin
    for ix := x to x+width-1 do
    begin
      GoToXY(ix,iy);
      Write(' ');
    end;
  end;
end;

function QueryVal(var s: string; initX, initY, width, height: integer;
                  Title: string; borderStrength: integer): boolean;
var
  x, y: integer;
  i, j: integer;
  sc: char;
  stmp: string;
begin
  if borderStrength = 1 then
    DrawThinBorder(initX-1,initY-1,width+2,height+2);
  if borderStrength = 2 then
    DrawDoubleBorder(initX-1,initY-1,width+2,height+2);
  if title <> '' then
  begin
    if borderStrength > 0 then
      GoToXY(initX+1, initY-1)
    else
      GoToXY(initX, initY-1);
    Write(title);
  end;
  ClearSection(initX,initY,width,height);

  x := initX;
  y := initY;

  (* Write existing string value and set cursor *)
  stmp := s;
  s := '';
  for i := 1 to Length(stmp) do
  begin
    if stmp[i] = #10 then
    begin
      s := s + stmp[i];
      continue;
    end;

    GoToXY(x,y);
    s := s + stmp[i];
    Write(stmp[i]);
    Inc(x);

    if (x=initX+width-1) and (y=initY+height-1) then
    begin
      (* Attention: Data following after this will be lost! *)
      break;
    end;

    if stmp[i] = #13 then
    begin
      if y=initY+height-1 then
      begin
        (* Attention: Data following after this will be lost! *)
        s := Copy(s, 1, Length(s)-1);
        Dec(x);
        break;
      end;
      x := initX;
      Inc(y);
      continue;
    end;

    if x=initX+width then
    begin
      Inc(y);
      x := initX;
    end;
  end;

  repeat
    GotoXY(x, y);
    sc := ReadKey;

    if sc = #0 then
    begin
      (* Extended key code *)
      sc := ReadKey;
      (* TODO: Implement keys like DEL, END, POS1, and ArrowKeys *)
      Beep;
      continue;
    end
    else if sc = #8(*Backspace*) then
    begin
      if x <= initX then
      begin
        if y = initY then
        begin
          Beep;
          continue;
        end;
        Dec(y);

        (* Find out length of previous line *)
        j := Length(s)-2(*CRLF*);
        while (j >= 0) do
        begin
          if (s[j]=#13) or (s[j]=#10) then break;
          Dec(j);
        end;
        j := Length(s)-2(*CRLF*)-j;
        x := initX + j;
        s := Copy(s, 1, Length(s)-1); (* Remove #10 now. #13 will be removed below *)
      end
      else
      begin
        Dec(x);
      end;
      GotoXY(x, y);
      Write(' ');
      GotoXY(x, y);
      s := Copy(s, 1, Length(s)-1);
      continue;
    end
    else if sc = #13(*Return*) then
    begin
      if GetShiftState and kbRightShift <> 0 then
      begin
        if y=initY+height-1 then
        begin
          Beep;
          continue;
        end;
        s := s + #13 + #10;
        x := initX;
        Inc(y);
      end
      else
      begin
        QueryVal := true;
        exit;
      end;
    end
    else if sc = #27(*ESC*) then
    begin
      QueryVal := false;
      exit;
    end
    else
    begin
      if (x=initX+width-1) and (y=initY+height-1) then
      begin
        Beep;
        continue;
      end;
      s := s + sc;
      Write(sc);
      Inc(x);
      if x >= initX+width then
      begin
        Inc(y);
        x := initX;
      end;
    end;
  until false;
end;

procedure ShowMessage(msg: string; title: string; dobeep: boolean);
var
  x, y, w, h: integer;
begin
  x := SINGLE_LINE_BOX_PADDING_INNER;
  y := ScreenHeight div 2 - 1;
  w := ScreenWidth - (SINGLE_LINE_BOX_PADDING_INNER-1)*2;
  h := 1;
  DrawDoubleBorder(x-1, y, w+2, h+2);
  ClearSection(x, y+1, w-2, h);
  if title <> '' then
  begin
    GoToXY(x+1, y);
    Write(title);
  end;
  GoToXY(x, y+1);
  Write(msg);
  if DoBeep then Beep;
end;

end.
