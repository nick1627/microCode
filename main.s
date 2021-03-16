#include <xc.inc>

extrn	peripheralSetup, buzz, LEDProgress, LEDFlash
extrn	LCDSetup, LCDWrite

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
	movlw	7
	call	LCDWrite
	call	buzz
	goto	$

	end	init
	