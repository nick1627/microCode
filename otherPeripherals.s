#include <xc.inc>

global peripheralSetup, buzz, LEDProgress, LEDFlash, LEDDelay

psect	udata_acs		; reserve data space in access ram
progress:	ds 1	
delayCounter:	ds 3
flashTimes:	ds 1
buzzTime:	ds 1

buzzE		EQU 6		; buzzer enable bit
buzzFreq	EQU 80		; relative buzzer frequency 
flashFreq	EQU 0x15	; relative flash frequency
flashFor	EQU 5		; relative flash duration
	
psect	LED_code, class=CODE

peripheralSetup: 
	clrf    TRISD, A	; set port-D as output for LEDs
;	clrf	LATB, A		; done in LCD.s
	movlw	10000000B	; update LCD.s (11000000B)
	movwf	TRISB, A    

buzz: 
; resonant frequency ~3.8kHz (need to calculate and change buzzFreq)
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
    
LEDProgress:
; takes W 0-4 and shows relative progress on LED bar 
	movwf	progress, A 
	
	movlw	0		; LED OFF
	cpfseq	progress, A
	goto	$ + 8
	clrf	PORTD, A	; All pins OFF
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
