10 SCREEN 0 : width 80 : KEY OFF : E=&HC000
20 READ A$ : IF A$="M" THEN 60
30 POKE E,VAL("&H"+A$)
40 E=E+1
50 GOTO 20
60 LOCATE 0,2: PRINT"Essa linha se mexe!"
65 PRINT "TECLE ALGO ..."
70 LOCATE 0,23 : PRINT"Esta linha não se mexe."
80 locate 0, 3: A$=INPUT$(1)
90 DEFUSR=&HC000 
95 for a = 1 to 15 : X=USR(0) : next a
100 DATA 21,00,00 : ' LD HL,&H0000 <- Linha 1 na VRAM (em 80 colunas).
110 DATA 11,00,C1 : ' LD DE,&HC100 <- Endereço da RAM que vai guardar a tabela de nomes.
120 DATA 01,90,06 : ' LD BC,&H0690 <- Comprimento do bloco (80 x 21 linhas).
130 DATA CD,59,00 : ' CALL &H0059  <- Chamada VRAM -> RAM.
140 DATA 21,00,C1 : ' LD HL,&HC200 <- Endereço da RAM que guarda a tabela de nomes.
150 DATA 11,50,00 : ' LD DE,&H0050 <- Linha 2 na VRAM (em 80 colunas).
160 DATA 01,90,06 : ' LD BC,&H0690 <- Comprimento do bloco (80 x 21 linhas).
170 DATA CD,5C,00 : ' CALL &H005C  <- Chamada RAM -> VRAM.
180 DATA C9,M,    : ' RET
