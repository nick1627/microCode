#include <xc.inc>

global  LCDSetup, LCDWrite

psect	udata_acs   ; named variables in access ram
LCD_cnt_l:	ds 1	; reserve 1 byte for variable LCD_cnt_l
LCD_cnt_h:	ds 1	; reserve 1 byte for variable LCD_cnt_h
LCD_cnt_ms:	ds 1	; reserve 1 byte for ms counter
LCD_tmp:	ds 1	; reserve 1 byte for temporary use
LCDcounter:	ds 1	; reserve 1 byte for counting through message
messageSel:	ds 1	; reserve 1 byte for message option number from W
    
LCD_E	EQU 5	; LCD enable bit
LCD_RS	EQU 4	; LCD register select bi
twoLine	EQU 56	; Number of bytes in 2 lines of 2x16 message 
	
psect	udata_bank4 ; 
myArray:	ds twoLine  ; reserve 56 bytes (length of 2 lines) for message
    
;psect	udata_acs_ovr,space=1,ovrld,class=COMRAM
;LCD_hex_tmp:	ds 1    ; reserve 1 byte for variable LCD_hex_tmp
;
;	

psect	data		; Message Tables
;myMessage:	ds 2

secondLine: 
	db	' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' '

helloM: 
	db	'-','-','K','E','Y','P','A','D',' ','L','O','C','K','-','-','-'
	db	' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' '
	db	' ','B','Y',' ','N','I','C','K',' ','&',' ','H','A','N','A',' '

enterCodeM: 
	db	'E','n','t','e','r',' ','c','o','d','e',' ','t','o',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' '
	db	'u','n','l','o','c','k','!',' ',' ',' ',' ',' ',' ',' ',' ',' '

oneKeyM: 
	db	'E','n','t','e','r',' ','c','o','d','e',':',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
	db	' ',' ',' ',' ',' ',' ',' ',' '
	db	'*',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
	
	align	2

;=======LCD Setup===============================================================
psect	LCDcode,class=CODE
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
	movwf	messageSel, A	    ; Move option in W to messageSel	
	movlw	0		    ; Code for initialisation message
	cpfseq	messageSel, A		     
	goto	next;$ + 5		    ; If different, skip to next check 
	#define myMessage helloM
;	movff	helloM, myMessage
	call	LCDWriteTxt
	return 

next:	movlw	1		    ; Code for enter code message
	cpfseq	messageSel, A		     
	goto	back;$ + 5		    ; If different, skip to next check 
	#define myMessage enterCodeM
	call	LCDWriteTxt
	return
back:	return 
    
;=======Main Programme==========================================================
	
LCDWriteTxt:	    
	; Writes message stored in myMessage with length twoLine to LCD
	call	loadMessage		    ; load message in myMessage
	movff	twoLine, LCDcounter, A   ; bytes to write
	lfsr	2, myArray
	call	writeMessage
	return
	
loadMessage:
	; Load message array in PM (loc in FSR2) to FSR2
	movlw	low highword(myMessage)	    ; address of data in PM
	movwf	TBLPTRU, A		    ; load upper bits to TBLPTRU
	movlw	high(myMessage)		    ; address of data in PM
	movwf	TBLPTRH, A		    ; load high byte to TBLPTRH
	movlw	low(myMessage)		    ; address of data in PM
	movwf	TBLPTRL, A		    ; load low byte to TBLPTRL
	movff	twoLine, LCDcounter, A   ; bytes to read
	lfsr	2, myArray
loadLp: 
	tblrd*+				; 1-byte from PM to TABLAT, inc TBLPRT
	movff	TABLAT, POSTINC2	; 1-byte from TABLAT to FSR2, inc FSR2	
	decfsz	LCDcounter, A
	bra	loadLp
	return 

writeMessage: 
	; Sends message stored in FSR2 with message length in LCDcounter
	movf    POSTINC2, W, A
	call    LCDDataSend		    ; Send byte in W
	decfsz  LCDcounter, A
	bra	writeMessage
	return
	
LCDClear:
	; Clears the LCD Screen 
	movlw	00000001B		    ; clear display instruction
	call	LCDInstructionSend
	movlw	2			    ; wair 2ms
	call LCDDelayMs
	return 

;secondLine: 
;    	lfsr	2, myArray
;	movlw	36		; put 36 ' ' in PM 
;	movwf	LCDcounter, A
;secondLp:	
;	movlw	' '
;	movwf	POSTINC2, A
;	decfsz	LCDcounter, A
;	bra	secondLp
;	movlw	36	    	; output large space to LCD
;	lfsr	2, myArray
;	call	writeMessage
;	return 
;
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
	bcf	LATB, LCD_RS, A	; Instruction write clear RS bit
	call    LCDEnable  ; Pulse enable Bit 
	movf	LCD_tmp, W, A   ; swap nibbles, now do low nibble
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bcf	LATB, LCD_RS, A	; Instruction write clear RS bit
        call    LCDEnable  ; Pulse enable Bit 
	return

LCDDataSend:	   
	; Transmits byte stored in W to data reg
	movwf   LCD_tmp, A
	swapf   LCD_tmp, W, A	; swap nibbles, high nibble goes first
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bsf	LATB, LCD_RS, A	; Data write set RS bit
	call    LCDEnable  ; Pulse enable Bit 
	movf	LCD_tmp, W, A	; swap nibbles, now do low nibble
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bsf	LATB, LCD_RS, A	; Data write set RS bit	    
        call    LCDEnable  ; Pulse enable Bit 
	movlw	10	    ; delay 40us
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
	bsf	LATB, LCD_E, A	    ; Take enable high
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bcf	LATB, LCD_E, A	    ; Writes data to LCD
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

	
;LCD_Write_Hex:			; Writes byte stored in W as hex
;	movwf	LCD_hex_tmp, A
;	swapf	LCD_hex_tmp, W, A	; high nibble first
;	call	LCD_Hex_Nib
;	movf	LCD_hex_tmp, W, A	; then low nibble
;LCD_Hex_Nib:			; writes low nibble as hex character
;	andlw	0x0F
;	movwf	LCD_tmp, A
;	movlw	0x0A
;	cpfslt	LCD_tmp, A
;	addlw	0x07		; number is greater than 9 
;	addlw	0x26
;	addwf	LCD_tmp, W, A
;	call	LCD_Send_Byte_D ; write out ascii
;	return	
;	

end