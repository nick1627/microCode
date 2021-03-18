#include <xc.inc>

extrn	LCDSetup, LCDWrite
extrn	keypadSetup, checkKey
extrn	peripheralSetup, buzz, LEDProgress, LEDFlash, LEDDelay

    
psect	udata_acs   ; reserve data space in access ram
storedKey:		ds 4    ; reserve 4 bytes for 4 digit stored keycode
inputKey:		ds 4    ; reserve 4 bytes for inputted 4 digits stored keycode
codeCounter:		ds 1	; reserve 1 byte to store length of inputted code
attemptTimerHigh:	ds 1	; reserve 2 bytes for the timer.
attemptTimerLow:	ds 1
timerFinished:		ds 1	; reserve 1 byte to indicate whether the timer has finished
				; i.e. has reached 0
temp1:			ds 1
mode:			ds 1	; the program mode - this determines what the interrupt
				; does when valid keypad presses are made
alarmFlag:		ds 1	;

			

psect	code, abs	
init: 	org	0x00
 	goto	setup

intHigh:	
	org	0x0008			; high priority interrupt triggered by timer
	goto	checkForKeyPress	; store keypad input

;=======Setup I/O===============================================================

setup:	
	; technical setup
	bcf	CFGS	        ; point to Flash program memory  
	bsf	EEPGD		; access Flash program memory
	
	call	LCDSetup	; setup LCD
	call	keypadSetup	; setup keypad
	call	peripheralSetup	; setup other electronics
	
	clrf	TRISC, A	; port-C as output for lock/unlock
	
	; Set up the timer interrupt
	movlw	10000111B	; configure rules for timer - CHECK THE TIMING!
	movwf	T0CON, A
	bsf	TMR0IE		; enable timer 0 interrupts
	bsf	GIE		; globally enable all interrupts with high priority
	
	
	; program related setup
	; initialise contents of code counter
	movlw	0x00
	movwf	codeCounter, A
	
	codeLength EQU 0x04
 
	lfsr	0, inputKey	; will use FSR0 with inputKey
	lfsr	1, storedKey	; will use FSR1 with storedKey
	
	movlw	0x00
	movwf	mode, A
	
	movlw	0xFF		; set the alarm to be on initially
	movwf	alarmFlag, A
	
	
	; screen options
	; intro
	welcomeScreen		EQU 0
	; mode 0 (mostly)
	enterCodeScreen		EQU 1
	oneStarScreen		EQU 2
	twoStarScreen		EQU 3
	threeStarScreen		EQU 4
	fourStarScreen		EQU 5
	codeCorrectScreen	EQU 6
	codeIncorrectScreen	EQU 7
	outOfTimeScreen		EQU 8
	; mode 1
	optionScreen		EQU 9
	changeCodeScreen	EQU 10
	changeAlarmScreen	EQU 11
	alarmOnScreen		EQU 12
	alarmOffScreen		EQU 13
	; mode 2
	enterNewCodeScreen	EQU 14
	newCodeSetScreen	EQU 15
	
	
	goto	start
	
;=======Main Programme==========================================================

start: 
	movlw	welcomeScreen
	call	LCDWrite
	; delay
	goto	mainLoop
	;call	buzz
	;goto	$
	; debug section
	
	

	
	
	
mainLoop:
	; select which mode we're in
	movlw	0x00
	cpfsgt	mode, A
	bra	mode0
	movlw	0x01
	cpfsgt	mode, A
	bra	mode1
	bra	mode2
mode0:    
	; check code counter
	; if code counter = 4, do the code checking sequence
	movlw	codeLength
	cpfslt	codeCounter, A
	; 4 digits have been entered, so we do the next line
	goto	checkEnteredCode
	; 4 digits have not been entered, so we do the next line
	movlw	0x00
	; check to see if the attempt timer has run out
	cpfseq	timerFinished, A
	; the entered code is reset if the timer has run out.
	call	resetEnteredCode
	; now we decrement the timer (if the timer has not run out).
	call	decrementAttemptTimer
	; display the correct display for the current moment
	call	codeEntryDisplay
	; now loop back to the beginning
	goto	mainLoop
mode1:	
	; in this mode, we are presented with options to change the code,
	; mute the alarm etc
	
	movlw	0x00
	cpfseq	timerFinished, A
	; time has run out, switch back to locked mode
	bra	mode1Exit
	; time has not run out, so offer options
	movlw	optionScreen
	call	LCDWrite
	movlw	changeCodeScreen
	call	LCDWrite
	movlw	changeAlarmScreen
	call	LCDWrite
	; will need a delay
	
	
	goto	mainLoop
mode1Exit:	
	call	switchMode0
	goto	mainLoop
	
mode2:	
	; in this mode, we can change the code.
	; if the time runs out, we switch back to the locked mode
	movlw	enterNewCodeScreen
	call	LCDWrite
	; check code counter
	; if code counter = 4, do the code checking sequence
	movlw	codeLength
	cpfslt	codeCounter, A
	; 4 digits have been entered, so we do the next line
	goto	setNewCode
	; 4 digits have not been entered, so we do the next line
	movlw	0x00
	; check to see if the attempt timer has run out
	cpfseq	timerFinished, A
	; the entered code is reset if the timer has run out.
	call	timeOut
	; now we decrement the timer (if the timer has not run out).
	call	decrementAttemptTimer
	; now loop back to the beginning
	goto	mainLoop
mode2Exit:
	call	switchMode0
	goto	mainLoop
	
	
timeOut:
	call	resetEnteredCode
	movlw	outOfTimeScreen
	call	LCDWrite
	return
	
	
; display-related code (the standalone subroutines anyway)
codeEntryDisplay:
	movlw	0x00
	cpfsgt	codeCounter, A
	bra	codeEntryDisplayEnterCode
	movlw	0x01
	cpfsgt	codeCounter, A
	bra	codeEntryDisplayOneStar
	movlw	0x02
	cpfsgt	codeCounter, A
	bra	codeEntryDisplayTwoStar
	movlw	0x03
	cpfsgt	codeCounter, A
	bra	codeEntryDisplayThreeStar
	bra	codeEntryDisplayFourStar
codeEntryDisplayEnterCode:
	movlw	enterCodeScreen
	bra	codeEntryDisplayExit
codeEntryDisplayOneStar:
	movlw	oneStarScreen
	bra	codeEntryDisplayExit
codeEntryDisplayTwoStar:
	movlw	twoStarScreen
	bra	codeEntryDisplayExit
codeEntryDisplayThreeStar:
	movlw	threeStarScreen
	bra	codeEntryDisplayExit
codeEntryDisplayFourStar:
	movlw	fourStarScreen
	bra	codeEntryDisplayExit
codeEntryDisplayExit:
	call	LCDWrite
	return
	
	
	
	
; switching modes	
switchMode0:
	movlw	0x00
	movwf	mode, A
	return
switchMode1:
	movlw	0x01
	movwf	mode, A
	; assume for now that we can use the same timer for both
	; modes 0 and 1
	call	resetAttemptTimer 
	return
switchMode2:
	movlw	0x02
	movwf	mode, A
	return
	
	
; code related to entered passcode
checkEnteredCode:
	; At this point, 4 digits of the code have been entered.
	; We must now check to see if they are the correct values
	
	; display the correct screen
	movlw	fourStarScreen
	call	LCDWrite
	
	; reset the code counter, since it will be used here
	movlw	0x00
	movwf	codeCounter, A
	; also reset the FSRs relating to the two codes to compare
	lfsr	0, inputKey	; FSR0 used with inputKey
	lfsr	1, storedKey	; FSR1 used with storedKey
checkEnteredCodeLoop:
	movf	POSTINC0, W, A
	cpfseq	POSTINC1, A
	bra	codeIncorrect
	incf	codeCounter, A
	movlw	codeLength
	cpfseq	codeCounter, A
	bra	checkEnteredCodeLoop
codeCorrect:
	; reset the entered code
	call resetEnteredCode
	; display relevant screen
	movlw	codeCorrectScreen
	call	LCDWrite
	; unlock the lock
	call	unlock
	; set the mode
	call	switchMode1
	return
codeIncorrect:
	; the entered code is incorrect
	; display relevant screen
	movlw	codeIncorrectScreen
	call	LCDWrite
	; ensure lock is locked
	call	lock
	call	switchMode0
	return

	
appendEnteredCode:
	;Append the code that has been entered into the keypad
	;assume w register contains the new code
	movwf	POSTINC0, A
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
	movwf	codeCounter, A
	
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

	
; stored passcode related code
setNewCode:
	; this sets the new code, switches the mode and goes to mainloop
	movff	inputKey, storedKey
	movlw	newCodeSetScreen
	call	LCDWrite
	call	resetEnteredCode
	call	switchMode0
	call	lock
	; DELAY?
	goto	mainLoop
	
	
; lock-related code
lock:	; This sends the signal to lock the lock
	movlw	0xFF
	movwf	PORTC, A
	return
	
unlock:	; This sends the signal to unlock the lock
	movlw	0x00
	movwf	PORTC, A
	return
	
; code that runs on the interrupt
checkForKeyPress:
	btfss	TMR0IF		; check that this is timer0 interrupt
	retfie	f		; if not then return
	
	; move keypad input to W if any
	movlw	0xFF
	movwf   temp1, A
	call	checkKey		
	; if input key is FF then invalid or no press 
	cpfsgt	temp1, A
	goto	checkForKeyPressExit	
	
	; If valid key press, then branch based on mode:
	movlw	0x00
	cpfsgt	mode, A
	bra	checkForKeyPressMode0
	movlw	0x01
	cpfsgt	mode, A
	bra	checkForKeyPressMode1
	bra	checkForKeyPressMode2
checkForKeyPressMode0:
    	; find new location to store the pressed key
	; store the pressed key
	call	appendEnteredCode ; ASSUMES NEW KEY STORED IN WREG
	; reset timer
	call	resetAttemptTimer
	; increment code counter	
	call	incrementCodeCounter
	bra	checkForKeyPressExit
checkForKeyPressMode1:
	; expect two allowed inputs
	; A to switch alarm on/off
	; C to change code
	; otherwise, exit
	movwf	temp1, A
	movlw	01111110B ;CODE FOR "A" GOES HERE
	cpfseq	temp1, A
	bra	checkForKeyPressMode1MoreOptions
	bra	checkForKeyPressMode1Alarm
	
checkForKeyPressMode1MoreOptions:
	; now check if the output was C
	movlw	01110111B ; CODE FOR "C" GOES HERE
	cpfseq	temp1, A
	bra	checkForKeyPressExit
	; otherwise switch to mode 2 and exit, allowing 
	; a new code to be set in the next interrupt
	call	switchMode2
	bra	checkForKeyPressExit
checkForKeyPressMode1Alarm:
	; want to change the flag for the alarm
	; if alarm on, switch it off
	; if alarm off, switch it on
	movlw	0x00
	cpfsgt	alarmFlag, A
	bra	checkForKeyPressMode1AlarmTurnOff
checkForKeyPressMode1AlarmTurnOn:
	movlw	0xFF
	movwf	alarmFlag, A
	movlw	alarmOnScreen
	call	LCDWrite
	return
checkForKeyPressMode1AlarmTurnOff:
	movlw	0x00
	movwf	alarmFlag, A
	movlw	alarmOffScreen
	call	LCDWrite
	return
	
checkForKeyPressMode2:
	; the option to change the stored code has been selected in the previous
	; interrupt, so now we are in mode 2 and are looking to change the code.
	
	; find new location to store the pressed key
	; store the pressed key
	call	appendEnteredCode ; ASSUMES NEW KEY STORED IN WREG
	; reset timer
	call	resetAttemptTimer
	; increment code counter	
	call	incrementCodeCounter
	bra	checkForKeyPressExit
		
checkForKeyPressExit:	
	bcf	TMR0IF		; clear interrupt flag
	retfie	f		;return from interrupt
	
; alarm-related code
activateAlarm:
	movlw	0xFF
	movwf	alarmFlag, A
	return

deactivateAlarm:
	movlw	0x00
	movwf	alarmFlag, A
	return

; delay-related code
	
;delay16Repeater:
;	; This calls the sixteen-bit delay FFh times.
;	movlw	0xFF
;	movwf	delay16_repeats, A
;delay16RepeaterLoop:
;	call	delay16
;	decfsz	delay16_repeats, A
;	bra	delay16_repeater_loop
;	return	
;	
;delay16:
;	movlw	0xFF ;high(0xFFFF)
;	movwf	delay16_counterHigh, A
;	movlw	0xFF ;low(0xFFFF)
;	movwf	delay16_counterLow, A
;	movlw	0x00
;delay16Loop:	
;	; decrement your way through the 16 bits
;	decf	delay16_counterLow, f, A
;	subwfb	delay16_counterHigh, f, A
;	bc	dLoop
;	return
    
	end	init