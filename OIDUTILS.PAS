unit OIDUTILS;

(************************************************)
(* OIDUTILS.PAS                                 *)
(* Author:   Daniel Marschall                   *)
(* Revision: 2022-02-19                         *)
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
function UnicodeLabelValid(unicodeLabel: string): boolean;

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
  CreateList(la);
  CreateList(lb);
  OIDtoArcList(a, la);
  OIDtoArcList(b, lb);
  CompareOID := CompareOIDArcList(la, lb);
  FreeList(la);
  FreeList(lb);
end;

procedure ListBubbleSortOID(list: PStringList);
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
      if CompareOID(a, b) > 0 then
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

function UnicodeLabelValid(unicodeLabel: string): boolean;
begin
  UnicodeLabelValid := true;
  (* TODO: Implement *)
  
(*


function iri_char_valid($c, $firstchar, $lastchar) {
	// see Rec. ITU-T X.660, clause 7.5

	if (($firstchar || $lastchar) && ($c == '-')) return false;

	if ($c == '-') return true;
	if ($c == '.') return true;
	if ($c == '_') return true;
	if ($c == '~') return true;
	if (($c >= '0') && ($c <= '9') && (!$firstchar)) return true;
	if (($c >= 'A') && ($c <= 'Z')) return true;
	if (($c >= 'a') && ($c <= 'z')) return true;

	$v = mb_ord($c);

	if (($v >= 0x000000A0) && ($v <= 0x0000DFFE)) return true;
	if (($v >= 0x0000F900) && ($v <= 0x0000FDCF)) return true;
	if (($v >= 0x0000FDF0) && ($v <= 0x0000FFEF)) return true;
	if (($v >= 0x00010000) && ($v <= 0x0001FFFD)) return true;
	if (($v >= 0x00020000) && ($v <= 0x0002FFFD)) return true;
	if (($v >= 0x00030000) && ($v <= 0x0003FFFD)) return true;
	if (($v >= 0x00040000) && ($v <= 0x0004FFFD)) return true;
	if (($v >= 0x00050000) && ($v <= 0x0005FFFD)) return true;
	if (($v >= 0x00060000) && ($v <= 0x0006FFFD)) return true;
	if (($v >= 0x00070000) && ($v <= 0x0007FFFD)) return true;
	if (($v >= 0x00080000) && ($v <= 0x0008FFFD)) return true;
	if (($v >= 0x00090000) && ($v <= 0x0009FFFD)) return true;
	if (($v >= 0x000A0000) && ($v <= 0x000AFFFD)) return true;
	if (($v >= 0x000B0000) && ($v <= 0x000BFFFD)) return true;
	if (($v >= 0x000C0000) && ($v <= 0x000CFFFD)) return true;
	if (($v >= 0x000D0000) && ($v <= 0x000DFFFD)) return true;
	if (($v >= 0x000E1000) && ($v <= 0x000EFFFD)) return true;

	// Note: Rec. ITU-T X.660, clause 7.5.3 would also forbid ranges which are marked
        // in ISO/IEC 10646 as "(This position shall not be used)"
	// But tool implementers should be tolerate them, since these limitations can be removed in future.

	return false;
}

function iri_arc_valid($arc, $allow_numeric=true) {
	if ($arc == '') return false;

	$m = array();
	if ($allow_numeric && preg_match('@^(\\d+)$@', $arc, $m)) return true; # numeric arc

	// Question: Should we strip RTL/LTR characters?

	if (mb_substr($arc, 2, 2) == '--') return false; // see Rec. ITU-T X.660, clause 7.5.4

	$array = array();
	preg_match_all('/./u', $arc, $array, PREG_SET_ORDER);
	$len = count($array);
	foreach ($array as $i => $char) {
		if (!iri_char_valid($char[0], $i==0, $i==$len-1)) return false;
	}

	return true;
}


*)  
  
end;

end.
