#include <xc.inc>

global	keypadSetup, intKey
    
psect	udata_acs	; reserve data space in access ram
key:		ds 1    ; reserve one byte for keypad output
delay09:	ds 1	; CONSTANT can I load with 09? *****************
counter:	ds 1	; running empty counter 
keyPressed:	ds 1	; number of keys pressed so far

    ; delete later
	delay_cnt1:	ds 1    ; reserve 3 bytes for counter in the delay routine
	delay_cnt2:	ds 1    
	delay_cnt3:	ds 1  
    
;===============================================================================
psect	keypad_code, class=CODE
;	[ Keypad @PORTE RE1>P7 ]
;	[ LED    @PORTD	       ]
	
keypadSetup:
;	bsf	TMR0IE		; Enable timer0 interrupt
	bsf	GIE		; Enable all interrupts
	banksel PADCFG1		; Move bank to PADCFG1
	bsf	REPU		; Accesses PADCFG1 for keypad 
	clrf	LATE, A		; Set Latch-E to 0 
	return	
	
intKey:	
	incf	keyPressed, F, A
	call	read
	return	
	
;=======Reading Keypad Inputs===================================================
read:	
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
	call	keypadDelay
	movlw	0x0F
	movwf	PORTE, A	    ; 4-7 LOW
	call	keypadDelay
	return

configColumn: 
    	movlw	0xF0		    ; 11110000
	movwf	TRISE, A	    ; 0-3 Outputs | 4-7 Inputs
	call	keypadDelay
	movlw	0xF0
	movwf	PORTE, A	    ; 0-3 LOW
	call	keypadDelay
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
	movlw	11101110B	    ; Code for 1 Button 
	cpfseq	key, A		    ;  
	goto	checkTwo	    ; If different, skip to next check 
	movlw	1
	call	keyPress
	return 
checkTwo:	
	movlw	11101101B	    ; Code for 1 Button 
	cpfseq	key, A		    ;  
	goto	checkThree	    ; If different, skip to next check 
	movlw	2
	call	keyPress
	return 
checkThree:	
	movlw	11101011B	    ; Code for 1 Button 
	cpfseq	key, A		    ;  
	goto	checkFour	    ; If different, skip to next check 
	movlw	3
	call	keyPress
	return 
checkFour:
	movlw	11011110B	    ; Code for 4 Button 
	cpfseq	key, A		    ;  
	goto	checkFive	    ; If different, skip to next check 
	movlw	4
	call	keyPress
	return 
checkFive:
	movlw	11011101B	    ; Code for 4 Button 
	cpfseq	key, A		    ;  
	goto	checkSix	    ; If different, skip to next check 
	movlw	5
	call	keyPress
	return 
checkSix:
	movlw	11011011B	    ; Code for 4 Button 
	cpfseq	key, A		    ;  
	goto	checkSeven	    ; If different, skip to next check 
	movlw	6
	call	keyPress
	return 
checkSeven:
	movlw	10111110B	    ; Code for 7 Button 
	cpfseq	key, A		    ;  
	goto	checkEight	    ; If different, its invaliid
	movlw	7
	call	keyPress
	return 
checkEight:
	movlw	10111101B	    ; Code for 4 Button 
	cpfseq	key, A		    ;  
	goto	checkNine	    ; If different, skip to next check 
	movlw	8
	call	keyPress
	return 
checkNine:
	movlw	10111011B	    ; Code for 9 Button 
	cpfseq	key, A		    ;  
	goto	checkZero   	    ; If different, its invaliid
	movlw	9
	call	keyPress
	return 
checkZero:
	movlw	01111101B	    ; Code for 9 Button 
	cpfseq	key, A		    ;  
	goto	checkA		    ; If different, its invaliid
	movlw	0xff
	call	keyPress
	return 
checkA:
	movlw	01111110B	    ; Code for A Button 
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
	movlw	01110111B	    ; Code for C Button 
	cpfseq	key, A		    ;  
	goto	checkD		    ; If different, its invaliid
	movlw	12
	call	keyPress
	return 
checkD:
	movlw	10110111B	    ; Code for D Button 
	cpfseq	key, A		    ;  
	goto	checkE		    ; If different, its invaliid
	movlw	13
	call	keyPress
	return 
checkE:
	movlw	11010111B	    ; Code for D Button 
	cpfseq	key, A		    ;  
	goto	checkF		    ; If different, its invaliid
	movlw	14
	call	keyPress
	return 
checkF:
	movlw	11100111B	    ; Code for D Button 
	cpfseq	key, A		    ;  
	goto	invalidPress		    ; If different, its invaliid
	movlw	15
	call	keyPress
	return 

keyPress:   
	; displays W on PORT-D 
	movwf	PORTD, A
	call	bigDelay
	clrf	PORTD, A
	return 
	
invalidPress: 
; 	movlw	0
; 	call	keyPress
	return 

;=======Other Sub-Routines======================================================
keypadDelay: 
	decfsz	delay09, F, A	; decrement until zero
	bra	keypadDelay
	movlw	0x09	
	movwf	delay09, A
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

