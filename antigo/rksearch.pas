program DemoRKSearch;


              (* Rabin-Karp search demo program.             *)

const
    Limit = 235;
    b = 251;

type
    TString = string[127];
    arby64K = string[255];

var
    Index   : integer;
    stTemp  : string[20];
    Buffer  : arby64K;
    Position: Integer;
    i : byte;

(* Rabin-Karp algorithm, which is used for searching a pattern into the string. *)

function RabinKarp (Pattern: TString; Text: arby64K): integer;
var
    HashPattern, HashText, Bm, j, LengthPattern, LengthText, Result: integer;
    Found : Boolean;
  
begin

(*  Initializing variables. *)

    Found := False;
    Result := 0;
    LengthPattern := length(Pattern);
    HashPattern := 0;
    HashText := 0;
    Bm := 1;
    LengthText := length(Text);

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

BEGIN
  Randomize;
  stTemp := 'AbCdEfGhIj';
  for i := 1 to 10 do
  begin
    Position := round(int(random(Limit)));
    writeln('Randomizing position: ', Position);
    fillchar(Buffer, sizeof(Buffer), chr(round(int(random(Limit)))));
    writeln('Fill Buffer with random data.');
    insert(stTemp, Buffer, Position);
    Index := RabinKarp(stTemp, Buffer);
    writeln(stTemp, ' found at offset ', Index);
  end;
END.
