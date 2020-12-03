{scrollup.inc scrolldo.inc}

Procedure ScrollWindowUp(ScrollAreaPtr:Integer);
  {
    The defined portion of screen is scolled up and an empty line is written
    at the bottom line of the scrolled area

    SrollAreaPtr points 4-byte array/group:

      offs  0 = upper left column (x) of the area to be scrolled
           +1 = uppermost row (y) of the area to be scrolled
           +2 = width of the area to be scrolled
           +3 = height of the area to be scrolled
   }
  Var
      bufpt    :Array[0..80] Of Byte;
      bufaddr  :Integer Absolute bufpt;

  Begin
     Inline (
        $DD/$2A/ScrollAreaPtr/$DD/$7E/$3/$FE/$2/$38/$77/$3d/$47/$DD/$7E/$1/
        $3c/$5F/
        $16/$0/$E5/$B7/$EB/$ED/$6A/$ED/$6A/$ED/$6A/$ED/$6A/$E5/$ED/$6A/
        $ED/$6A/$D1/$19/$EB/$E1/$DD/$6E/$0/$26/$0/$19/$E5/$FD/$E1/$ED/
        $5B/bufaddr /$C5/$D5/$F3/$7D/$D3/$99/$7C/$E6/$3F/$D3/$99/$DD/$46/
        $2/$C5/$DB/$98/$12/$13/$10/$FA/$C1/$11/$50/$0/$B7/$ED/$52/$FD/
        $19/$D1/$D5/$EB/$7B/$D3/$99/$7A/$F6/$40/$D3/$99/$7E/$D3/$98/$23/
        $10/$FA/$D1/$C1/$FD/$E5/$E1/$10/$CA/$11/$50/$0/$B7/$ED/$52/$EB/
        $7B/$D3/$99/$7A/$F6/$40/$D3/$99/$DD/$46/$2/$AF/$D3/$98/$10/$FB
             );

  End; {ScrollWindowUp }

Procedure ScrollWindowDown(ScrollAreaPtr:Integer);
 
 {
    The defined portion of screen is scolled up and an empty line is written
    at the bottom line of the scrolled area

    SrollAreaPtr points 4-byte array/group:

      offs  0 = upper left column (x) of the area to be scrolled
           +1 = uppermost row (y) of the area to be scrolled
           +2 = width of the area to be scrolled
           +3 = height of the area to be scrolled
   }
  Var
      bufpt    :Array[0..80] Of Byte;
      bufaddr  :Integer Absolute bufpt;

  Begin
     Inline (
        $DD/$2A/ScrollAreaPtr/$DD/$7E/$3/$FE/$2/$38/$7f/$3d/$47/$DD/$7E/$1/
        $DD/$86/$3/$3D/$3d/$5F/$16/$0/$E5/$B7/$EB/$ED/$6A/$ED/$6A/$ED/$6A/
        $ED/$6A/$E5/$ED/$6A/$ED/$6A/$D1/$19/$EB/$E1/$DD/$6E/$0/$26/$0/
        $19/$E5/$FD/$E1/$ED/$5B/bufaddr /$C5/$D5/$F3/$7D/$D3/$99/$7C/$E6/
        $3F/$D3/$99/$DD/$46/$2/$C5/$DB/$98/$12/$13/$10/$FA/$C1/$11/$50/
        $0/$B7/$19/$E5/$FD/$E5/$E1/$ED/$52/$E5/$FD/$E1/$E1/$D1/$D5/$EB/
        $7B/$D3/$99/$7A/$F6/$40/$D3/$99/$7E/$D3/$98/$23/$10/$FA/$D1/$C1/
        $FD/$E5/$E1/$10/$C3/$11/$50/$0/$19/$EB/$7B/$D3/$99/$7A/$F6/$40/
        $D3/$99/$DD/$46/$2/$AF/$D3/$98/$10/$FB

             );

  End; {ScrollWindowDown }


