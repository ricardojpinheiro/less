{
   rabinkar.pas
   
   Copyright 2020 Ricardo Jurczyk Pinheiro <ricardo@aragorn>
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
   MA 02110-1301, USA.
   
   
}


program RabinKarp;

const
    b = 251;

type
    TFileName = string[255];

function RabinKarp (Pattern: TFileName; Text: TFileName): integer;
var
    HashPattern, HashText, Bm, j, LengthPattern, LengthText, Result: integer;
    Found : Boolean;
  
begin

(*  Initializing variables. *)

    Found := False;
    Result := 0;
    LengthPattern := length (Pattern);
    HashPattern := 0;
    HashText := 0;
    Bm := 1;
    LengthText := length (Text);

(*  If there isn't any patterns to search, exit. *)

    if LengthPattern = 0 then
    begin
        Result := 1;
        Found := true;
    end;

    if LengthText >= LengthPattern then

(*  Calculating Hash *)

    for j := 1 to LengthPattern do
    begin
        Bm := Bm * b;
        HashPattern := round(int(HashPattern * b + ord(Pattern[j])));
        HashText := round(int(HashText * b + ord(Text[j])));
    end;

    j := LengthPattern;
  
(*  Searching *)

    while not Found do
    begin
        if (HashPattern = HashText) and (Pattern = Copy (Text, j - LengthPattern + 1, LengthPattern)) then
        begin
            Result := j - LengthPattern;
            Found := true
        end;
        if j < LengthText then
        begin
            j := j + 1;
            HashText := round(int(HashText * b - ord (Text[j - LengthPattern]) * Bm + ord (Text[j])));
        end
        else
            Found := true;
    end;
    RabinKarp := Result;
end;

begin
  writeln(RabinKarp('abcde', '0123456abcde'));
  writeln(RabinKarp('abcde', '012345678abcde'));
  writeln(RabinKarp('abcde', '0123456785785758'));
  readln;
end.
