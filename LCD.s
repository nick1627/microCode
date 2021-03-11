#include <xc.inc>

global  LCD_Setup, LCD_Write_Message, LCD_Write_Hex

psect	udata_acs   ; named variables in access ram
LCD_cnt_l:	ds 1	; reserve 1 byte for variable LCD_cnt_l
LCD_cnt_h:	ds 1	; reserve 1 byte for variable LCD_cnt_h
LCD_cnt_ms:	ds 1	; reserve 1 byte for ms counter
LCD_tmp:	ds 1	; reserve 1 byte for temporary use
LCD_counter:	ds 1	; reserve 1 byte for counting through nessage

PSECT	udata_acs_ovr,space=1,ovrld,class=COMRAM
LCD_hex_tmp:	ds 1    ; reserve 1 byte for variable LCD_hex_tmp

	LCD_E	EQU 5	; LCD enable bit
    	LCD_RS	EQU 4	; LCD register select bit

psect	lcd_code,class=CODE
    
LCD_Setup:
	clrf    LATB, A
	movlw   11000000B	    ; RB0:5 all outputs
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

LCD_Write_Hex:			; Writes byte stored in W as hex
	movwf	LCD_hex_tmp, A
	swapf	LCD_hex_tmp, W, A	; high nibble first
	call	LCD_Hex_Nib
	movf	LCD_hex_tmp, W, A	; then low nibble
LCD_Hex_Nib:			; writes low nibble as hex character
	andlw	0x0F
	movwf	LCD_tmp, A
	movlw	0x0A
	cpfslt	LCD_tmp, A
	addlw	0x07		; number is greater than 9 
	addlw	0x26
	addwf	LCD_tmp, W, A
	call	LCD_Send_Byte_D ; write out ascii
	return	
	
LCD_Write_Message:	    ; Message stored at FSR2, length stored in W
	movwf   LCD_counter, A
LCD_Loop_message:
	movf    POSTINC2, W, A
	call    LCD_Send_Byte_D
	decfsz  LCD_counter, A
	bra	LCD_Loop_message
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

LCD_Send_Byte_D:	    ; Transmits byte stored in W to data reg
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

LCD_Enable:	    ; pulse enable bit LCD_E for 500ns
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


end
;	
;	
;	
;#include <xc.inc>
;
;extrn	LCD_Setup, LCD_Write_Message, LCD_Clear
;	
;psect	udata_acs   ; reserve data space in access ram
;counter:    ds 1    ; reserve one byte for a counter variable
;delay_count:ds 1    ; reserve one byte for counter in the delay routine
;delayC1:    ds 1
;delayC2:    ds 1
;delayC3:    ds 1
;
;psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
;myArray:    ds 0x80 ; reserve 128 bytes for message data
;lineSpace:  ds	24
;portInput:  ds 1
;
;psect	data    
;	; ******* myTable, data in programme memory, and its length *****
;myTable:
;	db	'H','e','l','l','o',' ','W','o','r','l','d','!',0x0a
;					; message, plus carriage return
;	myTable_l   EQU	13	; length of data
;	align	2
;    
;psect	code, abs	
;rst: 	org 0x0
; 	goto	setup
;
;	; ******* Programme FLASH read Setup Code ***********************
;setup:	bcf	CFGS	; point to Flash program memory  
;	bsf	EEPGD 	; access Flash program memory
;	call	UART_Setup	; setup UART
;	call	LCD_Setup	; setup UART
;	setf	TRISD, A
;	goto	start
;	
;	; ******* Main programme ****************************************
;start: 	lfsr	0, myArray	; Load FSR0 with address in RAM	
;	movlw	low highword(myTable)	; address of data in PM
;	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
;	movlw	high(myTable)	; address of data in PM
;	movwf	TBLPTRH, A		; load high byte to TBLPTRH
;	movlw	low(myTable)	; address of data in PM
;	movwf	TBLPTRL, A		; load low byte to TBLPTRL
;	movlw	myTable_l	; bytes to read
;	movwf 	counter, A		; our counter register
;loop: 	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
;	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
;	decfsz	counter, A		; count down to zero
;	bra	loop		; keep going until finished
;		
;	movlw	myTable_l	; output message to UART
;	lfsr	2, myArray
;	call	UART_Transmit_Message
;
;	movlw	myTable_l	; output message to LCD
;	addlw	0xff		; don't send the final carriage return to LCD
;	lfsr	2, myArray
;	call	LCD_Write_Message
;	movlw	0x44
;	call	bigDelay
;	call	LCD_Clear
;	; call	flash 
;	;call	portWrite
;	call	secondLine
;	
;	goto	$		; goto current line in code
;
;secondLine: 
;    	lfsr	2, lineSpace
;	movlw	40		; put 40 ' ' in memory 
;	movwf	counter, A
;loops:	movlw	' '
;	movwf	POSTINC2
;	decfsz	counter, A
;	bra	loops
;	movlw	40	    	; output large space to LCD
;	lfsr	2, lineSpace
;	call	LCD_Write_Message
;	
;	movlw	myTable_l	; output text to LCD after space
;	addlw	0xff		; don't send the final carriage return to LCD
;	lfsr	2, myArray
;	call	LCD_Write_Message   ; text pushed to second row
;
;	return 
;	
;portWrite: 
;	;call	LCD_Clear 
;	movff	PORTD, portInput
;	movlw	1	; output message to LCD
;	lfsr	2, portInput
;	call	LCD_Write_Message
;	movlw	0x33
;	call	bigDelay
;	bra	portWrite
;	return 
;
;flash:  ; Subroutine that makes text flash 
;	movlw	0xff		; repeats 256 times
;	movwf	counter, A
;fLoop: 
;	call	LCD_Clear	; clear display
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
;	
;	; a delay subroutine if you need one, times around loop in delay_count
;delay:	decfsz	delay_count, A	; decrement until zero
;	bra	delay
;	return
;
;bigDelay: ; delay subroutine changing length with w
;	movwf	delayC1, A
;	movwf	delayC2, A
;	movwf	delayC3, A
;delay1: call	delay2
;	decfsz	delayC1, A
;	bra	delay1
;	return 
;delay2: call	delay3
;	decfsz	delayC2, A
;	bra	delay2
;	return 
;delay3: decfsz	delayC3, A
;	bra	delay3
;	return 
;
;	end	rst
