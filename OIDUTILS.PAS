unit OIDUTILS;

(************************************************)
(* OIDUTILS.PAS                                 *)
(* Author:   Daniel Marschall                   *)
(* Revision: 2022-02-12                         *)
(* License:  Apache 2.0                         *)
(* This file contains:                          *)
(* - Various OID functions                      *)
(************************************************)

interface

uses
  StrList;
  
function CompareOIDArcList(a, b: PStringList): integer;
function CompareOID(a, b: string): integer;
procedure ListBubbleSortOID(list: PStringList);
function ASN1IDValid(asn1id: string): boolean;

implementation

uses
  VtsFuncs;

function CompareOIDArcList(a, b: PStringList): integer;
var
  x, y: PStringList;
  tmp: integer;
begin
  x := a;
  y := b;

  repeat
    if (x = nil) and (y <> nil) then
    begin
      CompareOIDArcList := -1;
      exit;
    end;

    if (x <> nil) and (y = nil) then
    begin
      CompareOIDArcList := 1;
      exit;
    end;

    if (x = nil) and (y = nil) then
    begin
      CompareOIDArcList := 0;
      exit;
    end;

    tmp := CompareNumericString(x^.element, y^.element);

    if tmp <> 0 then
    begin
      CompareOIDArcList := tmp;
      exit;
    end;

    x := x^.next;
    y := y^.next;
  until false;
end;

function CompareOID(a, b: string): integer;
var
  la, lb: PStringList;
begin
  InitList(la);
  InitList(lb);
  OIDtoArcList(a, la);
  OIDtoArcList(b, lb);
  CompareOID := CompareOIDArcList(la, lb);
end;

procedure ListBubbleSortOID(list: PStringList);
var
  n, i: integer;
  a, b: string;
begin
  n := ListCount(list);
  while n>1 do
  begin
    i := 0;
    while i<n-1 do
    begin
      a := ListGetElement(list, i);
      b := ListGetElement(list, i+1);
      if CompareOID(a, b) > 0 then
      begin
        ListSwapElement(list, i, i+1);
      end;
      Inc(i);
    end;
    Dec(n);
  end;
end;

function ASN1IDValid(asn1id: string): boolean;
var
  i: integer;
  lastChar: char;
begin
  (* see Rec. ITU-T X.660 | ISO/IEC 9834-1, clause 7.7  *)
  (* and Rec. ITU-T X.680 | ISO/IEC 8824-1, clause 12.3 *)

  ASN1IDValid := false;

  if Length(asn1id) = 0 then exit; (* may not be empty *)
  if not (asn1id[1] in ['a'..'z']) then exit; (* first char must be lowercase *)

  lastChar := #0;
  for i := 1 to Length(asn1id) do
  begin
    if (lastChar = '-') and (asn1id[i] = '-') then exit; (* may not contain '--' *)
    if not (asn1id[i] in ['a'..'z', 'A'..'Z', '0'..'9', '-']) then exit;
    lastChar := asn1id[i];
  end;
  if lastChar = '-' then exit; (* may not end with '-' *)
  ASN1IDValid := true;
end;

end.
