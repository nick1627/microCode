#include <xc.inc>

global peripheralSetup, buzz, LEDProgress, LEDFlash

psect	udata_acs	; reserve data space in access ram
progress:	ds 1	
delayCounter:	ds 3
flashTimes:	ds 1
buzzTime:	ds 1

buzzE		EQU 6	; buzzer enable bit
buzzFreq	EQU 80
flashFreq	EQU 0x15
flashFor	EQU 5
	
psect	LED_code, class=CODE

peripheralSetup: 
	clrf    TRISD, A	; set port-D as output for LEDs
	clrf	PORTD, A
;	clrf	LATB, A		; done in LCD.s
	movlw	10000000B	; update on LCD.s
	movwf	TRISB, A    

buzz: 
; resonant frequency ~3.8kHz
	movlw	0xff
	movwf	buzzTime, A
buzzF:
	bsf	PORTB, buzzE, A
	call	buzzDelay
	bcf	PORTB, buzzE, A
	call	buzzDelay
	decfsz	buzzTime, A
	bra	buzzF 
	return
	
buzzDelay: 
	movlw	buzzFreq
	movwf	delayCounter, A
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
    
LEDProgress:
; takes W 0-4 and shows relative progress on LED bar 
	movwf	progress, A
	
	movlw	0
	cpfseq	progress, A
	goto	$ + 8
	clrf	PORTD, A
	return 
	
	movlw	1
	cpfseq	progress, A
	goto	$ + 10
	movlw	00000011B
	movwf	PORTD, A
	return 
	
	movlw	2
	cpfseq	progress, A
	goto	$ + 10
	movlw	00001111B
	movwf	PORTD, A	
	return 
	
	movlw	3
	cpfseq	progress, A
	goto	$ + 10
	movlw	00111111B
	movwf	PORTD, A	
	return 
	
	setf	PORTD, A
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
	

	
	