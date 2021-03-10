#include <xc.inc>

global	keypadSetup, intKey
    
psect	udata_acs	; reserve data space in access ram
key:		ds 1    ; reserve one byte for keypad output
delay_cnt1:	ds 1    ; reserve 3 bytes for counter in the delay routine
delay_cnt2:	ds 1    
delay_cnt3:	ds 1    
delay_09:	ds 1	; reserve 1 byte for keypad delay
counter:	ds 1	; running counter 
output:		ds 1    ; output slot
keyPressed:	ds 1	; number of keys pressed so far
    
psect	udata_bank4	; reserve data anywhere in RAM (here at 0x400)
myKeycodes:	ds 0x80 ; reserve 128 bytes for keycode data

psect	data		; Loaded to FSR0 later
keycode:
	db	01110111B, 10110111B, 11010111B, 11100111B
	db	01111011B, 10111011B, 11011011B, 11101011B
	db	01111101B, 10111101B, 11011101B, 11101011B
	db	01111110B, 10111110B, 11011110B, 11101110B
	keycode_l   EQU	16	    ; length of data
	align	2
decoded:
	db	'C', 10110111B, 11010111B, 11100111B
	db	01111011B, 10111011B, 11011011B, 11101011B
	db	01111101B, 10111101B, 11011101B, 11101011B
	db	01111110B, 10111110B, 11011110B, '1'
	align	2
;===============================================================================
psect	keypad_code, class=CODE
;	Keypad @PORTE [RE1>P7]
;	LED    @PORTD 
	
keypadSetup:
;	bsf	TMR0IE		; Enable timer0 interrupt
	bsf	GIE		; Enable all interrupts
	banksel PADCFG1		; Move bank to PADCFG1
	bsf	REPU		; Accesses PADCFG1
	clrf	LATE, A		; Write 0s to latch 
	call	load		; Load necessary keypad codes to PM
	return	
	
intKey:	
	incf	keyPressed, F, A
	call	read
	return	
	
;	btfss	TMR0IF		; check that this is timer0 interrupt
;	retfie	f		; if not then return
;	incf	keyPressed, F, A; increment keyPressed counter
;	call	read		; read key pressed 
;	bcf	TMR0IF		; clear interrupt flag
;	retfie	f		; fast return from interrupt

;=======Loading PM==============================================================
load: 	lfsr	0, myKeycodes	    ; Load FSR0 with address in RAM	
	movlw	low highword(keycode)	
	movwf	TBLPTRU, A	    ; load upper bits to TBLPTRU
	movlw	high(keycode)	
	movwf	TBLPTRH, A	    ; load high byte to TBLPTRH
	movlw	low(keycode)	
	movwf	TBLPTRL, A	    ; load low byte to TBLPTRL
	movlw	keycode_l	    ; bytes to read
	movwf 	counter, A	    
	movlw	0x09
	movwf	delay_09, A 
lLoop: 	tblrd*+			    ; one byte from PM to TABLAT, increment
	movff	TABLAT, POSTINC0    ; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A	    ; count down to zero
	bra	lLoop	
	goto	read
	
;=======Reading Keypad Inputs===================================================
read:
    	call	resetPorts	    ; 
	
	call	configRow
	call	readRow
	call	display
	
	call	configColumn
	call	readColumn 
	call	display
decode: 
	call 	keyCheck
	
	return
    
;=======Functional Sub-Routines=================================================
resetPorts: 
	clrf	PORTC, A

configRow: 
	movlw	0x0F		    ; 00001111
	movwf	TRISE, A	    ; 0-3 Inputs | 4-7 Outputs
	call	smallDelay
	movlw	0x0F
	movwf	PORTE, A	    ; 4-7 LOW
	call	smallDelay
	return

configColumn: 
    	movlw	0xF0		    ; 11110000
	movwf	TRISE, A	    ; 0-3 Outputs | 4-7 Inputs
	call	smallDelay
	movlw	0xF0
	movwf	PORTE, A	    ; 0-3 LOW
	call	smallDelay
	return
	
readRow:
	clrf	key, A		    ; Reset key output
	movff	PORTE, key, A	    ; Move row output to key
	return 
	
readColumn:
	movf	PORTE, W, A	    ; Read in Port-E Inputs to W
	addwf	key, A		    ; Add column output to key 
	return 

display: 
	movff	key, PORTC
	return
	
keyCheck: 
	movlw	11111111B	    ; Compare to 0xFF
	cpfseq	key, A		    ; (No key pressed) 
	goto	checkOne	    ; If different, skip to next check 
	return 
checkOne:	
	movlw	11011111B	    ; Code for 1 Button 
	cpfseq	key, A		    ;  
	goto	checkFour	    ; If different, skip to next check 
	movlw	1
	call	keyPress
	return 
checkFour:
	movlw	11101111B	    ; Code for 4 Button 
	cpfseq	key, A		    ;  
	goto	checkSeven	    ; If different, skip to next check 
	movlw	4
	call	keyPress
	return 
checkSeven:
	movlw	11110111B	    ; Code for 7 Button 
	cpfseq	key, A		    ;  
	goto	checkNine	    ; If different, its invaliid
	movlw	7
	call	keyPress
	return 
checkNine:
	movlw	01110111B	    ; Code for 9 Button 
	cpfseq	key, A		    ;  
	goto	checkA		    ; If different, its invaliid
	movlw	9
	call	keyPress
	return 
checkA:
	movlw	11111011B	    ; Code for A Button 
	cpfseq	key, A		    ;  
	goto	checkB		    ; If different, its invaliid
	movlw	10
	call	keyPress
	return 
checkB:
	movlw	01111011B	    ; Code for B Button 
	cpfseq	key, A		    ;  
	goto	checkC		    ; If different, its invaliid
	movlw	11
	call	keyPress
	return 
checkC:
	movlw	10111011B	    ; Code for C Button 
	cpfseq	key, A		    ;  
	goto	checkD		    ; If different, its invaliid
	movlw	12
	call	keyPress
	return 
checkD:
	movlw	10110111B	    ; Code for D Button 
	cpfseq	key, A		    ;  
	goto	other		    ; If different, its invaliid
	movlw	13
	call	keyPress
	return 
other:
	call	invalidPress	    
	return 

keyPress:   
	; displays W on PORT-D 
	movwf	PORTD, A
	call	bigDelay
	clrf	PORTD, A
	return 
	
invalidPress: 
	movlw	0xff
	call	keyPress
	return 

;=======Other Sub-Routines======================================================
smallDelay: 
	decfsz	delay_09, F, A	; decrement until zero
	bra	smallDelay
	movlw	0x09	
	movwf	delay_09, A
	return

bigDelay: 
	; Subroutine to add CASCADED 8-bit delay 
	movlw	0x22	
	movwf	delay_cnt1, A	    ; Initiate counter 
	movwf	delay_cnt2, A
	movwf	delay_cnt3, A
sLoop:	call	sLoop2
	decfsz	delay_cnt1, F, A	    ; Decrament from 256
	bra	sLoop	    
	return 
sLoop2: call	sLoop3
	decfsz	delay_cnt2, F, A
	bra	sLoop2
	return 
sLoop3: decfsz	delay_cnt3, F, A
	bra	sLoop3
	return 

	end 

