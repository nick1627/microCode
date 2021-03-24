;===============================================================================
;* Includes function to read/write to non-volatile memory (EEPROM)	      *
;*									      *
;* Uses PIC EEPROM							      *
;===============================================================================
#include <xc.inc>
extrn		storedKey, codeLength
global		readEEPROM, writeEEPROM 

psect	udata_acs ;=============================================================
EECounter:	ds 1

psect	EEPROM_code, class=CODE	;===============================================

readEEPROM: 
    ; read data in EEPROM (@EEAddr) to storedKey	    
	; specify EEPROM address to be read from with EEADR
	clrf	EEADR, A		; point to address in EEPROM at 0x0000
	clrf	EEADRH, A
	
	; setup EEPROM for reading 
	clrf	EECON1, A		; clears EEPGD/CFGS to select EE memory

	; read EEADR to EEADR+3 into storedKey at FSR1
	lfsr	1, storedKey		; load FSR1 with storedKey location
	movlw	codeLength
	movwf	EECounter, A		; load counter with the number of keys

readLp:	; loop to read data for each key 
	bsf	RD			; initialise read cycle 
	nop				; leave one cycle for reading 
	movff	EEDATA, POSTINC1, A	; move data to storedKey pointed by FSR1
	
	incf	EEADR, A		; increment EEADR to the next location
	decfsz	EECounter, A		; decrement counter and
	bra	readLp			;	repeat for all keys
	
	; reset system and return 
	bsf	EEPGD			; set EEPGD to select flash data memory 
	return
	
writeEEPROM:
    ; write data from storedKey to EEPROM (@EEAddr)
	; specify EEPROM address to be written-in with EEADR
	clrf	EEADR, A		; point to address in EEPROM at 0x0000
	clrf	EEADRH, A
	
	; setup EEPROM for writing 
	clrf	EECON1, A		; clears EEPGD/CFGS to select EE memory
	bsf	WREN			; set WREN to enable writing to EEPROM 
	bcf	GIE			; disable interrupt whilst writing

	; write storedKey in FSR1 into EEADR to EEADR+3
	lfsr	1, storedKey		; load FSR1 with storedKey location
	movlw	codeLength
	movwf	EECounter, A		; load counter with the number of keys
	
writeLp:; loop to write data for ecah key 
	movf	POSTINC1, W, A		; move data from storedKey to EEDATA
	movwf	EEDATA, A		    
	
	movlw	0x55			; required sequence for EEPROM write
	movwf	EECON2, A
	movlw	0xAA
	movwf	EECON2, A
	bsf	WR			; initialise write cycle 
	btfsc	WR			; check if writing is done
	bra	$-2			; wait until write-completed flag is up
	bcf	WRERR			; clear writing error flag	
	bcf	EEIF			; clear EEPROM interrupt flag
	
	incf	EEADR, A		; increment EEADR to the next location
	decfsz	EECounter, A		; decrement counter and
	bra	readLp			;	repeat for all keys
	
	; reset system and return 
	bsf	GIE			; enable interupt again
	clrf	EECON1, A		; clear WREN to disable  EEPROM writing 
	bsf	EEPGD			; reset EEPGD to select flash data 
	return 
