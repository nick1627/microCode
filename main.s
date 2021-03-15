#include <xc.inc>

extrn  LCDSetup, LCDWrite
    
psect	code, abs	
init: 	org	0x00
 	goto	setup

setup:	
	; technical setup
	bcf	CFGS	        ; point to Flash program memory  
	bsf	EEPGD		; access Flash program memory
	
	call	LCDSetup	; setup LCD
	
	goto	start
	
;=======Main Programme==========================================================

start: 

	movlw	0
	call	LCDWrite
	goto	$
    
	end	init