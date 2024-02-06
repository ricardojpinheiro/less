(* less.pas - This wannabe GNU less-like text pager is based on milli, my
 * text editor (https://ricardojpinheiro.github.io/nanomsx/). 
 * Our main approach is to have all useful less funcionalities. 
 * MSX version by Ricardo Jurczyk Pinheiro - 2022-2024.  *)

program less;

{$i d:defs.inc}
{$i d:conio.inc}
{$i d:dos.inc}
(* {$i d:dos2err.inc} *)
{$i d:readvram.inc}
{$i d:fillvram.inc}
{$i d:fastwrit.inc}
{$i d:txtwin.inc}
{$i d:blink.inc}
{$i d:less1.inc}
{$i d:less2.inc}

{$u-}

procedure InitMainScreen;
begin
    EditWindowPtr := MakeWindow(0, 1, maxwidth + 2, maxlength + 1, '');

	fillvram(0, startvram   , 0, $FFFF - startvram);

	ClrWindow (EditWindowPtr);

	FillChar(temp, SizeOf(temp), chr(32));
    GotoXY(((maxwidth - length(filename)) div 2), 1);
    temp := concat('[', filename, ']');
    
    FastWrite(temp);
end;

procedure ReadFile;
var
    VRAMAddress, l:        		integer;
	lengthline, lineparts:		byte;

begin
	counter := startvram;

	fillvram(0, startvram, 0, $FFFF);

	temp	:= concat ('Reading file ', filename);
	StatusLine(temp);
    
    assign(textfile, filename);
    {$i-}
    reset(textfile);
    {$i+}
	currentline := 1;
	
	while not eof(textfile) and (currentline <= maxlines) do
	begin
		FillChar(line, sizeof(line), chr(32));
		readln(textfile, line);
		lengthline := length(line);

		if currentline = 783 then
			fillvram(1, 0, 0, $FFFF);

(*	If length of the read line is greater than the maxwidth,
	you must break it into several lines, and save them into
	VRAM, as individual lines. *)		

		if lengthline > maxwidth then
		begin
			l := 1;
			lineparts := (lengthline div maxwidth) + 1;
			for i := 1 to lineparts do
			begin
				FillChar(Line1, sizeof(Line1), chr(32));
				Line1 := copy (line, l, l + (maxwidth - 1));
				l := l + (maxwidth - 1);
				
				InitVRAM(currentline, counter);
				counter := counter + maxwidth;

				FromRAMToVRAM(Line1, currentline);
				currentline := currentline + 1;
			end;
		end

(*	If length of the read line is less than the maxwidth,
	save it to VRAM. *)

		else
		begin
			InitVRAM(currentline, counter);
			counter := counter + maxwidth;

			FromRAMToVRAM(line, currentline);
			currentline := currentline + 1;
		end;
	end;

    close(textfile);

    highestline :=  currentline - 1;	insertmode  := true;
    currentline := 1;	column := 1;	screenline  := 1;
   
    DrawScreen(currentline, screenline, 1);

    ClearStatusLine;
    Blink(2, screenline + 1, maxwidth);
end;

procedure ExitToDOS;
begin
    GotoXY(1, maxlength + 1);
    ClrEol;
    Blink(1, maxlength + 1, maxwidth + 2);
    temp := 'Are you sure? (Y/N)';
    FastWrite(temp);
    
    c := chr(32);
    
    while ((c <> 'N') and (c <> 'Y')) do
        c := upcase(readkey);
    
    ClearStatusLine;

    EraseWindow(EditWindowPtr);

(*  Restore function keys. *)
    if (MSXDOSversion.nKernelMajor >= 2) then
        CheatAPPEND(chr(32));

    if msx_version = 4 then
        TRZ80mode;

	ClearAllBlinks;
	with ScreenStatus do
		Color(nFgColor, nBkColor, nBdrColor);
    ClrScr;
    Halt;
end;

procedure InitTextEditor;
begin
    if ScreenStatus.bFnKeyOn then
        SetFnKeyStatus (false);
    
    ScreenWidth(80);
    ClearAllBlinks;
    
(*	Opção de alterar a cor da tela deve ser colocada. *)    
    
    SetBlinkColors(NewScreenStatus.nBkColor, NewScreenStatus.nFgColor);
    SetBlinkRate(5, 0);

(*  Some variables. *)   
    currentline := 1;		screenline 	:= 1;       highestline := 1;
    column      := 1; 		insertmode  := false;   savedfile   := false;   
    FillChar(temp,          sizeof(temp),           chr(32));
    FillChar(searchstring,  sizeof(searchstring),   chr(32));
end;

procedure handlefunc(keynum: byte);
var
    key         : byte;
    iscommand   : boolean;
    
begin
    case keynum of
		69:			CursorDown; 							(* E *)
		74:			CursorDown;								(* J *)
		CONTROLE:	CursorDown;
		CONTROLJ:	CursorDown;
		ENTER:		CursorDown;
		DownArrow:  CursorDown;
		68:			CursorUp;								(* D *)
		89:			CursorUp;								(* Y *)
		CONTROLD:	CursorUp;
		CONTROLY:	CursorUp;
		CONTROLP:	CursorUp;
		UpArrow:    CursorUp;
		70:   		PageDown;								(* F *)
		CONTROLF:   PageDown;
		CONTROLV:   PageDown;
		SPACE:   	PageDown;
		66:   		PageUp;									(* B *)
		CONTROLB:   PageUp;
		INSERT:     BeginFile;
		71:     	BeginFile;								(* G *)
		DELETE:     EndFile;
		73:     	EndFile;								(* I *)
		47:   		WhereIs (forwardsearch,  false); 		(* / *)
		63:   		WhereIs (backwardsearch, false);		(* ? *)
		78:   		WhereIs (forwardsearch,  true); 		(* N *)
		77:   		WhereIs (backwardsearch, true);			(* M *)
		80:			DrawScreen(currentline, screenline, 1);	(* P *)
		72:   		Help;									(* H *)
		81:   		ExitToDOS;								(* Q *)
		86:   		Version;								(* V *)
		SELECT:     begin
						key := ord(readkey);
						case key of
							UpArrow:  		PageUp;
							DownArrow:  	PageDown;
							INSERT:			BeginFile;
							DELETE:			EndFile;
							else    delay(10);
						end;
                    end;
        else    delay(10);
	end;
end;

function FileExistsOrNot (filename: TString): boolean;
begin
	assign(textfile, filename);
    {$i-}
    reset(textfile);
    {$i+}

    if (ioresult <> 0) then
		FileExistsOrNot := false
	else
		FileExistsOrNot := true;
end;

(* main *)

begin
    newline     := 1;
    newcolumn   := 1;
    tabnumber   := 8;
	AllChars    := [0..255];
    NoPrint     := [0..31, 127, 255];
    Print       := AllChars - NoPrint;

    GetMSXDOSVersion (MSXDOSversion);
	GetScreenStatus (ScreenStatus);
	NewScreenStatus := ScreenStatus;

    if paramcount = 0 then
    exit
	else
		begin
(*  Read parameters, and upcase them. *)
			for i := 1 to paramcount do
			begin
				temp := paramstr(i);
				for j := 1 to length(temp) do
					temp[j] := upcase(temp[j]);

				c := temp[2];
				if temp[1] = '/' then
				begin
					delete(temp, 1, 2);
(*  Parameters. *)
					case c of
						'V': CommandLine(1);
						'H': CommandLine(2);
						'D': begin	{ Define cores }
								with NewScreenStatus do
								begin
									val(copy(temp, 1, (pos(chr(44), temp)) - 1), 
										aux, rtcode);
									nFgColor := aux;
									val(copy(temp, pos(chr(44), temp) + 1, 
										length(temp)), aux, rtcode);
									nBkColor := aux;
									Color(nFgColor, nBkColor, nBkColor);
								end;  
							end;
						'M': delay(10); { Muda o prompt } 
						'N': delay(10); { Numera as linhas } 
					end;
				end;
			end;

(* The first parameter should be the file. *)
        filename    := paramstr(1);

		if not FileExistsOrNot (filename) then
		begin
			writeln('Missing filename. (less /h for help)');
			halt;
		end;

(*  If it's a MSX 1, exits. If it's a Turbo-R, turns on R800 mode.*)

		case msx_version of
			1:  begin
					writeln('MSX 1 detected. This program needs at least a MSX 2.');
					halt;
				end;
			2:  writeln('MSX 2 detected.');
			3:  writeln('MSX 2+ detected.');
			4:  begin
					writeln('MSX Turbo-R detected.');
					TRR800mode;
				end;
		end;
        
(* Cheats the APPEND environment variable. *)    

        if (MSXDOSversion.nKernelMajor >= 2) then
            CheatAPPEND(filename);

(*  Init text editor routines and variables. *)    
		InitTextEditor;
        InitMainScreen;

        currentline := 1;
        highestline := 1;

(* Reads file from the disk. *)
        ReadFile;
    end;

(* main loop - get a key and process it *)
    repeat
		handlefunc(ord(upcase(readkey)));
    until true = false;
end.
