; assemble with gputils:
; $ gpasm -o ti_graph_link_serial_gray.hex ti_graph_link_serial_gray.asm

    processor 16C54
    #include <P16C5x.INC>
    __config _CP_OFF & _WDT_ON & _XT_OSC ; 0x0FFD
    __idlocs 0xC830

; RAM variables
StateFlags equ 0x07 ; flags, bits 0-5 are used
LRAM_0x08 equ 0x08 ; stores incoming serial bits from TX
LRAM_0x09 equ 0x09 ; stores count of remaining bits
LRAM_0x0A equ 0x0A ; stores the bits sending out GraphLink
LRAM_0x0B equ 0x0B ; stores count of remaining bits
JumpBack equ 0x0C ; used as destination PC
LRAM_0x0D equ 0x0D ; counter for something
LRAM_0x0E equ 0x0E ; likely pointer, stored to FSR
LRAM_0x0F equ 0x0F ; likely pointer, stored to FSR

; Graph-Link pins
#define TIP_in   PORTA,0
#define TIP_out  PORTA,1
#define RING_in  PORTA,2
#define RING_out PORTA,3

; RS232 pins
#define Ser_TX   PORTB,0
#define Ser_RX   PORTB,1
#define Ser_CTS  PORTB,2

; debug
#define DebugPin PORTB,7

    ; Program
    Org 0x0000

; waits for either tip or ring to be pulled low or timeout
LADR_0x0000:
    BTFSC TIP_in         ; if TIP == 0 || RING == 0:
      BTFSS RING_in
        GOTO LADR_0x0006 ;   GOTO LADR_0x0006
    BTFSC TMR0,7         ; if TMR0[7] == 1:
      GOTO LADR_0x00E7   ;   GOTO LADR_0x00E7
    GOTO LADR_0x0000

LADR_0x0006:
    BTFSC StateFlags,5   ; if StateFlags[5] == 1:
      GOTO LADR_0x00E5   ;   GOTO LADR_0x00E5

    BSF StateFlags,3     ; StateFlags[3] = 1
    MOVLW 0x08           ; LRAM_0x0B = 0x08
    MOVWF LRAM_0x0B
LADR_0x000B:
    MOVLW LADR_0x000F    ; JumpBack = LADR_0x000F
    MOVWF JumpBack
LADR_0x000D:
    BTFSC TMR0,7         ; if TMR0[7] == 1:
      GOTO LADR_0x00E7   ;   GOTO LADR_0x00E7
LADR_0x000F:
    BTFSS RING_in        ; if RING == 0:
      GOTO LADR_0x0036   ;   GOTO LADR_0x0036

    BTFSC TIP_in         ; if TIP == 1:
      GOTO LADR_0x000D   ;   GOTO LADR_0x000D

    BTFSS RING_in        ; if RING == 0:
      GOTO LADR_0x0116   ;   GOTO LADR_0x0116

    RRF LRAM_0x0A,F      ; LRAM_0x0A = LRAM_0x0A >> 1
    BCF LRAM_0x0A,7
    BSF RING_out         ; RING = 1

    MOVLW LADR_0x001C    ; JumpBack = LADR_0x001C
    MOVWF JumpBack

LADR_0x001A:
    BTFSC TMR0,7         ; if TMR0[7] == 1:
      GOTO LADR_0x00E7   ;   GOTO LADSR_0x00E7

LADR_0x001C:
    BTFSS TIP_in         ; if TIP == 0:
      GOTO LADR_0x001A   ;   GOTO LADR_0x001A

    BCF RING_out         ; RING = 0

    MOVLW LADR_0x0025    ; JumpBack = LADR_0x0025
    MOVWF JumpBack

; wait until RING is high or timeout
LADR_0x0021:
    BTFSC TMR0,7         ; if TMR0[7] == 1:
      GOTO LADR_0x00E7   ;   GOTO LADR_0x00E7
    BTFSS RING_in        ; if RING == 0:
      GOTO LADR_0x0021   ;   GOTO LADR_0x0021

LADR_0x0025:
    DECFSZ LRAM_0x0B,F   ; LRAM_0x0B -= 1
      GOTO LADR_0x000B   ; if LRAM_0x0B != 0: GOTO LADR_0x000B

    MOVF LRAM_0x0E,W     ; W = LRAM_0x0E
    IORLW 0xF0           ; W |= 0xF0
    MOVWF FSR            ; FSR = W

    MOVF LRAM_0x0A,W     ; W = LRAM_0x0A
    MOVWF INDF           ; IND = W

    INCF LRAM_0x0E,F     ; LRAM_0x0E += 1
    INCF LRAM_0x0D,F     ; LRAM_0x0D += 1

    BTFSC LRAM_0x0D,4    ; if LRAM_0x0D[4] == 1:
      BSF StateFlags,5   ;   StateFlags[5] = 1

    BCF StateFlags,4     ; StateFlags[4] = 0
    BCF StateFlags,3     ; StateFlags[3] = 0

    MOVLW LADR_0x0000    ; JumpBack = LADR_0x0000
    MOVWF JumpBack

    CLRWDT               ; reset watchdog
    GOTO LADR_0x00E5

LADR_0x0036:
    BTFSS TIP_in         ; if TIP == 0:
      GOTO LADR_0x0116   ;   GOTO LADR_0x0116

    RRF LRAM_0x0A,F      ; LRAM_0x0A = (LRAM_0x0A >> 1) | 0'b1000_0000
    BSF LRAM_0x0A,7
    BSF TIP_out          ; TIP = 1
    MOVLW LADR_0x003F    ; JumpBack = LADR_0x003F
    MOVWF JumpBack

    ; loop until RING goes high or timeout
LADR_0x003D:
    BTFSC TMR0,7         ; if TMR0[7] == 1:
      GOTO LADR_0x00E7   ;   GOTO LADR_0x00E7
LADR_0x003F:
    BTFSS RING_in        ; if RING == 0:
      GOTO LADR_0x003D   ;   GOTO LADR_0x003D

    BCF TIP_out          ; TIP = 0
    MOVLW LADR_0x0048    ; JumpBack = LADR_0x0048
    MOVWF JumpBack

    ; loop until TIP goes low or timeout
LADR_0x0044:
    BTFSC TMR0,7         ; if TMR0[7] == 1:
      GOTO LADR_0x00E7   ;   GOTO LADR_0x00E7
    BTFSS TIP_in         ; if TIP == 0:
      GOTO LADR_0x0044   ;   GOTO LADR_0x0044

LADR_0x0048:             ; mostly a copy of the code from LADR_0x0025
    DECFSZ LRAM_0x0B,F   ; LRAM_0x0B -= 1
      GOTO LADR_0x000B   ; if LRAM_0x0B != 0: GOTO LADR_0x000B

    MOVF LRAM_0x0E,W     ; FSR = LRAM_0x0E | 0xF0
    IORLW 0xF0
    MOVWF FSR

    MOVF LRAM_0x0A,W     ; INDF = LRAM_0x0A
    MOVWF INDF

    INCF LRAM_0x0E,F     ; LRAM_0x0E += 1
    INCF LRAM_0x0D,F     ; LRAM_0x0D += 1

    BTFSC LRAM_0x0D,4    ; if LRAM_0x0D[4] == 1:
      BSF StateFlags,5   ;   StateFlags[5] = 1

    BCF StateFlags,4     ; StateFlags[4] = 0
    BCF StateFlags,3     ; StateFlags[3] = 0

    MOVLW LADR_0x0000    ; JumpBack = LADR_0x0000
    MOVWF JumpBack

    CLRWDT               ; reset watchdog
    GOTO LADR_0x00E5

LADR_0x0059:
    BTFSC StateFlags,4   ; if StateFlags[4] == 1:
      GOTO LADR_0x00F6   ;   GOTO LADR_0x00F6

    BSF StateFlags,3     ; StateFlags[3] = 1
    MOVLW 0x08           ; LRAM_0x0B = 0x08
    MOVWF LRAM_0x0B

    MOVF LRAM_0x0F,W     ; FSR = LRAM_0x0F | 0xF0
    IORLW 0xF0
    MOVWF FSR

    MOVF INDF,W          ; LRAM_0x0A = INDF
    MOVWF LRAM_0x0A

    INCF LRAM_0x0F,F     ; LRAM_0x0F += 1
    DECF LRAM_0x0D,F     ; LRAM_0x0D -= 1
    BTFSC STATUS,Z       ; if LRAM_0x0D == 0:
      BSF StateFlags,4   ;   StateFlags[4] = 1

    BCF StateFlags,5     ; StateFlags[5] = 0
    MOVF LRAM_0x0D,W     ; W = LRAM_0x0D
    XORLW 0x0F           ; W = W ^ 0x0F
    BTFSC STATUS,Z       ; if STATUS.Z == 1 (W == 0):
      GOTO LADR_0x0071   ;   GOTO LADR_0x0071

    MOVF LRAM_0x0D,W     ; W = LRAM_0x0D
    XORLW 0x0E           ; W = W ^ 0x0E
    BTFSC STATUS,Z       ; if STATUS.Z == 0 || StateFlags[0] == 0:
      BTFSS StateFlags,0
        BCF Ser_CTS      ; CTS = 0

LADR_0x0071:
    RRF LRAM_0x0A,F      ; STATUS.C = LRAM_0x0A[0], LRAM_0x0A = (LRAM_0x0A >> 1)
    BTFSC STATUS,C       ; if STATUS.C != 0:
      GOTO LADR_0x008B   ;   GOTO LADR_0x008B

    BSF TIP_out          ; TIP = 1
    MOVLW LADR_0x0079    ; JumpBack = LADR_0x0079
    MOVWF JumpBack

    ; loop until RING goes low or timeout
LADR_0x0077:
    BTFSC TMR0,7         ; if TMR0[7] == 1:
      GOTO LADR_0x00F8   ;   GOTO LADR_0x00F8
LADR_0x0079:
    BTFSC RING_in        ; if RING == 1:
      GOTO LADR_0x0077   ;   GOTO LADR_0x0077

    BCF TIP_out          ; TIP = 0
    MOVLW LADR_0x0080    ; JumpBack = LADR_0x0080
    MOVWF JumpBack

    ; loop until RING goes high or timeout
LADR_0x007E:
    BTFSC TMR0,7         ; if TMR0[7] == 1:
      GOTO LADR_0x00F8   ;   GOTO LADR_0x00F8
LADR_0x0080:
    BTFSS TIP_in         ; if TIP == 0:
      GOTO LADR_0x0116   ;   GOTO LADR_0x0116
    BTFSS RING_in        ; if RING == 0:
      GOTO LADR_0x007E   ;   GOTO LADR_0x007E

    DECFSZ LRAM_0x0B,F   ; LRAM_0x0B -= 1
      GOTO LADR_0x0071   ; if LRAM_0x0B != 0: GOTO LADR_0x0071
    BCF StateFlags,3     ; StateFlags[3] = 0

    MOVLW LADR_0x0059    ; JumpBack = LADR_0x0059
    MOVWF JumpBack
    CLRWDT               ; reset watchdog
    GOTO LADR_0x00F6

LADR_0x008B:
    BSF RING_out         ; RING = 1
    MOVLW LADR_0x0090    ; JumpBack = LADR_0x0090
    MOVWF JumpBack

    ; loop until TIP goes low or timeout
LADR_0x008E:
    BTFSC TMR0,7         ; if TMR0[7] == 1:
      GOTO LADR_0x00F8   ;   GOTO LADR_0x00F8
LADR_0x0090:
    BTFSC TIP_in         ; if TIP == 1:
      GOTO LADR_0x008E   ;   GOTO LADR_0x008E

    BCF RING_out         ; RING = 0
    MOVLW LADR_0x0097    ; JumpBack = LADR_0x0097
    MOVWF JumpBack

    ; loop until TIP goes high or timeout
LADR_0x0095:
    BTFSC TMR0,7         ; if TMR0[7] == 1:
      GOTO LADR_0x00F8   ;   GOTO LADR_0x00F8
LADR_0x0097:
    BTFSS RING_in        ; if RING == 0:
      GOTO LADR_0x0116   ;   GOTO LADR_0x0116
    BTFSS TIP_in         ; if TIP == 0:
      GOTO LADR_0x0095   ;   GOTO LADR_0x007E

    DECFSZ LRAM_0x0B,F   ; LRAM_0x0B -= 1
      GOTO LADR_0x0071   ; if LRAM_0x0B != 0: GOTO LADR_0x0071
    BCF StateFlags,3     ; StateFlags[3] = 0
    MOVLW LADR_0x0059    ; JumpBack = LADR_0x0059
    MOVWF JumpBack
    CLRWDT               ; reset watchdog
    GOTO LADR_0x00F6

LADR_0x00A2:
    BSF StateFlags,0     ; StateFlags[0] = 1

    MOVLW 0x1E           ; TMR0 = 0x1E
    MOVWF TMR0

    MOVLW 0x08           ; LRAM_0x09 = 0x08
    MOVWF LRAM_0x09

    MOVF LRAM_0x0D,W     ; W = (LRAM_0x0D & 0x0E) ^ 0x0E
    ANDLW 0x0E
    XORLW 0x0E
    BTFSC STATUS,Z       ; if STATUS.Z == 1 (W == 0):
      BSF Ser_CTS        ;   CTS = 1

    MOVF JumpBack,W      ; GOTO JumpBack
    MOVWF PCL

LADR_0x00AE:
    RRF LRAM_0x08,F      ; LRAM_0x08 = LRAM_0x08 >> 1
    BCF LRAM_0x08,7      ; initially set bit to 0, if TX=0, then set high
    BTFSS Ser_TX         ; if TX == 0:
      BSF LRAM_0x08,7    ;   LRAM_0x08 |= 0'b1000_0000

    MOVF JumpBack,W
    DECFSZ LRAM_0x09,F   ; LRAM_0x08 -= 1
      MOVWF PCL          ; if LRAM_0x09 != 0: GOTO JumpBack

    MOVF LRAM_0x0E,W     ; FSR = LRAM_0x0E | 0xF0
    IORLW 0xF0
    MOVWF FSR

    MOVF LRAM_0x08,W     ; INDF = LRAM_0x08
    MOVWF INDF

    INCF LRAM_0x0E,F     ; LRAM_0x0E += 1
    INCF LRAM_0x0D,F     ; LRAM_0x0D += 1

    BTFSC LRAM_0x0D,4    ; if LRAM_0x0D[4] == 1:
      BSF StateFlags,5   ;   StateFlags[5] = 1

    BCF StateFlags,4     ; StateFlags[4] = 0
    BCF StateFlags,0     ; StateFlags[0] = 0

    CLRWDT               ; reset watchdog
    MOVF JumpBack,W      ; GOTO JumpBack
    MOVWF PCL

LADR_0x00C3:
    BSF StateFlags,1     ; StateFlags[1] = 1
    BSF Ser_RX           ; RX = 1

    MOVF LRAM_0x0F,W     ; FSR = LRAM_0x0F | 0xF0
    IORLW 0xF0
    MOVWF FSR

    MOVF INDF,W          ; LRAM_0x08 = INDF
    MOVWF LRAM_0x08

    INCF LRAM_0x0F,F     ; LRAM_0x0F += 1
    DECF LRAM_0x0D,F     ; LRAM_0x0D -= 1
    BTFSC STATUS,Z       ; if STATUS.Z == 1 (W == 0):
      BSF StateFlags,4   ;   StateFlags[4] = 1
    BCF StateFlags,5     ; StateFlags[5] = 0

    MOVLW 0x08           ; LRAM_0x09 = 0x08
    MOVWF LRAM_0x09

    MOVF JumpBack,W
    MOVWF PCL            ; GOTO JumpBack

LADR_0x00D3:
    BTFSC StateFlags,2   ; if StateFlags[2] == 1:
      GOTO LADR_0x00DF   ;   GOTO LADR_0x00DF
    RRF LRAM_0x08,F      ; STATUS.C = LRAM_0x08[0], LRAM_0x08 = LRAM_0x08 >> 1
    BTFSC STATUS,C       ; if STATUS.C == 1:
      BCF Ser_RX         ;   RX = 0
    BTFSS STATUS,C       ; if STATUS.C == 0:
      BSF Ser_RX         ;   RX = 1
    MOVF JumpBack,W
    DECFSZ LRAM_0x09,F   ; LRAM_0x09 -= 1
      MOVWF PCL          ; if LRAM_0x09 != 0: GOTO JumpBack
    BSF StateFlags,2     ; StateFlags[2] = 1
    MOVWF PCL            ; GOTO JumpBack
LADR_0x00DF:
    BCF Ser_RX           ; RX = 0

    BCF StateFlags,1     ; StateFlags[1] = 0
    BCF StateFlags,2     ; StateFlags[2] = 0

    CLRWDT               ; reset watchdog
    MOVF JumpBack,W
    MOVWF PCL            ; GOTO JumpBack

LADR_0x00E5:
    BTFSS TMR0,7         ; delay
      GOTO LADR_0x00E5
LADR_0x00E7:             ; likely a timeout case from gotos above
    BTFSS TMR0,4         ; if TMR0[4] == 0:
      GOTO LADR_0x00E7   ;   GOTO LADR_0x00E7

    MOVLW 0x2E           ; TMR0 = 0x2E
    MOVWF TMR0

    BTFSC StateFlags,1   ; if StateFlags[1] == 1:
      GOTO LADR_0x00D3   ;   GOTO LADR_0x00D3

    BTFSS StateFlags,4   ; if StateFlags[4] == 0:
      GOTO LADR_0x00C3   ;   GOTO LADR_0x00C3

    MOVF JumpBack,W
    BTFSC StateFlags,3   ; if StateFlags[3] == 1:
      MOVWF PCL          ;  GOTO JumpBack

    BTFSC TIP_in         ; if TIP == 0 || RING == 0:
      BTFSS RING_in
        GOTO LADR_0x0006 ;  GOTO LADR_0x0006
    GOTO LADR_0x0109

; wait for TMR0[7] to be set
; while (TMR0[7] == 0) {}
LADR_0x00F6:
    BTFSS TMR0,7
      GOTO LADR_0x00F6

LADR_0x00F8:
    BTFSS TMR0,4         ; if TMR0[4] == 0:
      GOTO LADR_0x00F8   ;   GOTO LADR_0x00F8

    MOVLW 0x2E           ; TMR0 = 0x2E
    MOVWF TMR0

    BTFSC StateFlags,0   ; if StateFlags == 1:
      GOTO LADR_0x00AE   ;   GOTO LADR_0x00AE

    MOVLW 0x66           ; TMR0 = 0x66
    MOVWF TMR0

    BTFSC Ser_TX         ; if TX == 1:
      GOTO LADR_0x00A2   ;   GOTO LADR_0x00A2

    MOVF JumpBack,W
    BTFSC StateFlags,3  ; if StateFlags[3] == 1:
      MOVWF PCL         ;   GOTO JumpBack

    MOVF JumpBack,W
    BTFSS StateFlags,4   ; if StateFlags[4] == 0:
      GOTO LADR_0x0059   ;   GOTO LADR_0x0059
    GOTO LADR_0x0109     ; useless

LADR_0x0109:
    CLRWDT               ; reset watchdog

    MOVLW LADR_0x0059    ; JumpBack = LADR_0x0059
    MOVWF JumpBack

    BSF DebugPin         ; PORTB[7] = 1

    BTFSC Ser_TX         ; if TX == 1:
      GOTO LADR_0x00A2   ;   GOTO LADR_0x00A2

    MOVLW LADR_0x0006    ; JumpBack = LADR_0x0006
    MOVWF JumpBack

    BCF DebugPin         ; PORTB[7] = 0

    BTFSC TIP_in         ; if TIP == 0 || RING == 0:
      BTFSS RING_in
        GOTO LADR_0x0006 ;   GOTO LADR_0x0006
    GOTO LADR_0x0109

LADR_0x0116:
    BSF Ser_CTS          ; CTS = 1
    BSF Ser_RX           ; RX = 1
LADR_0x0118:
    CLRWDT               ; reset watchdog
    BTFSC RING_in        ; if RING == 0 || TIP == 0:
      BTFSS TIP_in
        GOTO LADR_0x0118 ;   GOTO LADR_0x0118
    GOTO Initialize

ResetVector: ; 0x011D
    MOVLW 0x05           ; TRISA = b'00000101: RA0=input, RA1=output, RA2=input, RA3=output
    TRIS PORTA

    MOVLW 0x01           ; TRISB = b'00000001': RB0=input, RB1=output, RB2=output, RB[3-7]=output
    TRIS PORTB

    MOVLW LADR_0x0059    ; JumpBack = LADR_0x0059
    MOVWF JumpBack

    MOVLW 0x0E           ; OPTION = b'00001110': T0CS=0 (CLKOUT), T0SE=0 (low->high transition), PSA=1 (WDT), PS<2:0>=110 (1:64)
    OPTION

    MOVLW 0x2E           ; TMR0 = 0x2E
    MOVWF TMR0

Initialize: ; 0x0127
    CLRW                 ; STATUS = 0
    MOVWF STATUS

    ; initialize variables
    MOVLW 0x11           ; StateFlags[4] = 1, StateFlags[0] = 1
    MOVWF StateFlags
    CLRF LRAM_0x08       ; LRAM_0x08 = 0x00
    CLRF LRAM_0x09       ; LRAM_0x09 = 0x00
    CLRF LRAM_0x0A       ; LRAM_0x0A = 0x00
    CLRF LRAM_0x0B       ; LRAM_0x0B = 0x00
    MOVLW 0x10
    MOVWF LRAM_0x0E      ; LRAM_0x0E = 0x10
    MOVWF LRAM_0x0F      ; LRAM_0x0F = 0x10
    CLRF LRAM_0x0D       ; LRAM_0x0D = 0x00

    ; set all output pins low
    BCF TIP_out          ; TIP = 0
    BCF RING_out         ; RING = 0
    BCF Ser_RX           ; RX = 0
    BCF Ser_CTS          ; CTS_CD = 0
    GOTO LADR_0x0109

    ; Reset vector
    Org 0x1ff
    GOTO ResetVector

    End
