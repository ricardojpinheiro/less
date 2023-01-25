{This code contains procedures and a function (USING BIOS ROUTINES)

  - Procedure ReadVRAM 
          (VRAMaddress: Integer;var RAMaddress;NumberOfBytes: Integer);

  - Procedure WriteVRAM 
          (VRAMaddress: Integer;var RAMaddress;NumberOfBytes: Integer);

  - Procedure fillVRAM 
          (VRAMaddress: Integer;NumberOfBytes: Integer;Value: Byte);
  
  - Procedure Vpoke (VRAMaddress: Integer;Value: Byte);

  - Function Vpeek (VRAMaddress: Integer): Byte;

 }

const
    _CALROM: array[0..6] of byte = ($FD,$21,$00,$00,$C3,$D4,$20);
    _CALSUB: array[0..6] of byte = ($FD,$21,$00,$00,$C3,$D4,$20);    

Procedure ReadVRAM (VRAMaddress: Integer;var RAMaddress;NumberOfBytes: Integer);
  begin
   inline ($DD/$21/$59/$00/$ED/$4B/NumberOfBytes/
           $ED/$5B/RAMaddress/$2A/VRAMaddress/$C3/_CALROM);
  end;

Procedure WriteVRAM (VRAMaddress: Integer;var RAMaddress;NumberOfBytes: Integer);
  begin
   inline ($DD/$21/$5C/$00/$ED/$4B/NumberOfBytes/
           $ED/$5B/VRAMaddress/$2A/RAMaddress/$C3/_CALROM);
  end;

Procedure FillVRAM (VRAMaddress: Integer;NumberOfBytes: Integer;Value: Byte);
  begin
   inline ($DD/$21/$6B/$01/
           $ED/$4B/NumberOfBytes/$2A/VRAMaddress/$3A/Value/$C3/_CALROM);
  end;

Function Vpeek (VRAMaddress: Integer): Byte;

  begin
    inline($DD/$21/$74/$01/
           $2A/VRAMaddress/$CD/_CALROM/$6F/$26/$00/$C9);
  end;

procedure Vpoke (VRAMaddress: Integer;Value: Byte);
begin
inline($DD/$21/$77/$01/
       $2A/VRAMaddress/$3A/Value/$C3/_CALROM);
end;
