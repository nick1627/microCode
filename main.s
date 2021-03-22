#include <xc.inc>

extrn	peripheralSetup, buzz, LEDProgress, LEDFlash
extrn	LCDSetup, LCDWrite
global	storedKey, testKey
extrn	readEEPROM, writeEEPROM

psect   udata_acs
storedKey:  ds 4
testKey:    ds 4

psect	code, abs
	
init: 	org	0x00
 	goto	setup

setup:	
	; technical setup
	bcf	CFGS	        ; point to Flash program memory  
	bsf	EEPGD		; access Flash program memory
	call	LCDSetup
	call	peripheralSetup
	
	goto	start
	
;=======Main Programme==========================================================

start: 
	;call	buzz
	call	readEEPROM

	movlw   2
	call	LCDWrite 
	movlw	8
	movwf	storedKey, A
	movlw	7
	movwf	storedKey+1, A
	movlw	6
	movwf	storedKey+2, A
	movlw	5
	movwf	storedKey+3, A
	
	call	writeEEPROM	

	movff	testKey, PORTD
	goto	$

	end	init
	