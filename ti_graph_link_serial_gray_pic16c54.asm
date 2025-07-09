; assemble with gputils:
; $ gpasm -o ti_graph_link_serial_gray_pic16c54.hex ti_graph_link_serial_gray_pic16c54.asm

    processor 16C54
    #include <P16C5x.INC>
    __config _CP_OFF & _WDT_ON & _XT_OSC ; 0x0FFD
    __idlocs 0xC830

; RAM-Variable
LRAM_0x07 equ 0x07
LRAM_0x08 equ 0x08
LRAM_0x09 equ 0x09
LRAM_0x0A equ 0x0A
LRAM_0x0B equ 0x0B
JumpBack equ 0x0C ; used as destination PC
LRAM_0x0D equ 0x0D
LRAM_0x0E equ 0x0E ; likely pointer, stored to FSR
LRAM_0x0F equ 0x0F

; Program

    Org 0x0000

; waits for either tip or ring to be pulled low or timeout
LADR_0x0000:
    BTFSC PORTA,0        ; if PORTA[0] == 0 OR PORTA[2] == 0: GOTO LADR_0x0006
      BTFSS PORTA,2
        GOTO LADR_0x0006
    BTFSC TMR0,7         ; if TMR0[7] == 1: GOTO LADR_0x00E7
      GOTO LADR_0x00E7
    GOTO LADR_0x0000

LADR_0x0006:
    BTFSC LRAM_0x07,5    ; if LRAM_0x07[5] == 1: GOTO LADR_0x00E5
      GOTO LADR_0x00E5
    BSF LRAM_0x07,3      ; LRAM_0x07[3] = 1
    MOVLW 0x08           ; LRAM_0x0B = 0x08
    MOVWF LRAM_0x0B
LADR_0x000B:
    MOVLW LADR_0x000F    ; JumpBack = 0x0F
    MOVWF JumpBack
LADR_0x000D:
    BTFSC TMR0,7         ; if TMR0[7] == 1: GOTO LADR_0x00E7
      GOTO LADR_0x00E7
LADR_0x000F:
    BTFSS PORTA,2        ; if PORTA[2] == 0: GOTO LADR_0x0036
      GOTO LADR_0x0036

    BTFSC PORTA,0        ; if PORTA[0] == 1: GOTO LADR_0x000D
      GOTO LADR_0x000D

    BTFSS PORTA,2        ; if PORTA[2] == 0: GOTO LADR_0x0116
      GOTO LADR_0x0116

    RRF LRAM_0x0A,F      ; LRAM_0x0A = LRAM_0x0A >> 1
    BCF LRAM_0x0A,7
    BSF PORTA,3          ; PORTA[3] = 1

    MOVLW LADR_0x001C    ; JumpBack = 0x1C
    MOVWF JumpBack

LADR_0x001A:
    BTFSC TMR0,7         ; if TMR0[7] == 1: GOTO LADSR_0x00E7
      GOTO LADR_0x00E7

LADR_0x001C:
    BTFSS PORTA,0        ; if PORTA[0] == 0: GOTO LADR_0x001A
      GOTO LADR_0x001A

    BCF PORTA,3          ; PORTA[3] = 0

    MOVLW LADR_0x0025    ; JumpBack = 0x025
    MOVWF JumpBack

; wait until PORTA[2] is high or timeout
LADR_0x0021:
    BTFSC TMR0,7         ; if TMR0[7] == 1: GOTO LADR_0x00E7
      GOTO LADR_0x00E7
    BTFSS PORTA,2        ; if PORTA[2] == 0: GOTO LADR_0x0021
      GOTO LADR_0x0021

LADR_0x0025:
    DECFSZ LRAM_0x0B,F   ; LRAM_0x0B -= 1
      GOTO LADR_0x000B   ; if LRAM_0x0B != 0: GOTO LADR_0x000B

    MOVF LRAM_0x0E,W     ; W = LRAM_0x0E
    IORLW 0xF0           ; W |= 0xF0
    MOVWF FSR            ; FSR = W
    MOVF LRAM_0x0A,W     ; W = LRAM_0x0A
    MOVWF INDF           ; IND = W
    INCF LRAM_0x0E,F     ; LRAM_0x0E += 1
    INCF LRAM_0x0D,F     ; LRAM_0x0D +=1
    BTFSC LRAM_0x0D,4
      BSF LRAM_0x07,5
    BCF LRAM_0x07,4
    BCF LRAM_0x07,3
    MOVLW LADR_0x0000           ;   b'00000000'  d'000'
    MOVWF JumpBack
    CLRWDT
    GOTO LADR_0x00E5
LADR_0x0036:
    BTFSS PORTA,0
      GOTO LADR_0x0116
    RRF LRAM_0x0A,F
    BSF LRAM_0x0A,7
    BSF PORTA,1
    MOVLW LADR_0x003F           ;   b'00111111'  d'063'  "?"
    MOVWF JumpBack
LADR_0x003D:
    BTFSC TMR0,7
      GOTO LADR_0x00E7
LADR_0x003F:
    BTFSS PORTA,2
      GOTO LADR_0x003D
    BCF PORTA,1
    MOVLW LADR_0x0048           ;   b'01001000'  d'072'  "H"
    MOVWF JumpBack
LADR_0x0044:
    BTFSC TMR0,7
      GOTO LADR_0x00E7
    BTFSS PORTA,0
      GOTO LADR_0x0044
LADR_0x0048:
    DECFSZ LRAM_0x0B,F
      GOTO LADR_0x000B
    MOVF LRAM_0x0E,W
    IORLW 0xF0           ;   b'11110000'  d'240'
    MOVWF FSR
    MOVF LRAM_0x0A,W
    MOVWF INDF
    INCF LRAM_0x0E,F
    INCF LRAM_0x0D,F
    BTFSC LRAM_0x0D,4
    BSF LRAM_0x07,5
    BCF LRAM_0x07,4
    BCF LRAM_0x07,3
    MOVLW LADR_0x0000           ;   b'00000000'  d'000'
    MOVWF JumpBack
    CLRWDT
    GOTO LADR_0x00E5

LADR_0x0059:
    BTFSC LRAM_0x07,4
      GOTO LADR_0x00F6
    BSF LRAM_0x07,3
    MOVLW 0x08           ;   b'00001000'  d'008'
    MOVWF LRAM_0x0B
    MOVF LRAM_0x0F,W
    IORLW 0xF0           ;   b'11110000'  d'240'
    MOVWF FSR
    MOVF INDF,W
    MOVWF LRAM_0x0A
    INCF LRAM_0x0F,F
    DECF LRAM_0x0D,F
    BTFSC STATUS,Z
      BSF LRAM_0x07,4
    BCF LRAM_0x07,5
    MOVF LRAM_0x0D,W
    XORLW 0x0F           ;   b'00001111'  d'015'
    BTFSC STATUS,Z
      GOTO LADR_0x0071
    MOVF LRAM_0x0D,W
    XORLW 0x0E           ;   b'00001110'  d'014'
    BTFSC STATUS,Z
      BTFSS LRAM_0x07,0
        BCF PORTB,2
LADR_0x0071:
    RRF LRAM_0x0A,F
    BTFSC STATUS,C
      GOTO LADR_0x008B
    BSF PORTA,1
    MOVLW LADR_0x0079           ;   b'01111001'  d'121'  "y"
    MOVWF JumpBack
LADR_0x0077:
    BTFSC TMR0,7
      GOTO LADR_0x00F8
LADR_0x0079:
    BTFSC PORTA,2
      GOTO LADR_0x0077
    BCF PORTA,1
    MOVLW LADR_0x0080           ;   b'10000000'  d'128'
    MOVWF JumpBack
LADR_0x007E:
    BTFSC TMR0,7
      GOTO LADR_0x00F8
LADR_0x0080:
    BTFSS PORTA,0
      GOTO LADR_0x0116
    BTFSS PORTA,2
      GOTO LADR_0x007E
    DECFSZ LRAM_0x0B,F
      GOTO LADR_0x0071
    BCF LRAM_0x07,3
    MOVLW LADR_0x0059           ;   b'01011001'  d'089'  "Y"
    MOVWF JumpBack
    CLRWDT
    GOTO LADR_0x00F6
LADR_0x008B:
    BSF PORTA,3
    MOVLW LADR_0x0090           ;   b'10010000'  d'144'
    MOVWF JumpBack
LADR_0x008E:
    BTFSC TMR0,7
      GOTO LADR_0x00F8
LADR_0x0090:
    BTFSC PORTA,0
      GOTO LADR_0x008E
    BCF PORTA,3
    MOVLW LADR_0x0097           ;   b'10010111'  d'151'
    MOVWF JumpBack
LADR_0x0095:
    BTFSC TMR0,7
      GOTO LADR_0x00F8
LADR_0x0097:
    BTFSS PORTA,2
      GOTO LADR_0x0116
    BTFSS PORTA,0
      GOTO LADR_0x0095
    DECFSZ LRAM_0x0B,F
      GOTO LADR_0x0071
    BCF LRAM_0x07,3
    MOVLW LADR_0x0059           ;   b'01011001'  d'089'  "Y"
    MOVWF JumpBack
    CLRWDT
    GOTO LADR_0x00F6
LADR_0x00A2:
    BSF LRAM_0x07,0
    MOVLW 0x1E           ;   b'00011110'  d'030'
    MOVWF TMR0
    MOVLW 0x08           ;   b'00001000'  d'008'
    MOVWF LRAM_0x09
    MOVF LRAM_0x0D,W
    ANDLW 0x0E           ;   b'00001110'  d'014'
    XORLW 0x0E           ;   b'00001110'  d'014'
    BTFSC STATUS,Z
      BSF PORTB,2
    MOVF JumpBack,W
    MOVWF PCL            ; !!Program-Counter-Modification
LADR_0x00AE:
    RRF LRAM_0x08,F
    BCF LRAM_0x08,7
    BTFSS PORTB,0
      BSF LRAM_0x08,7
    MOVF JumpBack,W
    DECFSZ LRAM_0x09,F
      MOVWF PCL            ; !!Program-Counter-Modification
    MOVF LRAM_0x0E,W
    IORLW 0xF0           ;   b'11110000'  d'240'
    MOVWF FSR
    MOVF LRAM_0x08,W
    MOVWF INDF
    INCF LRAM_0x0E,F
    INCF LRAM_0x0D,F
    BTFSC LRAM_0x0D,4
      BSF LRAM_0x07,5
    BCF LRAM_0x07,4
    BCF LRAM_0x07,0
    CLRWDT
    MOVF JumpBack,W
    MOVWF PCL            ; !!Program-Counter-Modification
LADR_0x00C3:
    BSF LRAM_0x07,1
    BSF PORTB,1
    MOVF LRAM_0x0F,W
    IORLW 0xF0           ;   b'11110000'  d'240'
    MOVWF FSR
    MOVF INDF,W
    MOVWF LRAM_0x08
    INCF LRAM_0x0F,F
    DECF LRAM_0x0D,F
    BTFSC STATUS,Z
      BSF LRAM_0x07,4
    BCF LRAM_0x07,5
    MOVLW 0x08           ;   b'00001000'  d'008'
    MOVWF LRAM_0x09
    MOVF JumpBack,W
    MOVWF PCL            ; !!Program-Counter-Modification
LADR_0x00D3:
    BTFSC LRAM_0x07,2
      GOTO LADR_0x00DF
    RRF LRAM_0x08,F
    BTFSC STATUS,C
      BCF PORTB,1
    BTFSS STATUS,C
      BSF PORTB,1
    MOVF JumpBack,W
    DECFSZ LRAM_0x09,F
      MOVWF PCL            ; !!Program-Counter-Modification
    BSF LRAM_0x07,2
    MOVWF PCL            ; !!Program-Counter-Modification
LADR_0x00DF:
    BCF PORTB,1
    BCF LRAM_0x07,1
    BCF LRAM_0x07,2
    CLRWDT
    MOVF JumpBack,W
    MOVWF PCL            ; !!Program-Counter-Modification
LADR_0x00E5:
    BTFSS TMR0,7
      GOTO LADR_0x00E5
LADR_0x00E7:
    BTFSS TMR0,4
      GOTO LADR_0x00E7
    MOVLW 0x2E           ;   b'00101110'  d'046'  "."
    MOVWF TMR0
    BTFSC LRAM_0x07,1
      GOTO LADR_0x00D3
    BTFSS LRAM_0x07,4
      GOTO LADR_0x00C3
    MOVF JumpBack,W
    BTFSC LRAM_0x07,3
      MOVWF PCL            ; !!Program-Counter-Modification
    BTFSC PORTA,0
      BTFSS PORTA,2
        GOTO LADR_0x0006
    GOTO LADR_0x0109

; wait for TMR0[7] to be set
; while (TMR0[7] == 0) {}
LADR_0x00F6:
    BTFSS TMR0,7
      GOTO LADR_0x00F6

LADR_0x00F8:
    BTFSS TMR0,4         ; if TMR0[4] == 0: GOTO LADR_0x00F8
      GOTO LADR_0x00F8

    MOVLW 0x2E           ; TMR0 = 0x2E
    MOVWF TMR0

    BTFSC LRAM_0x07,0    ; if LRAM_0x07 == 1: GOTO LADR_0x00AE
      GOTO LADR_0x00AE

    MOVLW 0x66           ; TMR0 = 0x66
    MOVWF TMR0

    BTFSC PORTB,0        ; if PORTB[0] == 1: GOTO LADR_0x00A2
      GOTO LADR_0x00A2

    MOVF JumpBack,W     ; if LRAM_0x07[3] == 1: return to callback 
    BTFSC LRAM_0x07,3
      MOVWF PCL

    MOVF JumpBack,W
    BTFSS LRAM_0x07,4    ; if LRAM_0x07[4] == 0: GOTO LADR_0x0059
      GOTO LADR_0x0059
    GOTO LADR_0x0109     ; useless

LADR_0x0109:
    CLRWDT               ; reset watchdog

    MOVLW LADR_0x0059    ; JumpBack = 0x59
    MOVWF JumpBack

    BSF PORTB,7          ; PORTB[7] = 1

    BTFSC PORTB,0        ; if PORTB[0] == 1: goto LADR_0x00A2
      GOTO LADR_0x00A2

    MOVLW LADR_0x0006    ; JumpBack = 0x06
    MOVWF JumpBack

    BCF PORTB,7          ; PORTB[7] = 1

    BTFSC PORTA,0        ; if PORTA[0] == 1 OR (PORTA[0] == 0 AND PORTA[2] == 0): GOTO LADR_0x0006
      BTFSS PORTA,2      ; else: GOTO LADR_0x0109
        GOTO LADR_0x0006
    GOTO LADR_0x0109

LADR_0x0116:
    BSF PORTB,2          ; PORTB[2] = 1
    BSF PORTB,1          ; PORTB[1] = 1
LADR_0x0118:
    CLRWDT               ; reset watchdog
    BTFSC PORTA,2        ; if PORTA[2] == 1 OR (PORTA[2] == 0 AND PORTA[0] == 0): GOTO LADR_0x0118
      BTFSS PORTA,0
        GOTO LADR_0x0118
    GOTO Initialize

ResetVector: ; 0x011D
    MOVLW 0x05           ; TRISA = b'00000101: RA0=input, RA1=output, RA2=input, RA3=output
    TRIS PORTA

    MOVLW 0x01           ; TRISB = b'00000001': RB0=input, RB1=output, RB2=output, RB[3-7]=output
    TRIS PORTB

    MOVLW LADR_0x0059    ; JumpBack = 0x59
    MOVWF JumpBack

    MOVLW 0x0E           ; OPTION = b'00001110': T0CS=0 (CLKOUT), T0SE=0 (low->high transition), PSA=1 (WDT), PS<2:0>=110 (1:64)
    OPTION

    MOVLW 0x2E           ; TMR0 = b'00101110'
    MOVWF TMR0

Initialize: ; 0x0127
    CLRW                 ; STATUS = 0
    MOVWF STATUS

    ; initialize variables
    MOVLW 0x11           ; LRAM_0x07 = 0x11
    MOVWF LRAM_0x07
    CLRF LRAM_0x08       ; LRAM_0x08 = 0x00
    CLRF LRAM_0x09       ; LRAM_0x09 = 0x00
    CLRF LRAM_0x0A       ; LRAM_0x0A = 0x00
    CLRF LRAM_0x0B       ; LRAM_0x0B = 0x00
    MOVLW 0x10
    MOVWF LRAM_0x0E      ; LRAM_0x0E = 0x10
    MOVWF LRAM_0x0F      ; LRAM_0x0F = 0x10
    CLRF LRAM_0x0D       ; LRAM_0x0B = 0x00

    ; set all output pins low
    BCF PORTA,1          ; clear PORTA[1]
    BCF PORTA,3          ; clear PORTA[3]
    BCF PORTB,1          ; clear PORTB[1]
    BCF PORTB,2          ; clear PORTB[2]
    GOTO LADR_0x0109

    Org 0x1ff

;   Reset-Vector
    GOTO ResetVector

    End
