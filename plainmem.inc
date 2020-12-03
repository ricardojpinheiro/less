(*<plainmem.inc>
 * Memory mapper abstraction layer routines.
 * CopyLeft (c) since 2020 by Ricardo Jurczyk Pinheiro.
 *)

(**
  *
  * $Id: $
  * $Author: $
  * $Date: $
  * $Revision: $
  * $HeadURL: $
  *)

(*
 * This module depends on folowing include files (respect the order):
 * Yada-yada-yada
 *)

(*
{i d:types.inc}
{i d:msxbios.inc}
{i d:extbio.inc}
{i d:maprbase.inc}
{i d:maprvars.inc}
{i d:maprrw.inc}
{i d:maprallc.inc}
{i d:maprpage.inc}
{i diversos.inc} 
*) 

(*
* Constants
*)
const
    LastPositionAtSegment: Integer = 16384;
    LastPositionSegment = 16384;
    FirstSegment: Integer = 4;
    MaxSegments = 255;

(*
* Types and definitions
*)

type 
        PPlainMem   =   ^TPlainMem;
        TPlainMem   = record
            nTotalSegments      : Byte;   { Total number of segments available }
            nAvailableSegments  : Byte;   { How many segments are available    }
            nUsedSegments       : Byte;   { How many segments are used         }
            nAllocatedSegments  : Byte;   { How many segments are allocated    }
            aAllocatedSegments  : array [1..MaxSegments] of Byte;
    end;
    aBuffer =   array[1..LastPositionSegment] of byte;

(*
* Enable the plain memory abstraction layer.
*)
procedure EnablePlainMem (var PlainMemData : TPlainMem; Mapper: TMapperHandle; 
                            HowManySegments: byte);
var
    i: byte;
    AllRight: boolean;
begin
    i := 1;
    AllRight := true;
    with PlainMemData do
    begin
        nTotalSegments := Mapper.nTotalMapperSegs;
        nAvailableSegments := Mapper.nFreePriMapperSegs;
        nUsedSegments := 0;
        fillchar(aAllocatedSegments, sizeof(aAllocatedSegments), 0);
        while (AllRight) or (i < HowManySegments) do
        begin
            AllRight := AllocMapperSegment(Mapper, Mapper.nPriMapperSlot, UserSegment, aAllocatedSegments[i]);
            i := i + 1;
{
           writeln('Allocated Segment ', i - 1, ': ', aAllocatedSegments[i - 1]);
}            
        end;
        nAllocatedSegments := HowManySegments;
    end;
end;

(*
* Disable the plain memory abstraction layer.
*)
procedure DisablePlainMem (var PlainMemData : TPlainMem; 
                                Mapper: TMapperHandle);
var
    i: byte;
    AllRight: boolean;
begin
    i := 1;
    AllRight := true;
    with PlainMemData do
    begin
        while (AllRight) or (i < nAllocatedSegments) do
        begin
            AllRight := FreeMapperSegment(Mapper, Mapper.nPriMapperSlot, 
                                            aAllocatedSegments[i]);
            i := i + 1;
        end;
        nAvailableSegments := Mapper.nFreePriMapperSegs;
        nUsedSegments := 0;
        nAllocatedSegments := 0;
        fillchar(aAllocatedSegments, sizeof(aAllocatedSegments), 0);
    end;
end;

(*
*  Read a bunch of bytes from the memory mapper.
*)
procedure ReadFromPlainMemory (handle: TMapperHandle; PlainMemData : TPlainMem;
                        FirstPosition, LastPosition: real; var Buffer: aBuffer);
var
    FirstSegmentToBeUsed, LastSegmentToBeUsed: byte;
    FirstAddressInSegment, LastAddressInSegment: integer;
    Segments: byte;
    iBuffer: integer;
    DifferentSegments: boolean;
    i: byte;
    Addresses, temporary1, temporary2: integer;

begin
(*
*  First we need to define some limits, due to First and Last Positions.
*)
    FirstSegmentToBeUsed  := IntegerDivision(FirstPosition, LastPositionAtSegment) + 1;
    LastSegmentToBeUsed   := IntegerDivision(LastPosition , LastPositionAtSegment) + 1;
    
    FirstAddressInSegment := IntegerRemainder(FirstPosition, LastPositionAtSegment);
    LastAddressInSegment  := IntegerRemainder(LastPosition , LastPositionAtSegment);

    iBuffer := 1;
    DifferentSegments := false;
    temporary1 := 0;
    temporary2 := 9;
(*
*   Here is the routine that reads data from the Mapper. 
*)
    if FirstSegmentToBeUsed < LastSegmentToBeUsed then
        DifferentSegments := true;

    for Segments := FirstSegmentToBeUsed to LastSegmentToBeUsed do
    begin
        if DifferentSegments = false then
        begin
            temporary1 := FirstAddressInSegment;
            temporary2 := LastAddressInSegment;
        end
        else
            if Segments = FirstSegmentToBeUsed then
            begin
                temporary1 := FirstAddressInSegment;
                temporary2 := LastPositionAtSegment;
            end
            else
            begin
                temporary1 := 1;
                temporary2 := LastAddressInSegment;
            end;
        for Addresses := temporary1 to temporary2 do
        begin
            Buffer[iBuffer] := ReadMapperSegment(handle, PlainMemData.aAllocatedSegments[Segments], Addresses);
            iBuffer := iBuffer + 1;
        end;
    end;
end;

(*
*   Write a bunch of bytes into the memory mapper.
*)
procedure WriteToPlainMemory (handle: TMapperHandle; var PlainMemData : TPlainMem; 
                            FirstPosition, LastPosition: real; var Buffer: aBuffer);
var
    FirstSegmentToBeUsed, LastSegmentToBeUsed: byte;
    FirstAddressInSegment, LastAddressInSegment: integer;
    Segments: byte;
    Addresses, temporary1, temporary2: integer;
    iBuffer: integer;
    DifferentSegments, AllRight: boolean;
    i: byte;

begin
(*
*  First we need to define some limits, due to First and Last Positions.
*)

    FirstSegmentToBeUsed    := IntegerDivision(FirstPosition , LastPositionAtSegment) + 1;
    LastSegmentToBeUsed     := IntegerDivision(LastPosition  , LastPositionAtSegment) + 1;

    FirstAddressInSegment   := IntegerRemainder(FirstPosition  , LastPositionAtSegment);
    LastAddressInSegment    := IntegerRemainder(LastPosition   , LastPositionAtSegment);

    iBuffer := 1;
    DifferentSegments := false;
    temporary1 := 0;
    temporary2 := 9;

(*
*   Here the magic begins.
*)
    if FirstSegmentToBeUsed < LastSegmentToBeUsed then
        DifferentSegments := true;

    for Segments := FirstSegmentToBeUsed to LastSegmentToBeUsed do
    begin
        if DifferentSegments = false then
        begin
            temporary1 := FirstAddressInSegment;
            temporary2 := LastAddressInSegment;
        end
        else
            if Segments = FirstSegmentToBeUsed then
            begin
                temporary1 := FirstAddressInSegment;
                temporary2 := LastPositionAtSegment;
            end
            else
            begin
                temporary1 := 1;
                temporary2 := LastAddressInSegment;
            end;
{
        writeln('temporary1: ', temporary1, ' temporary2: ', temporary2, ' DifferentSegments: ', DifferentSegments);
}
        for Addresses := temporary1 to temporary2 do
        begin
            AllRight := WriteMapperSegment(handle, PlainMemData.aAllocatedSegments[Segments], Addresses, Buffer[iBuffer]);
            iBuffer := iBuffer + 1;
        end;
    end;
{
    writeln('FirstPosition: ', FirstPosition:0:0, ' LastPosition: ', LastPosition:0:0);
    writeln('FirstSegmentToBeUsed: ', FirstSegmentToBeUsed, ' LastSegmentToBeUsed: ', LastSegmentToBeUsed);
    writeln('FirstAddressInSegment: ', FirstAddressInSegment, ' LastAddressInSegment: ', LastAddressInSegment);
}
end;

