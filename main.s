#include <xc.inc>

extrn	peripheralSetup, buzz, LEDProgress, LEDFlash
extrn	LCDSetup, LCDWrite, LCDDelayMs
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
	movlw	5
	call	LCDDelayMs
	;call	writeEEPROM	

	call	readEEPROM
	movff	testKey, PORTD
	goto	$

	end	init
	