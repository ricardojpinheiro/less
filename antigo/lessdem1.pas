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
{$i d:maprrw.inc}
{$i d:maprallc.inc}
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
    BlockReadResult, Position: byte;
    NewPosition: integer;
    TextFileName: TFileName;
    ScreenBuffer: array[0..SizeScreen] of char;
    EndOfPage: array[0..PagesPerSegment] of integer absolute $BFD0; { Page 2 }
    PageRemnant: integer;
    OriginalRegister9Value: byte;
    ch, sch: char;

    TempString: TString;
    TempTinyString: string[5];
    MaxTotalPagesPerSegment, LastSegment, Segment, TotalPages: integer;
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

function PreProcessing (Segment: Byte): byte;
var 
    EndOfPageIndex, BufferIndex, ScreenBufferIndex, temporary: integer;
    NextSegment: boolean;
begin
    
{ A função dessa rotina de pre-processamento é localizar onde começa e onde
  termina cada página, dentro do segmento de memoria acessado. A ideia é
  salvar no vetor EndOfPage (q está travado na posição $BFD0 (página 2),
  então em cada segmento da Mapper, teremos o bloco de texto + o vetor
  EndOfPage daquele bloco, pra n ter q refazer o pré-processamento de tudo.
  O problema é o texto "quebrado", em que parte começa em uma página e termina
  em outra. Aí o vetor EndOfPage tem que ter a informação da página seguinte 
  também.
  }

{ Inicializa variáveis e seta o segmento da Mapper na página 2 }

    EndOfPage[0]    := 0;
    EndOfPageIndex  := 0;
    BufferIndex     := 0;
    NextSegment     := false;
{    
    writeln('EndOfPage[',EndOfPageIndex,']=',EndOfPage[EndOfPageIndex]);
}
{ Repete até que o EndofPage[EndOfPageIndex - 1] seja maior do que o EndOfPage[EndOfPageIndex] }

    repeat
        EndOfPageIndex := EndOfPageIndex + 1;
        ScreenBufferIndex := 0;
        temporary := EndOfPage[EndOfPageIndex - 1];

        while (ScreenBufferIndex < SizeTextScreen) do
        begin
            if BufferIndex >= Limit then
            begin

{ Se o i for maior do que Limit, significa que o texto está quebrado.
  Logo, é preciso pegar o resto na página seguinte. A flag NextSegment
  marca a necessidade de pegar o dado no segmento seguinte. } 

                BufferIndex := 0;
                NextSegment := true;
            end;
            
            case Buffer[BufferIndex] of
                9:              ScreenBufferIndex := ScreenBufferIndex + 8;
                13:             ScreenBufferIndex := (((ScreenBufferIndex div 80) + 1) * 80) - 2;
                else            ScreenBufferIndex := ScreenBufferIndex + 1;
            end;
            BufferIndex := BufferIndex + 1;
        end;
        EndOfPage[EndOfPageIndex] := BufferIndex - 1;
{
       writeln('EndOfPage[',EndOfPageIndex - 1,']=',temporary, ' EndOfPage[',EndOfPageIndex,']=',EndOfPage[EndOfPageIndex]);
}
    until (EndOfPage[EndOfPageIndex] < temporary);
    
    EndOfPage[EndOfPageIndex] := Limit;
{
     if NextSegment then
        PageRemnant := EndOfPage[EndOfPageIndex];
}
    PreProcessing := EndOfPageIndex;
end;

procedure FromRAMToVRAM (Segment: integer; Page, MaxTotalPagesPerSegment: byte);
var 
    i, j, temporary: integer;
    
begin
    
{ Aqui, joga da RAM pra VRAM. }

    i := EndOfPage[Page - 1];

    if Page > 1 then
        i := i - 2;
    k := 0;

    fillchar(ScreenBuffer, sizeof(ScreenBuffer), ' ');
    temporary := EndOfPage[Page];
    if Page = MaxTotalPagesPerSegment - 1 then
        temporary := Limit;

    while (k < SizeTextScreen) and (i < temporary) do
    begin
        if i >= Limit then
        begin
            i := 0;
            temporary := EndOfPage[Page + 1];
        end;
        if Buffer[i] in Print then
            ScreenBuffer[k] := chr(Buffer[i])
        else
            case Buffer[i] of
                9:              k := k + 8;
                13:             k := (((k div 80) + 1) * 80) - 2;
                10, 127, 255:   k := k + 0;
            end;
        i := i + 1;
        k := k + 1;
    end;
    WriteVRAM (0, $0000, addr(ScreenBuffer), $0730);
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

    PageRemnant := 0;
    i := FirstSegment;
    MaxBlock := round(int(MaxSize / Limit)) + 1;
    writeln ('MaxBlock: ', MaxBlock);

    EnablePlainMem (PlainMemory, Mapper, 48);
    
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
END.
