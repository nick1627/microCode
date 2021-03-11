#include <xc.inc>

;extrn	LCDSetup, LCD_Write_Message, LCD_Write_Hex ; external LCD subroutines
extrn	intKey, keypadSetup
    
   
psect	udata_acs   ; reserve data space in access ram
storedKey:  ds 4    ; reserve 4 bytes for 4 digit stored keycode
givenKey:   ds 4    ; reserve 4 bytes for inputted 4 digits stored keycode

psect	code, abs	
init: 	org	0x00
 	goto	setup

intHigh:	
	org	 0x0008		; high interrupt triggered by keypad input
	goto	 intKey		; store keypad input

;=======Setup I/O===============================================================

setup:	bcf	CFGS	        ; point to Flash program memory  
	bsf	EEPGD		; access Flash program memory
	
	call	LCDSetup	; setup LCD
	call	keypadSetup	; setup keypad
	
	clrf	TRISC, A	; port-C as output for lock/unlock
	clrf	TRISD, A	; port-D as output for LEDs
	clrf	PORTD, A		; clear port-D outputs 
	
	goto	start
	
;=======Main Programme==========================================================

start: 
	; default 
	; display "Please enter passcode" or something 
	call	intKey
	goto	start
	
compareKey: 
	; after 6 digits entered it will come here via goto 
	; if wrong display error message and goto start
	
    end	init