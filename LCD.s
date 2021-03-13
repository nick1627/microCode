#include <xc.inc>

global  LCDSetup, LCDWrite

psect	udata_acs   ; named variables in access ram
LCD_cnt_l:	ds 1	; reserve 1 byte for variable LCD_cnt_l
LCD_cnt_h:	ds 1	; reserve 1 byte for variable LCD_cnt_h
LCD_cnt_ms:	ds 1	; reserve 1 byte for ms counter
LCD_tmp:	ds 1	; reserve 1 byte for temporary use
LCDcounter:	ds 1	; reserve 1 byte for counting through message
;myMessage:	ds 1
myMessageL:	ds 1

LCD_E	EQU 5	; LCD enable bit
LCD_RS	EQU 4	; LCD register select bi
	
psect	udata_bank4 ; 
myArray:	ds 12
    
;psect	udata_acs_ovr,space=1,ovrld,class=COMRAM
;LCD_hex_tmp:	ds 1    ; reserve 1 byte for variable LCD_hex_tmp
;
;	

psect	data		; Message Tables
myMessage: 
	db	'H','e','l','l','o',' ','W','o','r','l','d','!'
; 	l1   EQU 13	; length of data
	align	2

psect	LCDcode,class=CODE

;=======LCD Setup===============================================================
LCDSetup:
	NOP
	clrf    LATB, A
	movlw   11000000B	; RB0:5 all outputs
	movwf	TRISB, A
	movlw   40
	call	LCD_delay_ms	; wait 40ms for LCD to start up properly
	movlw	00110000B	; Function set 4-bit
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00101000B	; 2 line display 5x8 dot characters
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00101000B	; repeat, 2 line display 5x8 dot characters
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00001111B	; display on, cursor on, blinking on
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00000001B	; display clear
	call	LCD_Send_Byte_I
	movlw	2		; wait 2ms
	call	LCD_delay_ms
	movlw	00000110B	; entry mode incr by 1 no shift
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	return

;=======LCD Menu================================================================
LCDWrite:
	; Writes message denoted by number option stored in W
;	movff	welcome, myMessage
	movlw	12
	movwf	myMessageL, A
;	movff	l1, myMessageL
	call	LCDWriteTxt
	return 

;=======Main Programme==========================================================
	
LCDWriteTxt:	    
	; Message stored in PM myMessage with length myMessageL
	call	loadMessage		    ; load message in myMessage
	movff	myMessageL, LCDcounter, A   ; bytes to write
	lfsr	2, myArray
writeLp:
	movf    POSTINC2, W, A
	call    LCDDataSend		    ; Send byte in W
	decfsz  LCDcounter, A
	bra	writeLp
	return
	
loadMessage:
	; Load message array in PM (loc in FSR2) to FSR2
	movlw	low highword(myMessage)	    ; address of data in PM
	movwf	TBLPTRU, A		    ; load upper bits to TBLPTRU
	movlw	high(myMessage)		    ; address of data in PM
	movwf	TBLPTRH, A		    ; load high byte to TBLPTRH
	movlw	low(myMessage)		    ; address of data in PM
	movwf	TBLPTRL, A		    ; load low byte to TBLPTRL
	movff	myMessageL, LCDcounter, A   ; bytes to read
	lfsr	2, myArray
loadLp: 
	tblrd*+				; 1-byte from PM to TABLAT, inc TBLPRT
	movff	TABLAT, POSTINC2	; 1-byte from TABLAT to FSR2, inc FSR2	
	decfsz	LCDcounter, A
	bra	loadLp
	return 

LCD_Send_Byte_I:	    ; Transmits byte stored in W to instruction reg
	movwf   LCD_tmp, A
	swapf   LCD_tmp, W, A   ; swap nibbles, high nibble goes first
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bcf	LATB, LCD_RS, A	; Instruction write clear RS bit
	call    LCD_Enable  ; Pulse enable Bit 
	movf	LCD_tmp, W, A   ; swap nibbles, now do low nibble
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bcf	LATB, LCD_RS, A	; Instruction write clear RS bit
        call    LCD_Enable  ; Pulse enable Bit 
	return

LCDDataSend:	   
	; Transmits byte stored in W to data reg
	movwf   LCD_tmp, A
	swapf   LCD_tmp, W, A	; swap nibbles, high nibble goes first
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bsf	LATB, LCD_RS, A	; Data write set RS bit
	call    LCD_Enable  ; Pulse enable Bit 
	movf	LCD_tmp, W, A	; swap nibbles, now do low nibble
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bsf	LATB, LCD_RS, A	; Data write set RS bit	    
        call    LCD_Enable  ; Pulse enable Bit 
	movlw	10	    ; delay 40us
	call	LCD_delay_x4us
	return
	
LCD_Enable:	    
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
LCD_delay_ms:		    ; delay given in ms in W
	movwf	LCD_cnt_ms, A
lcdlp2:	movlw	250	    ; 1 ms delay
	call	LCD_delay_x4us	
	decfsz	LCD_cnt_ms, A
	bra	lcdlp2
	return
    
LCD_delay_x4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	LCD_cnt_l, A	; now need to multiply by 16
	swapf   LCD_cnt_l, F, A	; swap nibbles
	movlw	0x0f	    
	andwf	LCD_cnt_l, W, A ; move low nibble to W
	movwf	LCD_cnt_h, A	; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	LCD_cnt_l, F, A ; keep high nibble in LCD_cnt_l
	call	LCD_delay
	return

LCD_delay:			; delay routine	4 instruction loop == 250ns	    
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