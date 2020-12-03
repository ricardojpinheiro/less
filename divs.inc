(*<diversos.inc>
 * Several routines.
 * CopyLeft (c) since 2020 by Ricardo Jurczyk Pinheiro.
 *)

(**
  *
  * $Id: $
  * $Author: $
  * $Date: $
  * $Revision: $
  * $HeadURL: $
  *)

(*
 * This module depends on folowing include files (respect the order):
 * Yada-yada-yada
 *)

 
(*
* User defined variables.
*)
type
    str8 = string[8];

(*
* Integer Division using real numbers.
*)

function IntegerDivision (a, b: real): integer;
begin
    IntegerDivision := round(int((a - (a - (b * (a / b)))) / b));
end;

(*
* Integer Remainder using real numbers.
*)

function IntegerRemainder (a, b: real): integer;
begin
    IntegerRemainder := round(int(a - (b * round(int(a / b)))));
end;

(*
* Convert from real to hexadecimal - up to 4.294.967.295.
*)

Function I2Hex (L: real): str8;
const
    D = 16;
var
    S : str8;
    N : integer;
    R : integer;
begin
    S := '';
    if L < 0 then
        L := (((-1 * (maxint)) + L) * -1) + 1;
    for N := 1 to sizeof(S) - 1 do
    begin
        R := IntegerRemainder(L, D); { remainder }
        L := IntegerDivision(L, D); { for next dividing/digit }
        if R <= 9 then
            S := chr (R + 48) + S { 0.. 9 -> '0'..'9' (#48.. #57) }
        else
            S := chr (R + 87) + S; { 10..15 -> 'a'..'f' (#97..#102) }
    end;
    I2Hex := S; { the output in exactly 8 digits }
end; { I2Hex }
