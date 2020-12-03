{
   scrldemo.pas
   
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

program scrldemo;

{$i d:types.inc}
{$i d:fastwrit.inc}

const
{
  UpArrow = #30;
  DownArrow = #31;
  ESC = #27;
  Enter = #13;
  Null = #00;
  Select = #24; 
  Home = #11;
  Ins = #18;
  Del = #127;
}
    CALSLT = $001C;
    WRTVDP = $0047;
    RDVRM  = $004A;
    WRTVRM = $004D;
    SETRD  = $0050;
    SETWRT = $0053;
    FILVRM = $0056;
    LDIRMV = $0059;
    LDIRVM = $005C;
    INITXT = $006C;
    SETTXT = $0078;
    NAMBAS = $F922;
    EXPTBL = $FCC1;

    _CALROM: array[0..6] of byte = ($FD,$21,$00,$00,$C3,$D4,$20);
{
type
    TString = string[40];
}
var
    i, j, k, l: integer;
    Number: string[5];
    temp: string[40];
    Buffer: array [1..2048] of byte;
    Character: char;
    OriginalRegister9Value: byte;
    
    VDPSAV1: array[0..7]  of byte absolute $F3DF;
    VDPSAV2: array[8..23] of byte absolute $FFE7;
    TXTNAM : integer absolute $f3b3;
    TXTCGP : integer absolute $f3b7;
    LINL40 : integer absolute $f3ae;
    
Procedure CallBas(AC: byte; BC, DE, HL, IX: integer);
begin
    inline($F3/$CD/*+19/$FB/$32/AC/$22/HL/$43ED/BC/$53ED/DE/$1B18/
            $2ADD/IX/$3A/AC/$2A/HL/$4BED/BC/$5BED/DE/$08/$DB/$A8/$F5/
            $F0E6/$C3/$F38C);
END;

Procedure SetVDP(VdpRegister, Value: Byte);
Begin
    Inline(
           $f3/                 {Di}
           $3a/VdpRegister/     {LD a,(VdpReg)}
           $4f/                 {LD c,a}
           $3a/Value/           {LD a,(value)}
           $47/                 {LD b,a}
           $fd/$2a/$f7/$fa/     {ld iy,(exbrsa-)}
           $dd/$21/$2d/1/       {ld ix,WrtVdp}
           $cd/$1c/00           {call calslt}
           );
end;

function GetVDP (register: byte): byte;
begin
    if register < 8 then
        GetVDP:=VDPSAV1[register]
    else
        GetVDP:=VDPSAV2[register];
end;

Procedure ScrollText(FirstLine, LastLine: Byte);
const
    HeightScreen = 23;
    WidthScreen  = 80;
    FullText     = 2048;
var
    Buffer: array [1..FullText] of byte;
    FirstLineAddr, LastLineAddr, BlockSize: integer;
begin
    FirstLineAddr   := (FirstLine - 1)  * WidthScreen;
    LastLineAddr    := (LastLine - 1)   * WidthScreen;
    BlockSize       := HeightScreen     * WidthScreen;

    CallBas(0,  BlockSize, addr(Buffer), FirstLineAddr, LDIRMV);
    CallBas(32, BlockSize, addr(Buffer), FirstLineAddr, FILVRM);    
    CallBas(0,  BlockSize, LastLineAddr, addr(Buffer),  LDIRVM);
end; 

procedure InfoAboutVDP;
begin
    writeln('Text width: ', LINL40);
    writeln('Pattern name table address: ', TXTNAM);
    writeln('Pattern generator table address: ', TXTCGP);
end;

procedure SetExtendedScreen;
begin
    OriginalRegister9Value := getVDP(9);
    SetVDP(9, OriginalRegister9Value + 128);
    CallBas(32, $0C00, 0, 0, FILVRM);
end;

procedure SetOriginalScreen;
begin
    TXTNAM := 0;
    CallBas (0, 0, 0, 0, INITXT);
    setVDP(9, OriginalRegister9Value);
end;

procedure Example (YPosition, HowManyLines: byte);
begin
    gotoxy(1, YPosition);
    
    for i:= 1 to HowManyLines do 
    begin
        fillchar(temp, sizeof(temp), chr(random(26) + 65));
        str(i, Number);
        temp := concat('Line ', Number, ' - ', temp);
        fastwriteln(temp);
    end;
    writeln('Printed lines on the screen, from 1 to ', HowManyLines,'.');
end;

function Inkey:char;
var bt:integer;
    qqc:byte absolute $FCA9;
begin
     Inkey:=chr(0);
     qqc:=1;
     Inline($f3/$fd/$2a/$c0/$fc/$DD/$21/$9F/00     
            /$CD/$1c/00/$32/bt/$fb);
     Inkey:=chr(bt);
     qqc:=0;
end;

procedure sandbox;
const
    RightArrow = #28;
    LeftArrow = #29;
    UpArrow = #30;
    DownArrow = #31;
    Space = #32;
var
    ch : char;
begin  
    clrscr;
    ch := #00;
    while ch <> Space do
    begin
        ch:=Inkey;
        writeln(ch,'  ',ord(ch));
    end;
end;

procedure ScrollUp;
begin
{
* Print 7 lines with rubbish, starting at the line 10.
}
    clrscr;
    Example (1, 22);

    gotoxy (44, 23);
    writeln('Scroll up: from line 10 to 9.');
    readln;
    ScrollText(10, 9);
    readln;
    CallBas(32, $0C00, 0, 0, FILVRM);
end;

procedure ScrollDown;
begin
{
* Print 20 lines with rubbish, starting at the line 1.
}
    clrscr;
    Example (1, 20);

    gotoxy(1, 23);
    writeln('Scroll down: From line 1 to 10.');
    readln;
    ScrollText(1, 10);
    readln;
    CallBas(32, $0C00, 0, 0, FILVRM);
end;

procedure PlacingDataIntoVRAM;
begin
{
* We'll use the VRAM as a memory buffer. 
* Start at $2000 (8192), end at $5000 (20480). 
* Buffer will receive 2048 characters, from A to the last one.
* In the 1600th position, we'll get a message. 
* The CallBas procedure will be used to copy from Buffer array variable 
* to the VRAM, in the position designed by the i variable.
* We'll get $0800 increments.
}
    clrscr;
    i := $2000;
    l := 1;
    while i < $4000 do
    begin
        fillchar(Buffer, sizeof(Buffer), ord(l + 64));
        writeln('VRAM Page ',l , ' filled. Position ', i, ' Character: ', chr(l + 64));
        str(l, Number);
        temp := concat (' Page ', Number);
        for j := 1 to length(temp) do
            Buffer[1600 + j] := ord(temp[j]);
        CallBas(0, $0800, i, addr(Buffer), LDIRVM);
        i := i + $1000;
        l := l + 1;
    end;
    readln;
end;

procedure RetrievingDataFromVRAM;
begin

{
* Here goes the VRAM pages routine.
* Start at $2000 (8192), end at $5000 (20480). 
* The CallBas procedure will be used to change to text-mode 1.
* TXTNAM receives the address.
* We'll get $1000 increments.
}

    i := $2000;
    while i < $4000 do
    begin
        TXTNAM := i;
        CallBas (0, 0, 0, 0, SETTXT);
        gotoxy (1, 20); writeln('Position ',i, ' selected.');
        readln;
        i := i + $1000;
    end;
    TXTNAM := 0;
    CallBas (0, 0, 0, 0, SETTXT);
end;

BEGIN
    CallBas(0, 0, 0, 0, INITXT);
    randomize;

    while (Character <> 'F') do
    begin
        clrscr;
        fastwriteln(' Scroll and SCREEN 0 pages demo program: ');
        fastwriteln(' Choose your weapon: ');
        fastwriteln(' 1 - Information about VDP.');
        fastwriteln(' 2 - Set extended screen (26,5 lines).');
        fastwriteln(' 3 - Scroll up.');
        fastwriteln(' 4 - Scroll down.');
        fastwriteln(' 5 - Placing data into SCREEN 0 pages.');
        fastwriteln(' 6 - Retrieving data from SCREEN 0 pages.');
        fastwriteln(' 7 - Sandbox.');
        fastwriteln(' F - End.');
        read(kbd, Character);
        Character := upcase(Character);
        case Character of 
            '1': InfoAboutVDP;
            '2': SetExtendedScreen;
            '3': ScrollUp;
            '4': ScrollDown;
            '5': PlacingDataIntoVRAM;
            '6': RetrievingDataFromVRAM;
            '7': sandbox;
            'F': exit;
        end;
        readln;
    end;        
    
    SetOriginalScreen;

END.
