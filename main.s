#include <xc.inc>

extrn	peripheralSetup, buzz, LEDProgress, LEDFlash
extrn	LCDSetup, LCDWrite
global	storedKey
extrn	readEEPROM, writeEEPROM

psect	code, abs
	
init: 	org	0x00
 	goto	setup

setup:	
	; technical setup
	bcf	CFGS	        ; point to Flash program memory  
	bsf	EEPGD		; access Flash program memory
	;call	LCDSetup
	;call	peripheralSetup
	
	storedKey:  ds 1
	goto	start
	
;=======Main Programme==========================================================

start: 
	;call	buzz
	movlw   2
	call	LCDWrite 
	
	movlw	8
	movwf	storedKey, A
	call	writeEEPROM
	goto	$

	end	init
	