#include <xc.inc>

extrn	LCDSetup, LCDWrite
extrn	keypadSetup, checkKey
extrn	peripheralSetup, buzz, LEDProgress, LEDFlash, LEDDelay
;extrn	readEEPROM, writeEEPROM

global	storedKey
    
psect	udata_acs   ; reserve data space in access ram
storedKey:		ds 4    ; reserve 4 bytes for 4 digit stored keycode
inputKey:		ds 4    ; reserve 4 bytes for inputted 4 digits stored keycode
codeCounter:		ds 1	; reserve 1 byte to store length of inputted code
timer:			ds 3	; reserve 3 bytes for the timer.
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
attemptCounter:		ds 1	; Stores the number of attempts at entering the
				; the passcode that have been made
acceptInput:		ds 1	; Determines whether (FF) or not (0) keypad 
				; input is to be accepted
newKey:			ds 1	; Stores the most recent single key press value
			

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
	movlw	10000101B	; configure rules for timer - CHECK THE TIMING!
	movwf	T0CON, A
	bsf	TMR0IE		; enable timer 0 interrupts
	bsf	GIE		; globally enable all interrupts with high priority
	
	call	lock		; ensure lock is locked
	
	; program related setup
	;call	readEEPROM
	
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
	
	call	resetTimer	; timer must be set to its maximum
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
	call	delay16RepeaterQuarter
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
	call	decrementTimer ;	WHAT
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
	movlw	changeCodeScreen
	call	updateLCD
	; delay to let message be visible before switching
	call	delay16RepeaterHalf
	movlw	changeAlarmScreen
	call	updateLCD
	call	delay16RepeaterHalf
	
	call	decrementTimer
	
	goto	mainLoop
mode1Exit:	
	call	switchMode0
	goto	mainLoop
	
mode2:	
	; in this mode, we can change the code.
	; if the time runs out, we switch back to the locked mode
	
	; first display the correct screen depending on the entered 
	; code progress
	call	codeEntryDisplay
	; check code counter
	movlw	codeLength
	cpfslt	codeCounter, A
	; 4 digits have been entered, so do the code setting sequence
	goto	setNewCode
	; 4 digits have not been entered, so continue
	
	; now we decrement the timer (if the timer has not run out).
	call	decrementTimer
	; check to see if the timer has run out
	movlw	0x00
	cpfseq	timerFinished, A
	; If the timer runs out, we exit mode 2
	bra	mode2Exit
	; otherwise loop back to the beginning
	goto	mainLoop
mode2Exit:
	; reset input codes etc
	call	timeOut
	; switch to mode 0
	call	switchMode0
	goto	mainLoop
mode3:	
	; at this point, the alarm must sound because there have been sufficiently
	; many incorrect attempts at gaining entry
	; only turn on the alarm if the alarmFlag is True.
	movlw	0x00
	bra	mode3Exit
	
	
mode3Exit:
	call	switchMode0
	goto	mainLoop
	
	
timeOut:
	call	resetEnteredCode
	movlw	outOfTimeScreen
	call	updateLCD
	call	delay16RepeaterQuarter
	return
	
	
; display-related code (the standalone subroutines anyway)
codeEntryDisplay:
	; this subroutine determines which display is to be presented to the user
	; on code entry, whether in modes 0 or 2
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
	movlw	0x00
	cpfseq	mode, A
	bra	codeEntryDisplayEnterCodeMode2
	bra	codeEntryDisplayEnterCodeMode0
codeEntryDisplayEnterCodeMode0:
    	movlw	enterCodeScreen
	bra	codeEntryDisplayExit
codeEntryDisplayEnterCodeMode2:
	movlw	enterNewCodeScreen
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
	; use same timer for modes 1, 2 and 3
	call	resetTimer 
	return
switchMode2:
	movlw	0x02
	movwf	mode, A
	; use same timer for modes 1, 2 and 3
	call	resetTimer 
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
	call	delay16RepeaterHalf
	movlw	0x00
	movwf	attemptCounter, A
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
	call	delay16RepeaterHalf
	incf	attemptCounter, A
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
resetTimer:
	; the value that the timer is reset to depends on what mode the 
	; program is currently in.  So first we check the mode
	movlw	0x00
	cpfsgt	mode, A
	bra	resetTimerMode0
	movlw	0x01
	cpfsgt	mode, A
	bra	resetTimerMode1
	bra	resetTimerMode2
resetTimerMode0:
	movlw	0xFF
	movwf	timer+2, A
	movlw	0xFF
	movwf	timer+1, A
	movlw	0x10
	movwf	timer, A
	bra	resetTimerExit
resetTimerMode1:
	movlw	0x05
	movwf	timer+2, A
	movlw	0x00
	movwf	timer+1, A
	movlw	0x00
	movwf	timer, A
	bra	resetTimerExit
resetTimerMode2:
	movlw	0xFF
	movwf	timer+2, A
	movlw	0xFF
	movwf	timer+1, A
	movlw	0x40
	movwf	timer, A
	bra	resetTimerExit
resetTimerExit:
	; the timerFinished boolean flag must be reset to 0 to indicate that
	; the timer has not finished
	movlw	0x00
	movwf	timerFinished, A
	return

decrementTimer:
	movlw	0x00
	cpfseq	timerFinished, A
	return
	; the timer has not finished, so we decrement
	decf	timer+2, f, A
	subwfb	timer+1, f, A
	subwfb	timer, f, A
	; now check if the timer has reached 0
	movlw	0x00
	cpfseq	timer, A
	return
	cpfseq	timer+1, A
	return
	cpfseq	timer+2, A
	return
	; once the timer has reached zero, set the timer finished flag
	movlw	0xFF
	movwf	timerFinished, A
	return

	
; stored passcode related code
setNewCode:
	; this sets the new code, switches the mode and goes to mainloop
	movff	inputKey, storedKey
	; call	writeEEPROM
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
	
	; the key press options are
	; 0-9 are the 0-9 keys
	; 10-15 are the A-F keys like in hex
	; 16 means no key press
	; 17 is everything else, e.g. multiple key presses.  (invalid)
	
	call	checkKey ; this puts new key in WREG
	movwf	newKey, A
	
	; if the key press is invalid, we reject the next input and exit
	movlw	17
	cpfslt	newKey, A
	bra	checkForKeyPressBlockInput
	; if the key press is 'no press', we reset the flag blocking input
	; so we know that the next press is a separate press.
	movlw	16
	cpfslt	newKey, A
	bra	checkForKeyPressAllowInput
	; The opportunity to unblock the input has been presented, so now if 
	; the input is still blocked we should do nothing and exit the interrupt
	movlw	0xFF
	cpfseq	acceptInput, A
	; if input is not being accepted, we leave the interrupt
	bra	checkForKeyPressExit
	; otherwise we branch depending on the mode and continue.	
	movlw	0x00
	cpfsgt	mode, A
	bra	checkForKeyPressMode0
	movlw	0x01
	cpfsgt	mode, A
	bra	checkForKeyPressMode1
	movlw	0x02
	cpfsgt	mode, A
	bra	checkForKeyPressMode2
	bra	checkForKeyPressExit
checkForKeyPressMode0:
	movf	newKey, W, A
    	; find new location to store the pressed key
	; store the pressed key
	call	appendEnteredCode ; ASSUMES NEW KEY STORED IN WREG
	; reset timer
	call	resetTimer
	; increment code counter	
	call	incrementCodeCounter
	bra	checkForKeyPressBlockInput
checkForKeyPressMode1:
	movf	newKey, W, A
	; expect two allowed inputs
	; A to switch alarm on/off
	; C to change code
	; otherwise, exit
	movwf	temp1, A
	movlw	10 ; CODE FOR "A" GOES HERE
	cpfseq	temp1, A
	bra	checkForKeyPressMode1MoreOptions
	bra	checkForKeyPressMode1Alarm
checkForKeyPressMode1MoreOptions:
	; now check if the output was C
	movlw	12 ; CODE FOR "C" GOES HERE
	cpfseq	temp1, A
	bra	checkForKeyPressBlockInput
	; otherwise switch to mode 2 and exit, allowing 
	; a new code to be set in the next interrupt
	call	switchMode2
	bra	checkForKeyPressBlockInput
checkForKeyPressMode1Alarm:
	; want to change the flag for the alarm
	; if alarm on, switch it off
	; if alarm off, switch it on
	movlw	0x00
	cpfsgt	alarmFlag, A
	bra	checkForKeyPressMode1AlarmTurnOn
	bra	checkForKeyPressMode1AlarmTurnOff
checkForKeyPressMode1AlarmTurnOn:
	movlw	0xFF
	movwf	alarmFlag, A
	movlw	alarmOnScreen
	call	updateLCD
;	movlw	0x01
;	call	delay16RepeaterW
	call	delay8
	bra	checkForKeyPressBlockInput
checkForKeyPressMode1AlarmTurnOff:
	movlw	0x00
	movwf	alarmFlag, A
	movlw	alarmOffScreen
	call	updateLCD
	;movlw	0x01
	;call	delay16RepeaterW
	call	delay8
	bra	checkForKeyPressBlockInput
checkForKeyPressMode2:
	movf	newKey, W, A
	; the option to change the stored code has been selected in the previous
	; interrupt, so now we are in mode 2 and are looking to change the code.
	
	; find new location to store the pressed key
	; store the pressed key
	call	appendEnteredCode ; ASSUMES NEW KEY STORED IN WREG
	; increment code counter	
	call	incrementCodeCounter
	; reset the timer to allow more time for code entry
	call	resetTimer
	bra	checkForKeyPressBlockInput
checkForKeyPressAllowInput:
	movlw	0xFF
	movwf	acceptInput, A
	bra	checkForKeyPressExit
checkForKeyPressBlockInput:
	clrf	acceptInput, A
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

delay16RepeaterW:
	; this calls the sixteen-bit delay WREG times
	movwf	delay16Repeats, A
	bra	delay16RepeaterLoop
delay16RepeaterFull:
	; This calls the sixteen-bit delay FFh times.
	movlw	0xFF
	movwf	delay16Repeats, A
	bra	delay16RepeaterLoop
delay16RepeaterHalf:
	; This calls the sixteen-bit delay 80h times.
	movlw	0x80
	movwf	delay16Repeats, A
	bra	delay16RepeaterLoop
delay16RepeaterQuarter:
	; This calls the sixteen-bit delay 40h times.
	movlw	0x40
	movwf	delay16Repeats, A
	bra	delay16RepeaterLoop
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
	
delay8:
	movlw	0xFF
	movwf	delay16Counter+1, A
	movlw	0x00
delay8Loop:
	decf	delay16Counter+1, A
	cpfseq	delay16Counter+1, A
	bra	delay8Loop
	return
	
	
	end	init