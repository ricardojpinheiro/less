{
   scroltest.pas
   
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

program vdpdemo;

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
    CalSlt = $001c;
    WrtVdp = $0047;
    FILVRM = $0056;
    NRDVRM = $0174;
    NWRVRM = $0177;
    NSETRD = $016E;
    NSTWRT = $0171;
    BIGFIL = $016B;
    LDIRMV = $0059;
    LDIRVM = $005C;
    INITXT = $006C;
    SETTXT = $0078;
    ExpTbl = $Fcc1;

    _CALROM: array[0..6] of byte = ($FD,$21,$00,$00,$C3,$D4,$20);

type
    TString = string[40];

var
    i, j, k, l: integer;
    Number: string[5];
    temp: TString;
    Buffer: array [1..2048] of byte;
    ch: char;
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
    CallBas(32, BlockSize, addr(Buffer), FirstLineAddr, BIGFIL);    
    CallBas(0,  BlockSize, LastLineAddr, addr(Buffer),  LDIRVM);
end; 

procedure InfoAboutVDP;
begin
    writeln('Text width: ', LINL40);
    writeln('Pattern name table address: ', TXTNAM);
    writeln('PAttern generator table address: ', TXTCGP);
end;

procedure SetExtendedScreen;
begin
    OriginalRegister9Value := getVDP(9);
    SetVDP(9, OriginalRegister9Value + 128);
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
        writeln(temp);
    end;
    writeln('Printed lines on the screen, from 1 to ', HowManyLines,'.');
end;


BEGIN
    CallBas(0, 0, 0, 0, INITXT);
    randomize;

    InfoAboutVDP;
    readln;
    SetExtendedScreen;

{
* Fill the first 4096 bytes with spaces.
}
    
    CallBas(32, $1000, 0, 0, FILVRM);
    
{
* Print 7 lines with rubbish, starting at the line 10.
}
    clrscr;
    Example (10, 7);

    writeln('Scroll up: from line 10 to 1.');
    read(kbd, ch);
    ScrollText(10, 1);
    read(kbd, ch);

{
* Print 20 lines with rubbish, starting at the line 1.
}

    clrscr;
    Example (1, 20);

    writeln('Scroll down: From line 1 to 10.');
    read(kbd, ch);
    ScrollText(1, 10);
    read(kbd, ch);

{
* We'll use the VRAM as a memory buffer. 
* Start at $2000 (8192), end at $4000 (16384). 
* Buffer will receive 2048 characters, from A to the last one.
* In the 1600th position, we'll get a message. 
* The CallBas procedure will be used to copy from Buffer array variable 
* to the VRAM, in the position designed by the i variable.
* We'll get $0800 increments.
}
    clrscr;
    l := 1;
    i := $2000;
    while i < $5000 do
    begin
        fillchar(Buffer, sizeof(Buffer), ord(l + 64));
        writeln('VRAM Page ',l , ' filled. Position ', i, ' Character: ', chr(Buffer[j]));
        str(l, Number);
        temp := concat (' Page ', Number);
        for j := 1 to length(temp) do
            Buffer[1600 + j] := ord(temp[j]);
        CallBas(0, $0800, i, addr(Buffer), LDIRVM);
        i := i + $1000;
        l := l + 1;
    end;
    read(kbd, ch);

{
* Here goes the VRAM pages routine.
* Start at $2000 (8192), end at $4000 (16384). 
* The CallBas procedure will be used to change to text-mode 1.
* TXTNAM receives the address.
* We'll get $1000 increments.
}

    i := $2000;
    while i < $5000 do
    begin
        TXTNAM := i;
        CallBas (0, 0, 0, 0, SETTXT);
        gotoxy (1, 20); writeln('Position ',i, ' selected.');
        read(kbd, ch);
        i := i + $1000;
    end;

    SetOriginalScreen;

END.
