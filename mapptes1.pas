{
   mapptest.pas
   
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


program mapptest;

{$i d:msxdos2.inc}
{$i d:mapper.inc}

const
    UserPage = 0;
    
var i : integer;
    j : integer;
    teste: string[80] absolute $C000;
    Allright: boolean;

BEGIN
	writeln('Mapper Support: ', MapperSupport(MapperCount));
	writeln('How many Memory Mappers does this MSX have: ', MapperCount);
    writeln('Memory Mapper slotid: ', MapperTablePtr^.SlotId);
    writeln('Total Memory Mapper pages: ', MapperTablePtr^.PagesTotal, ' (', MapperTablePtr^.PagesTotal * 16, ' Kb).');
    writeln('Free Memory Mapper pages: ', MapperTablePtr^.PagesFree, ' (', MapperTablePtr^.PagesFree * 16, ' Kb).');
writeln('Memory Mapper pages used by DOS 2: ', MapperTablePtr^.PagesSystem, ' (', MapperTablePtr^.PagesSystem * 16, ' Kb).');
    writeln('Memory Mapper pages used by users: ', MapperTablePtr^.PagesUser, ' (', MapperTablePtr^.PagesUser * 16, ' Kb).');
    readln;

    teste := 'Testando 1 2 3';
    writeln('Texto: ', teste);
    i := (4 * 256) + MapperTablePtr^.SlotId;

    writeln('Allocate Mapper Page: ', AllocateMapperPage(PrimaryMapper, UserPage, i));
    writeln('i: ',i, ' Slot id: ', Lo(i), ' Pagina: ', Hi(i));
    writeln('Address teste: ', addr(teste));
    writeln('sizeof teste: ', sizeof(teste));
    WriteMapperPage(i, addr(teste), $C000, sizeof(teste));
    writeln('i: ',i, ' Slot id: ', Lo(i), ' Pagina: ', Hi(i));
    writeln('Free Mapper Page: ', FreeMapperPage(i));
    
    teste := '';
    writeln('Texto: ', teste);

    i := (4 * 256) + MapperTablePtr^.SlotId;
    writeln('Allocate Mapper Page: ', AllocateMapperPage(PrimaryMapper, UserPage, i));
    writeln('i: ',i, ' Slot id: ', Lo(i), ' Pagina: ', Hi(i));
    writeln('Address teste: ', addr(teste));
    writeln('sizeof teste: ', sizeof(teste));
    ReadMapperPage(i, $C000, addr(teste), sizeof(teste));
    writeln('i: ',i, ' Slot id: ', Lo(i), ' Pagina: ', Hi(i));
    writeln('Free Mapper Page: ', FreeMapperPage(i));

    writeln('Texto: ', teste);
   

{   if AllocateMapperPage(PrimaryMapper, UserPage, i) then
        WriteMapperPage(i, addr(teste), addr(teste), sizeof(teste));
    writeln('i: ',i, ' Slot id: ', Lo(i), ' Pagina: ', Hi(i));
    AllRight := FreeMapperPage(i);
    readln;

    teste := 'Testando 4 5 6';
    writeln(teste);
    writeln('Trocando de pagina...');
    i := (5 * 256) + MapperTablePtr^.SlotId;
    if AllocateMapperPage(PrimaryMapper, UserPage, i) then
        WriteMapperPage(i, addr(teste), addr(teste), sizeof(teste));
    writeln('i: ',i, ' Slot id: ', Lo(i), ' Pagina: ', Hi(i));
    AllRight := FreeMapperPage(i);
    readln;


    i := (4 * 256) + MapperTablePtr^.SlotId;
    writeln('Lendo da pagina ', i);
    if AllocateMapperPage(PrimaryMapper, UserPage, i) then
        ReadMapperPage(i, addr(teste), addr(teste), sizeof(teste));
    writeln('Resultado da pagina ', Hi(i), ': ', teste);
    AllRight := FreeMapperPage(i);
    readln;

    i := (5 * 256) + MapperTablePtr^.SlotId;
    writeln('Lendo da pagina ', i);
    if AllocateMapperPage(PrimaryMapper, UserPage, i) then
        ReadMapperPage(i, addr(teste), addr(teste), sizeof(teste));
    writeln('Resultado da pagina ', Hi(i), ': ', teste);
    AllRight := FreeMapperPage(i);
    readln;    
}

END.

