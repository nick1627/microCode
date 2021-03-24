#include <xc.inc>

extrn	peripheralSetup, buzz, LEDProgress, LEDFlash
extrn	LCDSetup, LCDWrite, LCDDelayMs
global	storedKey, testKey, codeLength
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
	;call	LCDSetup
	;call	peripheralSetup
	codeLength EQU 0x04
 	clrf    TRISD, A	; set port-D as output for LEDs
	clrf	PORTD, A

	goto	start
	
;=======Main Programme==========================================================

start: 
	call	readEEPROM
	movff	testKey, PORTD

	movlw	25
	movwf	storedKey, A
	movlw	6
	movwf	storedKey+1, A
	movlw	7
	movwf	storedKey+2, A
	movlw	8
	movwf	storedKey+3, A
	
	call	writeEEPROM	

	goto	$

	end	init
	