{
   less.pas
}

program less;

{$i d:types.inc}
{$i d:msxbios.inc}
{$i d:extbio.inc}
{$i d:maprbase.inc}
{$i d:maprvars.inc}
{$i d:maprrw.inc}
{$i d:maprallc.inc}
{$i d:maprpage.inc}
{$i d:dos.inc}
{$i d:dos2err.inc}
{$i d:dos2file.inc}
{$i d:fastwrit.inc}
{$i d:blink.inc}
{$i d:divs.inc}
{$i d:plainmem.inc}

const
    Limit = 16336;
    SizeScreen = 1919;
    SizeTextScreen = 1840;
    PagesPerSegment = 16;
    
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

var i, j, k, l, Page, MaxBlock: integer;
    MaxSize: real;
    Buffer: aBuffer absolute $8000; { Page 2 }
    BFileHandle: byte;
    B2FileHandle: file;
    NoPrint, Print, AllChars: ASCII;
    PlainMemory: TPlainMem;
    
    Mapper: TMapperHandle;
    PointerMapperVarTable: PMapperVarTable;
    NextPage, SeekResult, CloseResult: boolean;
    BlockReadResult: byte;
    NewPosition: integer;
    TextFileName: TFileName;
    ch, sch: char;

    TempString: TString;
    TempTinyString: string[5];
    MaxTotalPagesPerSegment, LastSegment, Segment, TotalPages: integer;

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

procedure SetLastLine (TextFileName: TFileName; PagePerDocument, TotalPages, Line: integer);
begin

{ Faz todo o trabalho para colocar informacao na ultima linha. }
            
    fillchar(TempString, sizeof(TempString), ' ');
    TempString := concat('File: ', TextFileName, '  Page ');
    fillchar(TempTinyString, sizeof(TempTinyString), ' ');
    str(PagePerDocument, TempTinyString);
    TempString := concat(TempString, TempTinyString);
    fillchar(TempTinyString, sizeof(TempTinyString), ' ');
    str(TotalPages, TempTinyString);
    TempString := concat(TempString, ' of ', TempTinyString, ' Line ');
    str(Line, TempTinyString);
    TempString := concat(TempString, TempTinyString, ' ');
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

{ Le arquivo 1a vez - pega o tamanho de tudo. }

    assign(B2FileHandle, TextFileName);
    reset(B2FileHandle);
    MaxSize := (FileSize(B2FileHandle) * 128);
    TotalPages := round(int(MaxSize / (SizeTextScreen + 1))) + 1;
    writeln('MaxSize = ', MaxSize:0:0, ' bytes.');
    writeln('TotalPages = ', TotalPages);
    close(B2FileHandle);

{ Le arquivo 2a vez - le e joga na Mapper. }

    BFileHandle := FileOpen (TextFileName, 'r');
    SeekResult := FileSeek (BFileHandle, 0, ctSeekSet, NewPosition);

    writeln('BFileHandle: ',BFileHandle, ' SeekResult: ',SeekResult);

{ Comeca com o segmento 4 da memoria. }

    i := FirstSegment;
    MaxBlock := round(int(MaxSize / Limit)) + 1;
    writeln ('MaxBlock: ', MaxBlock);

    EnablePlainMem (PlainMemory, Mapper, MaxBlock);
    
    writeln('Plain Memory enabled.');
    
    exit;

    while (i <= TotalPages) do
    begin
        gotoxy(20, 5); writeln('Block: ', i, ' MaxBlock + FirstSegment: ', MaxBlock + FirstSegment);
        fillchar(Buffer, sizeof (Buffer), 0 );
        BlockReadResult := FileBlockRead (BFileHandle, Buffer, 15872);
        WriteToPlainMemory (Mapper, PlainMemory, i, i + 15872, Buffer);
        i := i + 15872;
    end;

    CloseResult := FileClose(BFileHandle);

    exit;
(*
{ Aqui, ele mostra a pagina. Se teclar ESC, sai do programa. }

    ch := #00;
    j := FirstSegment;
    Segment := 4;
    Page := 1;
    l := 1;

{ Limpa os blinks }

    ClearAllBlinks;
    SetBlinkColors(DBlue, White);
    SetBlinkRate(1, 0);

    MaxTotalPagesPerSegment := PreProcessing (Segment);
    LastSegment := Segment;
    
    readln;
    
    while ch <> ESC do
    begin
        NextPage := false;
        FromRAMToVRAM (Segment, Page, MaxTotalPagesPerSegment);
        
{ Faz todo o trabalho para colocar informacao na ultima linha. }
        blink (1, l, 80);
{
         SetLastLine (TextFileName, Page, TotalPages, l);
}
        while not NextPage do
        begin
            ch := readkey;
            ClearBlink(1, l, 80);
            case ch of
                ESC: begin
                        ClearAllBlinks;
                        exit;
                    end;
                Home: l := 1;
                Select: l := 23;
                Insert: begin
                            Page := 1;
                            NextPage := true;
                        end;
                Delete: begin
                            Page := MaxTotalPagesPerSegment;
                            NextPage := true;
                        end;
                Space: begin
                            Page := Page + 1;
                            NextPage := true;
                        end;
                ControlB: begin
                                Page := Page - 1;
                                NextPage := true;
                            end;
                UpArrow: begin
                            l := l - 1;
                            if l < 1 then 
                            begin
                                Page := Page - 1;
                                NextPage := true;
                                l := 1;
                            end;
                        end;
                DownArrow: begin
                                l := l + 1;
                                if l > 23 then 
                                begin
                                    Page := Page + 1;
                                    NextPage := true;
                                    l := 1;
                                end;
                            end;
            end;
            if Page < 1 then Page := 1;
            if Page > TotalPages then Page := TotalPages;
            if Page >= MaxTotalPagesPerSegment then
            begin
                Page := 1;
                Segment := Segment + 1;
                MaxTotalPagesPerSegment := PreProcessing (Segment);
                NextPage := true;
                readln;
            end;
            blink (1, l, 80);
            blink (1, 24, 80);
            SetLastLine (TextFileName, Page, TotalPages, l);
        end;
    end;
    ClearAllBlinks;
*)

END.
