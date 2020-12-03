{ MAPPER.INC by Kari Lammassaari ? Finland /1996 }
{ Needs msxdos2.inc ! }
 
Type MapperTableType = Record       {Every memory mapper has this table entry.}   
                         SlotId     :Byte;
			 PagesTotal :Byte;
                         PagesFree  :Byte;
                         PagesSystem:Byte; 
                         PagesUser :Byte; 
                         Dummy1,Dummy2,Dummy3 :Byte;
                       End;

    MapperTablePtrType = ^MapperTableType;

Var MapperCount     :Byte;
    MapperTablePtr  :MapperTablePtrType;
    MapperTableAddr :Integer Absolute MapperTablePtr;
    PrimaryMapper   :Byte;     {Updated by function MapperSiupport} 
    SecondaryMapper :Byte;     {If there is only one mapper SecondM = PrimM }
    WantedMapper    :Byte;     {You can set this to Primary/SecondaryMapper.} 	
                               {Defaults PrimaryMapper, which is faster.}
    JumpTablePtr    :Integer;  {Addr of mapper support routine jump table}
			   
    bc,de,hl,ix,iy  :Integer; {These return values from CallMapperPage. }


Function MapperSupport(Var MappCount:Byte):Boolean; 
  
  {Checks the existence of mapper support and initializes Turbo Pascal
   mapper variables.} 

 Var HokVld    :Byte Absolute $fb20;
 Begin
   If Odd(HokVld) Then
     Begin
       MapperSupport := True;

       Inline ( 
	$3A/$20/$FB/$E6/$01/$B7/$28/$49/$ED/$73/$ae/$fb/$31/$ad/$fb/

	$3E/$00/$16/$04/$1E/$01/$CD/$CA/$FF/$E5/$22/MapperTablePtr/
	$DD/$E1/$DD/$7E/$00/$F6/$20/$32/PrimaryMapper/
	$32/WantedMapper/$06/$00/$DD/$7E/$00/$FE/

	$00/$28/$0B/$04/$32/SecondaryMapper/$11/$08/$00/$DD/$19/$18/$EE/
	$78/$32/MapperCount/$AF/$16/$04/$1E/$02/$CD/$CA/$FF/$22/JumpTablePtr/
	$ED/$7B/$ae/$fb/$18/$04/$Ad/$FB/$ae/$7b
              );
        MappCount := MapperCount;
     End  {If}
   Else
    Begin
     MapperSupport := False;
     MapperCount := 0;
    End;
 End;


Function AllocateMapperPage(    SlotType,PageType :Byte;
    			    Var PageId            :Integer ):Boolean;

  Var Id :Integer;
  Begin
       Inline( 
	$21/$E1/$E9/$22/$89/$FD/$ED/$73/$AE/$FB/$31/$AD/$FB/$3A/SlotType/

	$47/$3A/PageType/$2a/JumpTablePtr/$E5/$11/$06/$00/$CD/$89/$FD/$19/$D1/

	$73/$23/$72/$CD/$00/$00/$38/$09/$32/ Id+1 /$78/$32/ Id /$18/
	$07/$AF/$32/ Id+1 /$32/ Id /$ED/$7B/$AE/$FB
	     );
        PageId := Id;
        If Id <> 0 Then AllocateMapperPage := True 
	 Else AllocateMapperPage := False;
   End;


Function FreeMapperPage(PageId:Integer):Boolean;


  Var FREESEG :Integer; 
      Status  :Byte;
  Begin
       FREESEG := JumpTablePtr + 3;

       Inline(
	$21/$E1/$E9/$22/$89/$FD/$ED/$73/$AE/$FB/$31/$AD/$FB/$3A/ PageId /

	$47/$3A/ PageId+1 /$2A/ FREESEG /$E5/$11/$06/$00/$CD/$89/$FD/$19/$D1/

	$73/$23/$72/$CD/$00/$00/$38/$06/$AF/$32/Status/$18/$05/$3E/$FF/
	$32/Status/$ED/$7B/$AE/$FB
	     );
       If Status <> 0 Then FreeMapperPage := False 
         Else FreeMapperPage := True;

End; {FreeMapperPage}

Procedure CallMapperPage(   SlotId,PageNumber :Byte;
			    CallAddress       :Integer;
                        Var A		      :Byte;
			Var BC,DE,HL,IX,IY    :Integer
                         );


   Var OrigSlotId	:Byte Absolute $fd0b;
       TempA		:Byte;	
       TempBC,TempDE,TempHL,TempIX,TempIY :Integer;
	
  Begin
       OrigSlotId := Mem[(Hi(CallAddress) Div 64) + $f341];

       Inline( 
	$21/$E1/$E9/$22/$89/$FD/$ED/$73/$AE/$FB/$31/$AD/$FB/
	$2a/CallAddress/$3a/SlotId/$cd/$24/00/
	$11/$0C/$00/

	$2A/ JumptablePtr /$19/$E5/$11/$1C/$00/$CD/$89/$FD/$19/$D1/$73/$23/$72/

	$FD/$2A/PageNumber-1/$DD/$2A/CallAddress /$3A/ A /$ED/$4B/BC/
	$ED/$5B/ DE /$2A/ HL /$CD/$00/$00/$32/TempA/$ED/$43/TempBC/

	$ED/$53/TempDE/$22/TempHL/$DD/$22/TempIX/$FD/$22/TempIY/
	$2a/CallAddress/$3a/OrigSlotId/$cd/$24/00/
	$ED/$7B/$AE/$FB
	     );

       	A  := TempA;
	BC := TempBC;
	DE := TempDE;
	HL := TempHL;
	IX := TempIX;
	IY := TempIY;

   End;


Function GetPage(MemoryAddress:Integer):Byte ;


  Var PageNum :Byte;  {Used to receive Inline data .}
  Begin
       Inline( 
	$21/$E1/$E9/$22/$89/$FD/$ED/$73/$AE/$FB/$31/$AD/$FB/$11/$15/$00/

	$2A/JumpTablePtr/$19/$E5/$11/$09/$00/$CD/$89/$FD/$19/$D1/$73/$23/$72/

	$2A/ MemoryAddress /$CD/$00/$00/$32/ PageNum /$ED/$7B/$AE/$FB

	     );
        GetPage := PageNum;
   End;

Procedure PutPage(MemoryAddress:Integer;Page:Byte);

  Begin
       Inline(  
	$21/$E1/$E9/$22/$89/$FD/$ED/$73/$AE/$FB/$31/$AD/$FB/$11/$12/$00/

	$2A/JumpTablePtr/$90/$19/$E5/$11/$0C/$00/$CD/$89/$FD/$19/$D1/$73/$23/$72/
	$2A/MemoryAddress /$3A/ Page /$CD/$00/$00/$ED/$7B/$AE/$FB
	     );

  End; {PutPage}

Procedure WriteMapperPage(PageId,
			  SourceAddress,DestinationAddress,
			  ByteCount :Integer);

   Begin
     { SlotId := Lo(PageId); PageNumber := Hi(PageId);}
    
      Inline ( 

	$21/$E1/$E9/$22/$89/$FD/$ED/$73/$AE/$FB/$31/$AD/$FB/
	$2A/DestinationAddress/

	$DD/$2A/SourceAddress/$ED/$4B/ByteCount/
	$C5/$DD/$E5/$08/$DD/$7E/$00/$08/$E5/
	$21/$00/$80/$3A/ PageId /$CD/$24/$00/$11/$0E/$00/$11/$09/$00/

	$2A/JumpTablePtr /$19/$E5/$11/$0E/$00/$CD/$89/$FD/$19/$D1/$73/$23/$72/

	$3A/ PageId +1 /$E1/$E5/$08/$5F/$08/$CD/$00/$00/$3A/$43/$F3/$21/$00/

	$80/$CD/$24/$00/$E1/$DD/$E1/$C1/$23/$DD/$23/$0B/$78/$B1/$20/$B8/

	$ED/$7B/$AE/$FB

             );

   End; {WriteMapperPage}

Procedure ReadMapperPage( PageId,
			  SourceAddress,DestinationAddress,
			  ByteCount :Integer);
   Begin
      {SlotId := Lo(PageId); PageNumber := Hi(PageId);}
      Inline ( 
	$21/$E1/$E9/$22/$89/$FD/$ED/$73/$AE/$FB/$31/$AD/$FB/$2A/SourceAddress/

	$ED/$5B/DestinationAddress/$ED/$4B/ByteCount/
	$C5/$D5/$E5/$21/$00/$80/$3A/ PageId /$CD/$24/$00/
	$11/$0A/$00/$11/$06/$00/$2A/JumpTablePtr/$19/$E5/$11/

	$0A/$00/$CD/$89/$FD/$19/$D1/$73/$23/$72/$3A/ PageId+1 /$E1/$CD/$00/

	$00/$F5/$3A/$43/$F3/$21/$00/$80/$CD/$24/$00/$F1/$D1/$C1/$12/$23/
	$13/$0B/$78/$B1/$20/$C2/$ED/$7B/$AE/$FB
     		
             );

   End; {ReadMapperPage}


Function LoadMcFile(FileName:StringType):Integer; 
{ 
   Lo value = mapper slotId, Hi value = PageNunber,
   returned value 0000 = operation failed 
   The Mc - code must return stackpointer in good condition ! 
}

  Var  	Buffer		    :Array[0..511] Of Byte;	
       	FSize	    	    :Integer;
	Address,PageId      :Integer;
        Handle 		    :Byte;
        ByteCount,OffSet    :Integer;	

  Begin
    FindFirst(FileName,0,Fib);

    If AllocateMapperPage(WantedMapper,1,PageId) And
       (MsxIOResult = 0) Then
      Begin
        
        Move(Fib.FileSize,FSize,2);  {Get Filesize to Integer}

        Handle := MsxFileOpen(filename);

	ByteCount := 512; OffSet := 0;
        Address := Addr(Buffer);
	Repeat
	   MsxFileRead(Handle,Address,ByteCount);
           Writeln(ByteCount);
           WriteMapperPage(PageId,Address,$4000+OffSet,ByteCount);
           OffSet := OffSet + ByteCount;
           FSize := FSize - ByteCount;
        Until FSize = 0;  {All Read}
          
        MsxFileClose(Handle);

        LoadMcFile := PageId;
      End
    Else
      LoadMcFile := 0; {Failed}

  End; {LoadNcFile}

Procedure CallMcPage(Id,Address:Integer;Var a:Byte;Var bc,de,hl,ix,iy:Integer);
 Begin
    CallMapperPage(Lo(Id),Hi(Id),Address,a,bc,de,hl,ix,iy);
 End;



