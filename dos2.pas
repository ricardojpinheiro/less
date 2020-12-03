program dos2_info;

type txt=string[255];

const state:array[0..1] of txt=('aan','uit');

var tekst:txt;
    fout:byte;

{$i d:system.inc}

begin        { voor de eenvoud word er niet gecontroleerd op fouten ! }
  if dos_version>1
    then
      begin
        tekst:='';
        clrscr;
        writeln('***************** DOS 2 INFO ****************');
        gotoxy(1,4);
        writeln('Huidige drive:',current_drive,':');
        gotoxy(1,6);
        getdir(tekst,fout);
        writeln('Huidige directory:',tekst);
        gotoxy(1,8);
        writeln('Aantal disk buffers:',aantal_disk_buffers);
        gotoxy(1,10);
        writeln('Diskcheck status:',state[diskcheck_status div 255]);
        gotoxy(1,12);
        writeln('Verify status:',state[verify_status div 255]);
        gotoxy(1,14);
        writeln('Een aantal environment items:');
        writeln('=============================');
        get_environment_item('DATE',tekst,fout);
        gotoxy(1,16);
        writeln('DATE=',tekst);
        get_environment_item('HELP',tekst,fout);
        writeln('HELP=',tekst);
        get_environment_item('TEMP',tekst,fout);
        writeln('TEMP=',tekst);
        get_environment_item('UPPER',tekst,fout);
        writeln('UPPER=',tekst)
      end
    else
      begin
        clrscr;
        writeln('Geen MSX DOS 2 aanwezig !!')
      end;
end.

