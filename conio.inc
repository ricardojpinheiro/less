Procedure CALSLT (Var regs: TRegs);
Var
    nA, nF:                     Byte;
    nHL, nDE, nBC, nIX, nIY:    Integer;

Begin
    nA  := regs.A;
    nHL := regs.HL;
    nDE := regs.DE;
    nBC := regs.BC;
    nIX := regs.IX;
    nIY := Swap( regs.IY );

    InLine(   $F5/                  { PUSH AF      ; Push all registers  }
              $C5/                  { PUSH BC                            }
              $D5/                  { PUSH DE                            }
              $E5/                  { PUSH HL                            }
              $DD/$E5/              { PUSH IX                            }
              $FD/$E5/              { PUSH IY                            }
              $3A/nA/               { LD A , (nA )                       }
              $ED/$4B/nBC/          { LD BC, (nBC)                       }
              $ED/$5B/nDE/          { LD DE, (nDE)                       }
              $2A/nHL/              { LD HL, (nHL)                       }
              $DD/$2A/nIX/          { LD IX, (nIX)                       }
              $FD/$2A/nIY/          { LD IY, (nIY)                       }
              $CD/$1C/$00/          { CALL &H001C; CALL CALSLT           }
              $32/nA/               { LD (nA ), A                        }
              $ED/$43/nBC/          { LD (nBC), BC                       }
              $ED/$53/nDE/          { LD (nDE), DE                       }
              $22/nHL/              { LD (nHL), HL                       }
              $DD/$22/nIX/          { LD (nIX), IX                       }
              $FD/$22/nIY/          { LD (nIY), IY                       }
              $F5/                  { PUSH AF                            }
              $E1/                  { POP HL                             }
              $22/nF/               { LD (nF), HL                        }
              $FD/$E1/              { POP YI       ; Pop all registers   }
              $DD/$E1/              { POP IX                             }
              $E1/                  { POP HL                             }
              $D1/                  { POP DE                             }
              $C1/                  { POP BC                             }
              $F1/                  { POP AF                             }
              $FB                   { EI                                 }
            );

  (* Update the caller register struct *)
    regs.A  := nA;
    regs.F  := nF;
    regs.BC := nBC;
    regs.DE := nDE;
    regs.HL := nHL;
    regs.IY := nIY;
    regs.IX := nIX;
End;

Procedure ScreenWidth (nWidth: Byte);
Begin
    LINL40  := nWidth;
    regs.IX := ctINITXT;
    regs.IY := EXPTBL;
    CALSLT (regs);
End;

Procedure SetFnKeyStatus( bFnKeyStatus : Boolean );
Begin
    If (bFnKeyStatus) Then
        regs.IX := ctDSPFNK
    Else
        regs.IX := ctERAFNK;

    regs.IY := EXPTBL;
    CALSLT (regs);
End;

(**
  * Change the screen color (Foreground, background and Border);
  * @param nFgColor The foreground color to change;
  * @param nBkColor The backgound color to change;
  * @param nBdrColor The border color to change;
  *)
Procedure Color( nFgColor, nBkColor, nBdrColor : Byte );
Const
        ctCHGCLR  = $0062;    { Changes the color of the screen }

Var
        regs    : TRegs;
        EXPTBL  : Byte Absolute $FCC1; { Slot 0 }
        FORCLR  : Byte Absolute $F3E9; { Foreground color  }
        BAKCLR  : Byte Absolute $F3EA; { Background color  }
        BDRCLR  : Byte Absolute $F3EB; { Border color      }

Begin
  FORCLR  := nFgColor ;
  BAKCLR  := nBkColor;
  BDRCLR  := nBdrColor ;
  regs.IX := ctCHGCLR;
  regs.IY := EXPTBL;
  CALSLT( regs );
End;

Procedure GetScreenStatus( Var scrStatus : TScreenStatus );
Begin
    With scrStatus Do
    Begin
        nWidth    := LINLEN;
        nBkColor  := BAKCLR;
        nBdrColor := BDRCLR;
        nFgColor  := FORCLR;
        bFnKeyOn  := (CNSDFG <> 0);

        If( SCRMOD = 0 ) Then
            TextMode := TextMode4080
        Else
            TextMode := TextMode32;
    End;
End;

(**
  * Set the new text mode;
  * @param mode The new @see TTextMode to set;
  *)
Procedure SetTextMode( mode : TTextMode );
Const
        ctINITXT  = $006C;    { Initialize screen for text mode (40x24) }
        ctINIT32  = $006F;    { Initialize screen mode for text (32x24) }

Var
        regs    : TRegs;
        EXPTBL  : Byte Absolute $FCC1; { Slot 0 }

Begin
  If( mode = TextMode4080 )  Then
    regs.IX := ctINITXT
  Else
    regs.IX := ctINIT32;

  regs.IY := EXPTBL;
  CALSLT( regs );
End;

(**
  * Set the new screen status, retrieving the old screen
  * status;
  * @param scrStatus The new @see TScreenStatus with the new
  * screen colors and dimension;
  * @param scrRet The old @see TScreenStatus;
  *)
Procedure SetScreenStatus( scrStatus  : TScreenStatus;
                           Var scrRet : TScreenStatus );
Begin
  GetScreenStatus( scrRet );

  ScreenWidth( scrStatus.nWidth );
  SetFnKeyStatus( scrStatus.bFnKeyOn );
  SetTextMode( scrStatus.TextMode );
  Color( scrStatus.nFgColor,
         scrStatus.nBkColor,
         scrStatus.nBdrColor );
End;

function msx_version: byte;
var 
    version:    byte;
begin
  inline($3e/$80/              { LD A,&H80        }
         $21/$2d/$00/          { LD HL,&H002D     }
         $cd/$0c/$00/          { CALL &H000C      }
         $32/version/          { LD (VERSIE),A    }
         $fb);                 { EI               }
  msx_version := version + 1;
end;
