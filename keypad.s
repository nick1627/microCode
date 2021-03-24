;===============================================================================
;* Includes function to detect and read keypad input			      *
;*									      *
;* Keypad connected to Port-E with RE0|P0				      *
;===============================================================================
#include <xc.inc>
global	keypadSetup, checkKey

psect	udata_acs ; Access RAM data ===========================================
key:		ds 1    ; temporary keypad output 
delay09:	ds 1	; delay function counter
    
psect	keypad_code, class=CODE	; Keypad Code ==================================
;=======Keypad Configuration====================================================
keypadSetup:
	banksel PADCFG1		    ; Go to bank containing keypad configuration 
	bsf	REPU		    ; Accesses PADCFG1 for keypad 
	clrf	LATE, A		    ; Set Port-E to Output
	movlw	0x09		    ; Set up keypad delay variables
	movwf	delay09, A
	return	

;=======Global Keypad Reading Routine===========================================
checkKey:
    ; Global subroutine that returns keypad input in W when called
	call	configRow	    
	call	readRow	
	call	configColumn
	call	readColumn 
	call 	decode
	return
    
;=======Functional Sub-Routines=================================================
configRow: 
    ; Configures the keypad to reading row mode
	movlw	0x0F		    ; 00001111
	movwf	TRISE, A	    ; Pins 0-3 Inputs | 4-7 Outputs
	call	keypadDelay	    ; Small delay to complete configuration
	movlw	0x0F		    ; 00001111
	movwf	PORTE, A	    ; Output set to LOW
	call	keypadDelay	    ; Small delay
	return

configColumn: 
    ; Similar to configRow, reads columns
    	movlw	0xF0		    ; 11110000
	movwf	TRISE, A	    ; Pins 0-3 Outputs | 4-7 Inputs
	call	keypadDelay
	movlw	0xF0
	movwf	PORTE, A	    
	call	keypadDelay
	return
	
readRow:
    ; Reads row output from keypad
	clrf	key, A		    ; Reset temporary key memory 
	movff	PORTE, key, A	    ; Move row output to key (inputs set as 0)
	return 
	
readColumn:
    ; After readRow, reads column output from keypad
	movf	PORTE, W, A	    ; Read in Port-E Inputs to W
	addwf	key, A		    ; Add column output to row output in key 
	return 

decode: 
    ; Takes keypad output in key and decodes which button was pressed
	movlw	11111111B	    ; Compare to 0xFF
	cpfseq	key, A		    ; (No key pressed) 
	goto	checkOne	    ; If different, skip to next check 
	movlw	16		    ; 16 means no press
	return 
	; Return the key pressed in Hex to W
checkOne:	
	movlw	11101110B	    ; Code for 1 Button 
	cpfseq	key, A		    
	goto	checkTwo	    ; If different, skip to next check 
	movlw	1
	return 
checkTwo:	
	movlw	11101101B	    ; Code for 2 Button 
	cpfseq	key, A		    
	goto	checkThree	    ; If different, skip to next check 
	movlw	2
	return 
checkThree:	
	movlw	11101011B	    ; Code for 3 Button 
	cpfseq	key, A		    
	goto	checkFour	    ; If different, skip to next check 
	movlw	3
	return 
checkFour:
	movlw	11011110B	    ; Code for 4 Button 
	cpfseq	key, A		    
	goto	checkFive	    ; If different, skip to next check 
	movlw	4
	return 
checkFive:
	movlw	11011101B	    ; Code for 5 Button 
	cpfseq	key, A		    ;  
	goto	checkSix	    ; If different, skip to next check 
	movlw	5
	return 
checkSix:
	movlw	11011011B	    ; Code for 6 Button 
	cpfseq	key, A		    
	goto	checkSeven	    ; If different, skip to next check 
	movlw	6
	return 
checkSeven:
	movlw	10111110B	    ; Code for 7 Button 
	cpfseq	key, A		    
	goto	checkEight	    ; If different, its invaliid
	movlw	7
	return 
checkEight:
	movlw	10111101B	    ; Code for 8 Button 
	cpfseq	key, A		    
	goto	checkNine	    ; If different, skip to next check 
	movlw	8
	return 
checkNine:
	movlw	10111011B	    ; Code for 9 Button 
	cpfseq	key, A		    
	goto	checkZero   	    ; If different, skip to next check 
	movlw	9
	return 
checkZero:
	movlw	01111101B	    ; Code for 0 Button 
	cpfseq	key, A		    
	goto	checkA		    ; If different, skip to next check 
	movlw	0
	return 
checkA:
	movlw	01111110B	    ; Code for A Button 
	cpfseq	key, A		    
	goto	checkB		    ; If different, skip to next check 
	movlw	10
	return 
checkB:
	movlw	01111011B	    ; Code for B Button 
	cpfseq	key, A		   
	goto	checkC		    ; If different, skip to next check 
	movlw	11
	return 
checkC:
	movlw	01110111B	    ; Code for C Button 
	cpfseq	key, A		     
	goto	checkD		    ; If different, skip to next check 
	movlw	12
	return 
checkD:
	movlw	10110111B	    ; Code for D Button 
	cpfseq	key, A		    
	goto	checkE		    ; If different, skip to next check 
	movlw	13
	return 
checkE:
	movlw	11010111B	    ; Code for D Button 
	cpfseq	key, A		    
	goto	checkF		    ; If different, skip to next check 
	movlw	14
	return 
checkF:
	movlw	11100111B	    ; Code for D Button 
	cpfseq	key, A		    
	goto	invalidPress	    ; If different, its invaliid
	movlw	15		    
	return 
	
invalidPress: 
	movlw	17		    ; 17 means invalid key 
	return 

;=======Other Sub-Routines======================================================
keypadDelay: 
	decfsz	delay09, F, A	    ; decrement counter until zero
	bra	keypadDelay
	movlw	0x09		    ; reload counter for next call
	movwf	delay09, A
	return
