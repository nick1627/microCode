#include <xc.inc>

global	keypadSetup, checkKey
    
psect	udata_acs	; reserve data space in access ram
key:		ds 1    ; reserve one byte for keypad output
delay09:	ds 1	; CONSTANT can I load with 09? *****************
counter:	ds 1	; running empty counter 
    
;===============================================================================
psect	keypad_code, class=CODE
;	[ Keypad @PORTE RE1>P7 ]
;	[ LED    @PORTD	       ]
	
keypadSetup:
	banksel PADCFG1		; Move bank to PADCFG1
	bsf	REPU		; Accesses PADCFG1 for keypad 
	clrf	LATE, A		; Set Latch-E to 0 
	return	

;=======Reading Keypad Inputs===================================================
checkKey:	
	call	configRow
	call	readRow	
	call	configColumn
	call	readColumn 
	call 	decode
	return
    
;=======Functional Sub-Routines=================================================
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

decode: 
	movlw	11111111B	    ; Compare to 0xFF
	cpfseq	key, A		    ; (No key pressed) 
	goto	checkOne	    ; If different, skip to next check 
	movlw	0xff
	return 
checkOne:	
	movlw	11101110B	    ; Code for 1 Button 
	cpfseq	key, A		    ;  
	goto	checkTwo	    ; If different, skip to next check 
	movlw	1
	return 
checkTwo:	
	movlw	11101101B	    ; Code for 1 Button 
	cpfseq	key, A		    ;  
	goto	checkThree	    ; If different, skip to next check 
	movlw	2
	return 
checkThree:	
	movlw	11101011B	    ; Code for 1 Button 
	cpfseq	key, A		    ;  
	goto	checkFour	    ; If different, skip to next check 
	movlw	3
	return 
checkFour:
	movlw	11011110B	    ; Code for 4 Button 
	cpfseq	key, A		    ;  
	goto	checkFive	    ; If different, skip to next check 
	movlw	4
	return 
checkFive:
	movlw	11011101B	    ; Code for 4 Button 
	cpfseq	key, A		    ;  
	goto	checkSix	    ; If different, skip to next check 
	movlw	5
	return 
checkSix:
	movlw	11011011B	    ; Code for 4 Button 
	cpfseq	key, A		    ;  
	goto	checkSeven	    ; If different, skip to next check 
	movlw	6
	return 
checkSeven:
	movlw	10111110B	    ; Code for 7 Button 
	cpfseq	key, A		    ;  
	goto	checkEight	    ; If different, its invaliid
	movlw	7
	return 
checkEight:
	movlw	10111101B	    ; Code for 4 Button 
	cpfseq	key, A		    ;  
	goto	checkNine	    ; If different, skip to next check 
	movlw	8
	return 
checkNine:
	movlw	10111011B	    ; Code for 9 Button 
	cpfseq	key, A		    ;  
	goto	checkZero   	    ; If different, its invaliid
	movlw	9
	return 
checkZero:
	movlw	01111101B	    ; Code for 9 Button 
	cpfseq	key, A		    ;  
	goto	checkA		    ; If different, its invaliid
	movlw	0xff
	return 
checkA:
	movlw	01111110B	    ; Code for A Button 
	cpfseq	key, A		    ;  
	goto	checkB		    ; If different, its invaliid
	movlw	10
	return 
checkB:
	movlw	01111011B	    ; Code for B Button 
	cpfseq	key, A		    ;  
	goto	checkC		    ; If different, its invaliid
	movlw	11
	return 
checkC:
	movlw	01110111B	    ; Code for C Button 
	cpfseq	key, A		    ;  
	goto	checkD		    ; If different, its invaliid
	movlw	12
	return 
checkD:
	movlw	10110111B	    ; Code for D Button 
	cpfseq	key, A		    ;  
	goto	checkE		    ; If different, its invaliid
	movlw	13
	return 
checkE:
	movlw	11010111B	    ; Code for D Button 
	cpfseq	key, A		    ;  
	goto	checkF		    ; If different, its invaliid
	movlw	14
	return 
checkF:
	movlw	11100111B	    ; Code for D Button 
	cpfseq	key, A		    ;  
	goto	invalidPress		    ; If different, its invaliid
	movlw	15
	return 
	
invalidPress: 
	movlw	0xff
	return 

;=======Other Sub-Routines======================================================
keypadDelay: 
	decfsz	delay09, F, A	; decrement until zero
	bra	keypadDelay
	movlw	0x09	
	movwf	delay09, A
	return

	end 

