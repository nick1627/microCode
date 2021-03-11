#include <xc.inc>

<<<<<<< OURS
extrn	LCDSetup, LCDWrite	; external LCD subroutines
extrn	intKey, keypadSetup, bigDelay
=======
;extrn	LCDSetup, LCD_Write_Message, LCD_Write_Hex ; external LCD subroutines
extrn	intKey, keypadSetup
>>>>>>> THEIRS
    
   
psect	udata_acs   ; reserve data space in access ram
storedKey:	ds 4    ; reserve 4 bytes for 4 digit stored keycode
givenKey:	ds 4    ; reserve 4 bytes for inputted 4 digits stored keycode
codeCounter:	ds 1	; reserve 1 byte to store length of inputted code
attemptTimerHigh:	ds 1	; reserve 1 byte for the timer.  It is likely this 
			; will have to be increased to accomodate a time that
			; is suitable for human timescales
attemptTimerLow:	ds 1
			

			

psect	code, abs	
init: 	org	0x00
 	goto	setup

intHigh:	
	org	 0x0008		; high interrupt triggered by keypad input
<<<<<<< OURS
	goto	 intKey	; store keypad input
=======
	goto	 intKey		; store keypad input
>>>>>>> THEIRS

;=======Setup I/O===============================================================

setup:	
	; technical setup
	bcf	CFGS	        ; point to Flash program memory  
	bsf	EEPGD		; access Flash program memory
	
	call	LCDSetup	; setup LCD
	call	keypadSetup	; setup keypad
	
	clrf	TRISC, A	; port-C as output for lock/unlock
	clrf	TRISD, A	; port-D as output for LEDs
	clrf	PORTD, A		; clear port-D outputs 
	
	; program related setup
	; initialise contents of code counter
	movlw	0x00
	movwf	codeCounter, A
	
	goto	start
	
;=======Main Programme==========================================================

start: 
	; default 
	; display "Please enter passcode" or something 
<<<<<<< OURS
	call	intKey
	call	LCDWrite
	call	bigDelay
	goto	start
=======
	goto	mainLoop
	
mainLoop:
	;check code counter
	;if code counter = 4, do the code checking sequence
	movlw	0x04
	cpfslt	codeCounter
	;4 digits have been entered, so we do the next line
	goto	checkCode
	;4 digits have not been entered, so we do the next line
	movlw	0x00
	; check to see if the attempt timer has run out
	cpfsgt	attemptTimer
	; the code counter is reset if the timer has run out.
	call	resetCodeCounter
	; now we decrement the timer if the contents of the timer 
	; are greater than 0
	cpfslt	attemptTimer
	call	decrementAttemptTimer
	;now loop back to the beginning
	goto	mainLoop
	
	
checkCode:
	; At this point, 4 digits of the code have been entered.
	; We must now check to see if they are the correct values
>>>>>>> THEIRS
	
compareKey: 
	; after 4 digits entered it will come here via goto 
	; if wrong display error message and goto start
	
appendEnteredCode:
    ;	Append the code that has been entered into the keypad
    ;	assume w register contains the new code
	movwf	givenKey + codeCounter ; how?
	return

resetCodeCounter:
	; reset the value of the actual counter
	movlw	0x00
	movwf	codeCounter
	; FSR0 is used to store the value of the desired memory location
	; for the input digits, and should be reset to the first location 
	; now
	lfsr	0, givenKey
	
	return
	
	
; timer related code
resetAttemptTimer:
	movlw	0xFF ;high(0xFFFF)
	movwf	attemptTimerHigh, A
	movlw	0xFF ;low(0xFFFF)
	movwf	attemptTimerLow, A
	
decrementAttemptTimer:
	movlw	0x01
	cpfslt	attemptTimerLow, A
	bra	timerA
	bra	timerB
timerA:
	movlw	0xFF
timerB:
	
	return
	

	
    
delay16_repeater:
	; This calls the sixteen-bit delay FFh times.
	movlw	0xFF
	movwf	delay16_repeats, A
delay16_repeater_loop:
	call	delay16
	decfsz	delay16_repeats, A
	bra	delay16_repeater_loop
	return	
	
delay16:
	
	movlw	0x00
dloop:	
	; decrement your way through the 16 bits
	decf	delay16_counterLow, f, A
	subwfb	delay16_counterHigh, f, A
	bc	dLoop
	return
	
; lock related code
	
lock:	; This sends the signal to lock the lock
	movlw	0xFF
	movwf	PORTC, A
	return
	
unlock:	; This sends the signal to unlock the lock
	movlw	0x00
	movwf	PORTC, A
	return
    
    end	init
