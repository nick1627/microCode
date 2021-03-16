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
	counters    EQU	    0x01
	
	goto	start
	
;=======Main Programme==========================================================

start: 
	movlw	15
;	movwf	counters, A
;loops:	movf	counters, W, A
	call	LCDWrite
;	subwfb	counters, f, A
;	bc	loops
	goto	$

	end	init
	