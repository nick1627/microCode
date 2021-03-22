#include <xc.inc>

global  LCDSetup, LCDWrite

psect	udata_acs;================================named variables in access ram=
LCD_cnt_l:	ds 1	; reserve 1 byte for variable LCD_cnt_l
LCD_cnt_h:	ds 1	; reserve 1 byte for variable LCD_cnt_h
LCD_cnt_ms:	ds 1	; reserve 1 byte for ms counter
LCD_tmp:	ds 1	; reserve 1 byte for temporary use
LCDcounter:	ds 1	; reserve 1 byte for counting through message
messageSel:	ds 2	; reserve 1 byte for message option number from W
    
LCDE		EQU 5	; LCD enable bit
LCDRS		EQU 4	; LCD register select bi
twoLine		EQU 56	; Number of bytes in 2 lines of 2x16 message 

psect	data;============================================message display stored=
myMessage: 
; 0 - initialisation
	db	'-','-','K','E','Y','P','A','D',' ','L','O','C','K','-','-','-'
	db	' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' '
	db	' ','B','Y',' ','N','I','C','K',' ','&',' ','H','A','N','A',' '
; 1 - dormant
	db	'E','n','t','e','r',' ','c','o','d','e',' ','t','o',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' '
	db	'u','n','l','o','c','k','!',' ',' ',' ',' ',' ',' ',' ',' ',' '
; 2 - entered code (1)
	db	'E','n','t','e','r',' ','c','o','d','e',':',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' '
	db	'*',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
; 3 - entered code (2) 
	db	'E','n','t','e','r',' ','c','o','d','e',':',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' '
	db	'*','*',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
; 4 - entered code (3)
	db	'E','n','t','e','r',' ','c','o','d','e',':',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' '
	db	'*','*','*',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
; 5 - entered code (4)
	db	'E','n','t','e','r',' ','c','o','d','e',':',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' '
	db	'*','*','*','*',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
; 6 - correct passcode 
	db	'E','n','t','e','r',' ','c','o','d','e',':',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' '
	db	'-','-','-','-','-','-','O','P','E','N','-','-','-','-','-','-'
; 7 - incorrect passcode
	db	'E','n','t','e','r',' ','c','o','d','e',':',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ','I','N','C','O','R','R','E','C','T',' ',' ',' ',' '
; 8 - out of time 
	db	' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ','-','T','I','M','E','O','U','T','-',' ',' ',' ',' '
; 9 - options
	db	'O','p','t','i','o','n','s',':',' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
; 10 - change code
	db	'O','p','t','i','o','n','s',':',' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' '
	db	'C','-','C','h','a','n','g','e',' ','C','o','d','e',' ',' ',' '
; 11 - change alarm
	db	'O','p','t','i','o','n','s',':',' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' '
	db	'A','-','A','l','a','r','m',' ','O','n','/','O','f','f',' ',' '
; 12 - alarm on 
	db	'A','l','a','r','m',':',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ','-','O','N','-',' ',' ',' ',' ',' ',' '
; 13 - alarm off 
	db	'A','l','a','r','m',':',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ','-','O','F','F','-',' ',' ',' ',' ',' ',' '
; 14 - enter new code
	db	'E','n','t','e','r',' ','n','e','w',' ','c','o','d','e',':',' '
	db	' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
; 15 - new code set 
	db	'E','n','t','e','r',' ','n','e','w',' ','c','o','d','e',':',' '
	db	' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' '
	db	'-','-','N','E','W',' ','C','O','D','E',' ','S','E','T','-','-'
; 16 - alarm screen 1
	db	0x11,0x11,'U','N','A','U','T','H','O','R','I','S','E','D',0x11,0x11
	db	' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' '
	db	0x11,0x11,0x11,0x11,0x11,'A','C','C','E','S','S',0x11,0x11,0x11,0x11,0x11
; 17 - alarm screen 2
	db	' ',' ','U','N','A','U','T','H','O','R','I','S','E','D',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ','A','C','C','E','S','S',' ',' ',' ',' ',' '
	
	align	2		; Align instruction and location in PM again 

psect	LCDcode, class=CODE
	
;=======LCD Setup===============================================================
LCDSetup:
	clrf    LATB, A
	movlw   11000000B	; RB0:5 all outputs
	movwf	TRISB, A
	movlw   40
	call	LCDDelayMs	; wait 40ms for LCD to start up properly
	movlw	00110000B	; Function set 4-bit
	call	LCDInstructionSend
	movlw	10		; wait 40us
	call	LCDDelayX4us
	movlw	00101000B	; 2 line display 5x8 dot characters
	call	LCDInstructionSend
	movlw	10		; wait 40us
	call	LCDDelayX4us
	movlw	00101000B	; repeat, 2 line display 5x8 dot characters
	call	LCDInstructionSend
	movlw	10		; wait 40us
	call	LCDDelayX4us
	movlw	00001111B	; display on, cursor on, blinking on
	call	LCDInstructionSend
	movlw	10		; wait 40us
	call	LCDDelayX4us
	movlw	00000001B	; display clear
	call	LCDInstructionSend
	movlw	2		; wait 2ms
	call	LCDDelayMs
	movlw	00000110B	; entry mode incr by 1 no shift
	call	LCDInstructionSend
	movlw	10		; wait 40us
	call	LCDDelayX4us
	return

;=======LCD Menu================================================================
LCDWrite:	
; Writes message denoted by number option stored in W
	mullw	twoLine		    ; option x 56 bytes
	movff	PRODL, messageSel   ; store 16-bit product in messageSel
	movff	PRODH, messageSel+1
	call	LCDClear	    ; clear current message 
	call	loadMessage	    ; load message at relative position to TABLE
	movlw	twoLine		    
	movwf	LCDcounter, A	    ; set # bytes to send
	call	writeMessage	    ; send # bytes
	
	return 

;=======Main Programme==========================================================
loadMessage:
; Load message at messageSel to TABLE 

	movlw	low(myMessage)		    
	addwf	messageSel, A		    ; add relative loc to memory loc
	movff	messageSel, TBLPTRL, A	    ; load low byte to TBLPTRL	
	movlw	high(myMessage)		
	addwfc	messageSel+1, A		    ; add relative loc w/ carry over 
	movff	messageSel+1, TBLPTRH, A    ; load high byte to TBLPTRH
	movlw	low highword(myMessage)	    ; address of data in PM
	movwf	TBLPTRU, A		    ; load upper bits to TBLPTRU as is
	
	return

writeMessage: 
; Send message in TABLE to LCD 
	tblrd*+				    ; data to table, inc TABLE
	movf	TABLAT, W, A		    ; table to W
	call	LCDDataSend		    ; send byte in W	
	decfsz	LCDcounter, A		    ; loop to send # bytes 
	bra	writeMessage
	return 
	
LCDClear:
; Clears the LCD Screen 
	movlw	00000001B		    ; clear display instruction
	call	LCDInstructionSend
	movlw	2			    ; wait 2ms
	call	LCDDelayMs
	return 

;flash:  ; Subroutine that makes text flash 
;	movlw	0xff		; repeats 256 times
;	movwf	counter, A
;fLoop: 
;;	call	LCD_Clear	; clear display
;	movlw	0x33
;	call	bigDelay	; wait
;	movlw	myTable_l	; output message to LCD
;	addlw	0xff		; don't send the final carriage return to LCD
;	lfsr	2, myArray
;	call	LCD_Write_Message   ; write message
;	movlw	0x33
;	call	bigDelay	; wait
;	decfsz	counter, A
;	bra	fLoop
;	return
	
LCDInstructionSend:	    ; Transmits byte stored in W to instruction reg
	movwf   LCD_tmp, A
	swapf   LCD_tmp, W, A   ; swap nibbles, high nibble goes first
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bcf	LATB, LCDRS, A	; Instruction write clear RS bit
	call    LCDEnable  ; Pulse enable Bit 
	movf	LCD_tmp, W, A   ; swap nibbles, now do low nibble
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bcf	LATB, LCDRS, A	; Instruction write clear RS bit
        call    LCDEnable  ; Pulse enable Bit 
	return

LCDDataSend:	   
	; Transmits byte stored in W to data reg
	movwf   LCD_tmp, A
	swapf   LCD_tmp, W, A	; swap nibbles, high nibble goes first
	andlw   0x0f		; select just low nibble
	movwf   LATB, A		; output data bits to LCD
	bsf	LATB, LCDRS, A	; Data write set RS bit
	call    LCDEnable	; Pulse enable Bit 
	movf	LCD_tmp, W, A	; swap nibbles, now do low nibble
	andlw   0x0f		; select just low nibble
	movwf   LATB, A		; output data bits to LCD
	bsf	LATB, LCDRS, A	; Data write set RS bit	    
        call    LCDEnable	; Pulse enable Bit 
	movlw	10		; delay 40us
	call	LCDDelayX4us
	return
	
LCDEnable:	    
	; Pulse enable bit LCD_E for 500ns
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bsf	LATB, LCDE, A	    ; Take enable high
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bcf	LATB, LCDE, A	    ; Writes data to LCD
	return
    
; ** a few delay routines below here as LCD timing can be quite critical ****
LCDDelayMs:		    ; delay given in ms in W
	movwf	LCD_cnt_ms, A
lcdlp2:	movlw	250	    ; 1 ms delay
	call	LCDDelayX4us	
	decfsz	LCD_cnt_ms, A
	bra	lcdlp2
	return
    
LCDDelayX4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	LCD_cnt_l, A	; now need to multiply by 16
	swapf   LCD_cnt_l, F, A	; swap nibbles
	movlw	0x0f	    
	andwf	LCD_cnt_l, W, A ; move low nibble to W
	movwf	LCD_cnt_h, A	; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	LCD_cnt_l, F, A ; keep high nibble in LCD_cnt_l
	call	LCDDelay
	return

LCDDelay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
lcdlp1:	decf 	LCD_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	LCD_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	lcdlp1		; carry, then loop again
	return			; carry reset so return

