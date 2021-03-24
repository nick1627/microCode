;===============================================================================
;* Includes function to access other peripherals: LED, Buzzer		      *
;*									      *
;* Buzzer hard-wired to RB6 |  LED connected to Port-D RD0-P0		      *
;===============================================================================
#include <xc.inc>
global	peripheralSetup, buzz, LEDProgress, LEDFlash, LEDDelay, LEDsOn, LEDsOff
global	buzzOn, buzzOff
global	resetPeripherals

psect	udata_acs;================================named variables in access ram=
progress:	ds 1	
delayCounter:	ds 3
flashTimes:	ds 1
buzzTime:	ds 1

buzzE		EQU 6		; buzzer enable bit
buzzFreq	EQU 80		; relative buzzer frequency 
flashFreq	EQU 0x15	; relative flash frequency
flashFor	EQU 5		; relative flash duration
	
psect	LED_code, class=CODE ; =================================================
peripheralSetup: 
	clrf    TRISD, A	; set port-D as output for LEDs
	movlw	10000000B	; update LCD.s (11000000B)
	movwf	TRISB, A    

buzz: 
; makes a little buzz noise (resonant frequency ~3.8kHz)
	movlw	0xff
	movwf	buzzTime, A	; duration of buzz
buzzF:
	bsf	PORTB, buzzE, A	; HIGH to buzzer
	call	buzzDelay
	bcf	PORTB, buzzE, A	; LOW to buzzer
	call	buzzDelay
	decfsz	buzzTime, A	; repeat 
	bra	buzzF 
	return
	
buzzDelay: 
	movlw	buzzFreq	; time between buzz LOW/HIGH depends on freq
	movwf	delayCounter, A	; currently 8-bit cascaded delay 
	movwf	delayCounter+1, A
casA:	call	casB
	decfsz	delayCounter, f, A
	bra	casA
	return 
casB:	decfsz	delayCounter+1, f, A
	bra	casB
	movlw	buzzFreq
	movwf	delayCounter+1, A
	return 
	
buzzOn: 
	bsf PORTB, buzzE, A
	return 

buzzOff: 
	bcf PORTB, buzzE, A
	return
    
LEDProgress:
	; takes W 0-4 and shows relative progress on LED bar 
	; 0 - all off
	; 1 - a quarter way there
	; 2 - half way there
	; 3 - three quarters there
	; 4 - all on
    
	movwf	progress, A 
	
	movlw	0		; no keys entered
	cpfseq	progress, A
	goto	$ + 8
	clrf	PORTD, A	; All pins OFF
	return 
	
	movlw	1		; 1 correct key entered
	cpfseq	progress, A
	goto	$ + 10
	movlw	00000011B
	movwf	PORTD, A	; 1/4 lights on
	return 
	
	movlw	2		; 2 correct keys entered
	cpfseq	progress, A
	goto	$ + 10
	movlw	00001111B
	movwf	PORTD, A	; 2/4 lights on
	return 
	
	movlw	3		; 3 correct keys entered
	cpfseq	progress, A
	goto	$ + 10
	movlw	00111111B
	movwf	PORTD, A	; 3/4 lights on
	return 
	
	setf	PORTD, A	; ALL pins ON 
	return 
	
LEDFlash:
	movlw	flashFor
	movwf	flashTimes, A
flashLp:
	setf	PORTD, A
	call	LEDDelay
	clrf	PORTD, A
	call	LEDDelay
	decfsz	flashTimes, A
	bra	flashLp
	return 
	
LEDsOn:
	setf	PORTD, A
	return

LEDsOff: 
	clrf	PORTD, A
	return		
	
		
LEDDelay: 
	movlw	flashFreq
	movwf	delayCounter, A
	movwf	delayCounter+1, A
	movwf	delayCounter+2, A
casU:	call	casH
	decfsz	delayCounter, f, A
	bra	casU
	return 
casH:	call	casL
	decfsz	delayCounter+1, f, A
	bra	casH
	movlw	flashFreq
	movwf	delayCounter+1, A
	return 
casL:	decfsz	delayCounter+2, f, A
	bra	casL
	movlw	flashFreq
	movwf	delayCounter+2, A
	return 
	
resetPeripherals:
	call	LEDsOff
	return
