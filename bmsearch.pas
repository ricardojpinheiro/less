program DemoBMSearch;


              (* Boyer-Moore index-table data definition.             *)

const
    Limit = 255;

type
    BMTable  = array[0..255] of byte;
    TString = string[127];

var
    Position: Integer;

(* Create a Boyer-Moore index-table to search with.             *)

procedure CreateBMTable(var BMT: BMTable; Pattern : TString; ExactCase : boolean);
var
    Index : byte;
begin
    fillchar(BMT, sizeof(BMT), length(Pattern));
    if NOT ExactCase then
        for Index := 1 to length(Pattern) do
            Pattern[Index] := upcase(Pattern[Index]);
        for Index := 1 to length(Pattern) do
            BMT[ord(Pattern[Index])] := (length(Pattern) - Index)
end;

(* Boyer-Moore Search function. *)

function BMsearch(var BMT: BMTable; var Buffer; BufferSize: integer; Pattern: TString; ExactCase: boolean): integer;
var
    Buffer2 : array[1..Limit] of char absolute Buffer;
    Index1, Index2, PatternSize : integer;
begin

(* BMSearch returns 0 if BufferSize exceeds Limit. Only a precaution. *)

    if (BufferSize > Limit)  then
        begin
            BMsearch := 0;
            exit;
        end;
        
    PatternSize := length(Pattern);
    
    if NOT ExactCase then
    begin
        for Index1 := 1 to BufferSize do
            if (Buffer2[Index1] > #96) and (Buffer2[Index1] < #123) then
                Buffer2[Index1] := chr(ord(Buffer2[Index1]) - 32);
        for Index1 := 1 to length(Pattern) do
            Pattern[Index1] := upcase(Pattern[Index1]);
    end;
    
    Index1 := PatternSize;
    Index2 := PatternSize;
    
    repeat
        if (Buffer2[Index1] = Pattern[Index2]) then
        begin
            Index1 := Index1 - 1;
            Index2 := Index2 - 1;
        end
        else
        begin
            if (succ(PatternSize - Index2) > (BMT[ord(Buffer2[Index1])])) then
                Index1 := Index1 + succ(PatternSize - Index2)
            else
                Index1 := Index1 + BMT[ord(Buffer2[Index1])];
            Index2 := PatternSize;
        end;
    until (Index2 < 1) or (Index1 > BufferSize);
    
    if (Index1 > BufferSize) then
      BMsearch := 0
    else
      BMsearch := succ(Index1)
end;

type
  arby_64K = array[1..Limit] of byte;

var
  Index   : integer;
  stTemp  : string[20];
  Buffer  : ^arby_64K;
  BMT     : BMTable;
  i       : byte;

BEGIN
    Randomize;
    stTemp := 'AbCdEfGhIj';
    for i := 1 to 10 do
    begin
        new(Buffer);
        Position := round(int(random(Limit)));
        writeln('Randomizing position: ', Position);
        fillchar(Buffer^, sizeof(Buffer^), round(int(random(Limit))));
        move(stTemp[1], Buffer^[Position], length(stTemp));
        Create_BMTable(BMT, stTemp, false);
        Index := BMSearch(BMT, Buffer^, sizeof(Buffer^), stTemp, false);
        writeln(stTemp, ' found at offset ', Index)
    end;
END.
