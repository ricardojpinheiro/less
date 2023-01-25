{
   lessdemo.pas
}

program lessdemo;

{$i d:types.inc}
{$i d:dos.inc}
{$i d:dos2err.inc}
{$i d:dos2file.inc}
{$i d:fastwrit.inc}
{$i d:msxbios.inc}
{$i d:extbio.inc}
{$i d:maprbase.inc}
{$i d:maprvars.inc}
{$i d:maprpage.inc}
{$i d:blink.inc}

const
    Limit = 15360;
    LinesPerSegment = 204;
    ReadLinesPerSegment = 192;
    PagesPerSegment = 8;
    FirstSegment = 4;
    SizeScreen = 1840;
    WidthScreen = 80;
    
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
    
    CONTROLB    = #02;
    CONTROLE    = #05;
    CONTROLF    = #06;
    CONTROLK    = #11;
    CONTROLN    = #14;
    CONTROLP    = #16;
    CONTROLV    = #22;
    CONTROLY    = #25;
    BS          = #08;
    TAB         = #09;
    HOME        = #11;
    CLS         = #12;
    ENTER       = #13;
    INSERT      = #18;
    SELECT      = #24;
    ESC         = #27;
    RightArrow  = #28;
    LeftArrow   = #29;
    UpArrow     = #30;
    DownArrow   = #31;
    Space       = #32;
    DELETE      = #127;
    
    _CALROM: array[0..6] of byte = ($FD,$21,$00,$00,$C3,$D4,$20);
    _CALSUB: array[0..6] of byte = ($FD,$21,$00,$00,$C3,$D4,$20);   

type
    ASCII = set of 0..255;

var i, j, k, l, m, n, Page, TotalPages: integer;
    Line, PagesPerDocument, Segment, TotalSegments: integer;
    MaxSize: real;
    buffer : Array[1..LinesPerSegment,1..WidthScreen] of char absolute $8000; { Page 2 }
    BFileHandle: text;
    B2FileHandle: file;
    NoPrint, Print, AllChars: ASCII;
    
    Mapper: TMapperHandle;
    PointerMapperVarTable: PMapperVarTable;
    NextPage, Finished, NextSegment: boolean;
    TempString: TString;
    TempTinyString: string[8];
    TextFileName: TFileName;
    OriginalRegister9Value: byte;
    ch: char;

    VDPSAV1: array[0..7]  of byte absolute $F3DF;
    VDPSAV2: array[8..23] of byte absolute $FFE7;
    TXTNAM : integer absolute $F3B3;

procedure ErrorCode (ExitOrNot: boolean);
var
    ErrorCodeNumber: byte;
    ErrorMessage: TMSXDOSString;
    
begin
    ErrorCodeNumber := GetLastErrorCode;
    GetErrorMessage (ErrorCodeNumber, ErrorMessage);
    WriteLn (ErrorMessage);
    if ExitOrNot = true then
        Exit;
end;

Procedure FillVRAM (VRAMaddress: Integer; NumberOfBytes: Integer;Value: Byte);
begin
    inline ($DD/$21/$6B/$01/
            $ED/$4B/NumberOfBytes/$2A/VRAMaddress/$3A/Value/$C3/_CALROM);
end;

Procedure CallBas(AC: byte; BC, DE, HL, IX: integer);
begin
    inline($F3/$CD/*+19/$FB/$32/AC/$22/HL/$43ED/BC/$53ED/DE/$1B18/
            $2ADD/IX/$3A/AC/$2A/HL/$4BED/BC/$5BED/DE/$08/$DB/$A8/$F5/
            $F0E6/$C3/$F38C);
END;

function GetVDP (register: byte): byte;
begin
    if register < 8 then
        GetVDP:=VDPSAV1[register]
    else
        GetVDP:=VDPSAV2[register];
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

Procedure ClrScr2;
Const
        ctCLS     = $00C3;  { Clear screen, including graphic modes }
Var
        regs   : TRegs;
        CSRY   : Byte Absolute $F3DC; { Current row-position of the cursor    }
        CSRX   : Byte Absolute $F3DD; { Current column-position of the cursor }
        EXPTBL : Byte Absolute $FCC1; { Slot 0 }

Begin
  regs.IX := ctCLS;
  regs.IY := EXPTBL;
  (*
   * The Z80 zero flag must be set before calling the CLS BIOS function.
   * Check the MSX BIOS specification
   *)
  Inline( $AF );            { XOR A    }

  CALSLT( regs );
  CSRX := 1;
  CSRY := 1;
End;

Procedure GotoXY2( nPosX, nPosY : Byte );
Var
       CSRY : Byte Absolute $F3DC; { Current row-position of the cursor    }
       CSRX : Byte Absolute $F3DD; { Current column-position of the cursor }
Begin
  CSRX := nPosX;
  CSRY := nPosY;
End;

function Readkey : char;
var
    bt: integer;
    qqc: byte absolute $FCA9;
begin
     readkey := chr(0);
     qqc := 1;
     Inline($f3/$fd/$2a/$c0/$fc/$DD/$21/$9F/00     
            /$CD/$1c/00/$32/bt/$fb);
     readkey := chr(bt);
     qqc := 0;
end;

procedure ReadPartOfFileIntoMapper (Segment: byte);
const
    TABChar = #9;
var
    i, j, k, l, m: byte;
    LengthString, InitialPosition, FinalPosition: byte;
    TempString: TString;
    TempTinyString: String[8];

begin
    i := 0;
{    
    gotoxy(20, 5); writeln('Segment: ', Segment, ' FirstSegment + TotalSegments: ', FirstSegment + TotalSegments);
}    
    fillchar(Buffer, sizeof (Buffer), ' ' );
    TempTinyString := '        ';
    PutMapperPage(Mapper, Segment, 2);
    
    while i < ReadLinesPerSegment do
    begin
        fillchar(TempString, sizeof(TempString), ' ' );
        readln(BFileHandle, TempString);

{   Test if there is any TAB. Should be able to identify all of them. }

        repeat
            j := Pos (TABChar, TempString);
            if j <> 0 then 
            begin
                delete (TempString, j, 1);
                insert(TempTinyString, TempString, j);
            end;
        until j = 0;
        
        j := length(TempString);
        InitialPosition := 1;
        
{   Test if the line has more than 80 characters. If yes, it'ld stop in the first
*   80 and goes on. }        
        
        if j >= WidthScreen then
            FinalPosition := WidthScreen
        else
            FinalPosition := j;
       
        LengthString := (length(TempString) div WidthScreen) + 1;
        
        for k := 1 to LengthString do
        begin
            l := 1;
            for m := InitialPosition to FinalPosition do
            begin
                buffer[i, l] := TempString[m];
                l := l + 1;
            end;

            for m := l to WidthScreen do
                Buffer[i, m] := chr(32);

            InitialPosition := FinalPosition + 1;
            FinalPosition := FinalPosition * (LengthString + 1);
            if FinalPosition > j then
                FinalPosition := j;
            i := i + 1;
        end;
    end;
end;

procedure ShowPage (Page: Byte);
begin
    clrscr2;
    WriteVRAM (0, $0000, addr(buffer[23 * (Page - 1)]), $0730);
end;

procedure UpdateLastLine (Page: Byte; TextFileName: TFileName; PagesPerDocument, TotalPages, Line: integer);
var
    StringArray: array [1..3] of String[4];
begin
    for i := 1 to 3 do
        fillchar(StringArray[i], sizeof(StringArray[i]), ' ' );
    str(Page, StringArray[1]);
    str(TotalPages, StringArray[2]);
    str(Line, StringArray[3]);
    TempString := concat('File: ', TextFileName, '  Page ', StringArray[1], ' of ',
                        StringArray[2], ' Line ', StringArray[3]);
    gotoxy2(1, 24);
    fastwriteln(TempString);
    blink (1, 24, 80);
end;

BEGIN
    clrscr;
    AllChars := [0..255];
    NoPrint := [0..31, 127, 255];
    Print := AllChars - NoPrint;
    
    writeln('Init Mapper? ', InitMapper(Mapper));
    PointerMapperVarTable := GetMapperVarTable(Mapper);
    writeln('Number of free segments: ', PointerMapperVarTable^.nFreeSegs);
    writeln('Reading services file...');
    TextFileName := 'd:\services';
    
{ Clear the blink table, set colors (to do later) and set a non flashable blink rate. }

    ClearAllBlinks;
    SetBlinkColors(DBlue, White);
    SetBlinkRate(1, 0);

{ Le arquivo 1a vez - pega o tamanho de tudo. }

    assign(B2FileHandle, TextFileName);
    reset(B2FileHandle);
    MaxSize := (FileSize(B2FileHandle) * 128);
    TotalPages := round(int(MaxSize / (SizeScreen + 1))) + 1;
    TotalSegments := round(int(TotalPages / PagesPerSegment));
    writeln('MaxSize = ', MaxSize:0:0, ' bytes.');
    writeln('TotalPages = ', TotalPages);
    writeln('TotalSegments = ', TotalSegments);
    close(B2FileHandle);

{ Le arquivo 2a vez - le e joga na Mapper. }

    assign(BFileHandle, TextFileName);
    reset(BFileHandle);

{ Comeca com o segmento 4 da memoria. }

    Segment := FirstSegment;
    PagesPerDocument := TotalPages * PagesPerSegment;
    Page := 1;
    Line := 1;

    while not eof(BFileHandle) do
    begin
        ReadPartOfFileIntoMapper (Segment);

{ Here is where the program shows the page. 
* If the user hits ESC, the program is finished. }

        ch := #00;
        NextSegment := false;

        while not NextSegment do
        begin
            NextPage := false;
            ShowPage (Page);
            UpdateLastLine (Page, TextFileName, PagesPerDocument, TotalPages, Line);
            
    { Here the program calls the procedure which places info in the last line of the page. }        

    {        
            blink (1, Line, 80);
            UpdateLastLine (Page, TextFileName, PagesPerDocument, TotalPages, Line);
    }
            while not NextPage do
            begin
                ch := readkey;
                ClearBlink(1, Line, 80);
                UpdateLastLine (Page, TextFileName, PagesPerDocument, TotalPages, Line);
                case ch of
                    ESC: begin
                            ClearAllBlinks;
                            SetOriginalScreen;
                            exit;
                        end;
                    Home:   Line := 1;
                    Select: Line := 23;
                    Insert:     begin
                                    Page := 1;
                                    NextPage := true;
                                end;
                    Delete:     begin
                                    Page := PagesPerSegment;
                                    NextPage := true;
                                end;
                    Space:      begin
                                    Page := Page + 1;
                                    NextPage := true;
                                end;
                    ControlB:   begin
                                    Page := Page - 1;
                                    NextPage := true;
                                end;
                    UpArrow:    begin
                                    Line := Line - 1;
                                    if Line < 1 then 
                                    begin
                                        Page := Page - 1;
                                        NextPage := true;
                                        Line := 1;
                                    end;
                                end;
                    DownArrow: begin
                                    Line := Line + 1;
                                    if Line > 23 then 
                                    begin
                                        Page := Page + 1;
                                        NextPage := true;
                                        Line := 1;
                                    end;
                                end;
                end;
                if Page < 1 then Page := 1;
                if Page > TotalPages then Page := TotalPages;
                if Page > PagesPerSegment then
                begin
                    Page := 1;
                    Segment := Segment + 1;
                    NextPage := true;
                    NextSegment := true;
                end;
                blink (1, Line, 80);
            end;
        end;
    end;
    PutMapperPage (Mapper, 2, 2);
    ClearAllBlinks;
END.
