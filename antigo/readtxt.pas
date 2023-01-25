program crummy_search;

var
  fn : string;
  rd : string;
  srch: string;

function LastLine:string;
const
  BufferSize = 4194304; //4MB buffer; to big for most text lines
  lf = #10;
var
  MyFile   : File;
  MyBuffer :String;
  vCntr    :Integer;
begin
  Assign(MyFile, 'C:\MyTextResults.txt')
  Reset(MyFile, 1);
  Seek(MyFile,FileSize(MyFile) - BufferSize);
  SetLength(MyBuffer, BufferSize);
  BlockRead(MyFile, MyBuffer[1], BufferSize);
  Close(MyFile);
  for vCntr := BufferSize downto 1 do begin
    if MyBuffer[vCntr] = lf then begin
      result := Copy(MyBuffer, vcntr+1, BufferSize-vCntr);
      exit;
    end;
  end;
  Result:= '';// if the code reaches this point then no new line characters found.
end;


procedure upstring (var s : string);

var
  p : byte;

begin
  for p := 1 to length(s) do
    s[p] := upcase(s[p]);
end;

function searchfile (var name : string; find : string) : longint;

var
  fs : text;
  cmp : string;
  line : longint;

begin
  line := 0;
  searchfile := 0;
  upstring (find);
  assign (fs,name);
  reset (fs);
  while not eof(fs) do
    begin
      readln (fs,rd);
      inc (line);
      cmp := rd;
      upstring(cmp);
      if pos(find,cmp)>0 then
        begin
          searchfile := line;
          close (fs);
          exit;
        end;
    end;
  close (fs);
end;

var
  res : longint;

begin
  writeln ('file to search:');
  readln (fn);
  writeln ('what to search for:');
  readln (srch);
  res := searchfile (fn,srch);
  if res>0 then
    begin
      writeln ('Found in file ',fn,' in line #',res,':');
      writeln (rd);
    end
  else
    writeln ('String not found.');
end. 
