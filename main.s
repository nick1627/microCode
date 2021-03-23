#include <xc.inc>

extrn	LCDSetup, LCDWrite
extrn	keypadSetup, checkKey
extrn	readEEPROM, writeEEPROM 
extrn	peripheralSetup, buzz, LEDProgress, LEDFlash, LEDDelay
global	storedKey, codeLength
    
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
currentScreen:		ds 1	; stores the code associated with the current
				; screen being displayed
delay16Counter:		ds 2	; reserve 2 bytes for the 16-bit delay
delay16Repeats:		ds 1	; reserve 1 byte to indicate how many times to 
				; call the 16-bit delay
			

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
	
	call	lock		; ensure lock is locked
	
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
	
	call	resetAttemptTimer ; attempt timer must be set to its maximum
				  ; initially.
	
	
	
	
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
	
	movlw	100		; initialise value of currentScreen
	movwf	currentScreen, A; to match the first screen displayed
	
	
	goto	start
	
;=======Main Programme==========================================================

start: 
	movlw	welcomeScreen
	call	updateLCD
	call	buzz
	; delay
	goto	mainLoop

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
	;call	decrementAttemptTimer
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
	;movlw	optionScreen
	;call	updateLCD
	;call	delay16Repeater
	movlw	changeCodeScreen
	call	updateLCD
	; delay to let message be visible before switching
	call	delay16Repeater
	movlw	changeAlarmScreen
	call	updateLCD
	call	delay16Repeater
	
	
	goto	mainLoop
mode1Exit:	
	call	switchMode0
	goto	mainLoop
	
mode2:	
	; in this mode, we can change the code.
	; if the time runs out, we switch back to the locked mode
	movlw	enterNewCodeScreen
	call	updateLCD
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
	call	updateLCD
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
	call	updateLCD
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
	call	updateLCD
	
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
	call	resetEnteredCode
	; display relevant screen
	movlw	codeCorrectScreen
	call	updateLCD
	; unlock the lock
	call	unlock
	; set the mode
	call	switchMode1
	call	delay16Repeater
	goto	mainLoop
codeIncorrect:
	; the entered code is incorrect
	; reset the entered code
	call	resetEnteredCode
	; display relevant screen
	movlw	codeIncorrectScreen
	call	updateLCD
	; ensure lock is locked
	call	lock
	call	switchMode0
	call	delay16Repeater
	goto	mainLoop

	
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
	call	updateLCD
	call	resetEnteredCode
	call	switchMode0
	call	lock
	; DELAY?
	goto	mainLoop
	
	
; lock-related code
lock:	; This sends the signal to lock the lock
	setf	PORTC, A	
	return
	
unlock:	; This sends the signal to unlock the lock
	clrf	PORTC, A
	return
	
; code that runs on the interrupt
checkForKeyPress:
	btfss	TMR0IF		; check that this is timer0 interrupt
	retfie	f		; if not then return
	
	
	movlw	0xFF
	movwf   temp1, A
	call	checkKey	; this puts new key in WREG		
	; if input key is FF then invalid or no press 
	cpfsgt	temp1, A
	goto	checkForKeyPressExit	
	; temporarily put pressed key into temp1
	movwf	temp1, A
	; If valid key press, then branch based on mode:
	movlw	0x00
	cpfsgt	mode, A
	bra	checkForKeyPressMode0
	movlw	0x01
	cpfsgt	mode, A
	bra	checkForKeyPressMode1
	bra	checkForKeyPressMode2
checkForKeyPressMode0:
	movf	temp1, W, A
    	; find new location to store the pressed key
	; store the pressed key
	call	appendEnteredCode ; ASSUMES NEW KEY STORED IN WREG
	; reset timer
	call	resetAttemptTimer
	; increment code counter	
	call	incrementCodeCounter
	bra	checkForKeyPressExit
checkForKeyPressMode1:
	movf	temp1, W, A
	; expect two allowed inputs
	; A to switch alarm on/off
	; C to change code
	; otherwise, exit
	movwf	temp1, A
	movlw	10 ;CODE FOR "A" GOES HERE
	cpfseq	temp1, A
	bra	checkForKeyPressMode1MoreOptions
	bra	checkForKeyPressMode1Alarm
	
checkForKeyPressMode1MoreOptions:
	; now check if the output was C
	movlw	12 ; CODE FOR "C" GOES HERE
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
	call	updateLCD
	return
checkForKeyPressMode1AlarmTurnOff:
	movlw	0x00
	movwf	alarmFlag, A
	movlw	alarmOffScreen
	call	updateLCD
	return
	
checkForKeyPressMode2:
	movf	temp1, W, A
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
	
; display management code
updateLCD:
	; expect new screen value in W
	cpfseq	currentScreen, A
	bra	updateLCDNewScreen
	return
updateLCDNewScreen:
	movwf	currentScreen, A
	call	LCDWrite
	return

	
; delay-related code
	
delay16Repeater:
	; This calls the sixteen-bit delay FFh times.
	movlw	0x80
	movwf	delay16Repeats, A
delay16RepeaterLoop:
	call	delay16
	decfsz	delay16Repeats, A
	bra	delay16RepeaterLoop
	return
	

	
delay16:
	movlw	0xFF ;high(0xFFFF)
	movwf	delay16Counter, A
	movlw	0xFF ;low(0xFFFF)
	movwf	delay16Counter+1, A
	movlw	0x00
delay16Loop:	
	; decrement your way through the 16 bits
	decf	delay16Counter+1, f, A
	subwfb	delay16Counter, f, A
	bc	delay16Loop
	return
    
	end	init