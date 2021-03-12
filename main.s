#include <xc.inc>

;extrn	LCDSetup, LCD_Write_Message, LCD_Write_Hex ; external LCD subroutines
;extrn	keyPress, keypadSetup
    
   
psect	udata_acs   ; reserve data space in access ram
storedKey:		ds 4    ; reserve 4 bytes for 4 digit stored keycode
inputKey:		ds 4    ; reserve 4 bytes for inputted 4 digits stored keycode
codeCounter:		ds 1	; reserve 1 byte to store length of inputted code
attemptTimerHigh:	ds 1	; reserve 2 bytes for the timer.
attemptTimerLow:	ds 1
timerFinished:		ds 1	; reserve 1 byte to indicate whether the timer has finished
				; i.e. has reached 0
			

			

psect	code, abs	
init: 	org	0x00
 	goto	setup

;intHigh:	
;	org	0x0008		; high priority interrupt triggered by keypad input
;	goto	keyPress	; store keypad input

;=======Setup I/O===============================================================

setup:	
	; technical setup
	bcf	CFGS	        ; point to Flash program memory  
	bsf	EEPGD		; access Flash program memory
	
	;call	LCDSetup	; setup LCD
	;call	keypadSetup	; setup keypad
	
	clrf	TRISC, A	; port-C as output for lock/unlock
	clrf	TRISD, A	; port-D as output for LEDs
	
	; program related setup
	; initialise contents of code counter
	movlw	0x00
	movwf	codeCounter, A
	
	codeLength EQU 0x04
 
	lfsr	0, inputKey	; will use FSR0 with inputKey
	lfsr	1, storedKey	; will use FSR1 with storedKey
	
	goto	start
	
;=======Main Programme==========================================================

start: 
	; default 
	; display "Please enter passcode" or something 
	goto	mainLoop
	
	; debug section

	

	
	
	
mainLoop:
	;check code counter
	;if code counter = 4, do the code checking sequence
	movlw	codeLength
	cpfslt	codeCounter, A
	;4 digits have been entered, so we do the next line
	goto	checkEnteredCode
	;4 digits have not been entered, so we do the next line
	movlw	0x00
	; check to see if the attempt timer has run out
	cpfseq	timerFinished, A
	; the entered code is reset if the timer has run out.
	call	resetEnteredCode
	; now we decrement the timer (if the timer has not run out).
	call	decrementAttemptTimer
	;now loop back to the beginning
	goto	mainLoop
	
	
; code related to entered passcode
checkEnteredCode:
	; At this point, 4 digits of the code have been entered.
	; We must now check to see if they are the correct values
	movlw	0x00
	movwf	codeCounter
checkEnteredCode_loop:
	movff	POSTINC0, W
	cpfseq	POSTINC1
	bra	codeIncorrect
	incf	codeCounter, A
	movlw	codeLength
	cpfseq	codeCounter, A
	bra	checkEnteredCode_loop
codeCorrect:
	call	unlock
	return
codeIncorrect:
	; the entered code is incorrect
	; ensure lock is locked
	call	lock
	return

	
appendEnteredCode:
	;Append the code that has been entered into the keypad
	;assume w register contains the new code
	movwf	POSTINC0
	return

resetEnteredCode:
	call	resetCodeCounter
	; FSR0 is used to store the value of the desired memory location
	; for the input digits, and should be reset to the first location 
	; now
	lfsr	0, inputKey
	return

incrementCodeCounter:
	incf	codeCounter, A
	return	
	
resetCodeCounter:
	; reset the value of the actual counter
	movlw	0x00
	movwf	codeCounter
	
	return
	
; timer-related code
resetAttemptTimer:
	movlw	0xFF
	movwf	attemptTimerHigh, A
	movlw	0xFF
	movwf	attemptTimerLow, A
	; the timerFinished boolean flag must be reset to 0 to indicate that
	; the timer has not finished
	movlw	0x00
	movwf	timerFinished, A
	return

decrementAttemptTimer:
	movlw	0x00
	cpfseq	timerFinished, A
	return
	; the timer has not finished, so we decrement
	decf	attemptTimerLow, f, A
	subwfb	attemptTimerHigh, f, A
	; now check if the timer has reached 0
	movlw	0x00
	cpfseq	attemptTimerHigh, A
	return
	cpfseq	attemptTimerLow, A
	return
	movlw	0x01
	movwf	timerFinished, A
	return

	
	
; lock-related code
lock:	; This sends the signal to lock the lock
	movlw	0xFF
	movwf	PORTC, A
	return
	
unlock:	; This sends the signal to unlock the lock
	movlw	0x00
	movwf	PORTC, A
	return
    
	end	init