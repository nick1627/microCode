#include <xc.inc>

extrn		storedKey, codeLength
global		readEEPROM, writeEEPROM 

psect	udata_acs ;=============================================================
EECounter:	ds 1

psect	EEPROM_code, class=CODE	;===============================================

readEEPROM: 
    ; read data in EEPROM (@EEAddr) to storedKey	    
	; specify EEPROM address to be written-in with EEADR
	banksel	EECON1			; select EEPROM memory bank 
	clrf	EEADR, A		; reset set address in EEPROM at 0x0000
	clrf	EEADRH, A
	
	; setup EEPROM for reading 
	clrf	EECON1, A		; clears EEPGD/CFGS to select EEPROM memory

	; read EEADR to EEADR+4 into storedKey in FSR1
	lfsr	1, storedKey		; load FSR1 with storedKey memory location -- CHANGE TEST KEY
	movlw	codeLength
	movwf	EECounter, A		; load counter with the number of keys (4)
	incf	EEADR, A		; read/write begins at location: 0x0001

readLp:	; loop to read data for each key 
	bsf	RD			; initialise read cycle 
	nop				; leave one cycle for reading 
	movf	EEDATA, W, A		; move data to FSR1 (storedKey)
	movwf	POSTINC1, A
	
	incf	EEADR, A		; increment EEADR to the next location in EE
	decfsz	EECounter, A
	bra	readLp			; repeat for all (4) keys
	
	; reset system and return 
	bsf	EEPGD			; reset EEPGD to select flash data memory 
	return
	
writeEEPROM:
    ; write data from storedKey to EEPROM (@EEAddr)
	; specify EEPROM address to be written-in with EEADR
	banksel	EECON1		    ; select EEPROM memory bank
	clrf	EEADR, A		    ; reset set address in EEPROM at 0x0000
	clrf	EEADRH, A
	
	; setup EEPROM for writing 
	clrf	EECON1, A		    ; clears EEPGD/CFGS to select EEPROM memory
	bsf	WREN		    ; set WREN to enable writing to EEPROM 
	bcf	GIE		    ; disable interrupt whilst writing

	; write storedKey in FSR1 into EEADR to EEADR+4
	lfsr	1, storedKey	    ; load FSR1 with storedKey memory location
	movlw	codeLength
	movwf	EECounter, A	    ; load counter with the number of keys (4)
	incf	EEADR, A		    ; read/write begins at location: 0x0001
	
writeLp:; loop to write data for ecah key 
	movf	POSTINC1, W, A	    ; move 8-bit data from storedKey to EEDATA
	movwf	EEDATA, A		    
	
	movlw	0x55		    ; required sequence for writing to EEPROM
	movwf	EECON2, A
	movlw	0xAA
	movwf	EECON2, A
	bsf	WR		    ; initialise write cycle 
	
	btfsc	WR		    ; check if writing is done
	bra	$-2		    ; wait until write-completed flag is up
	bcf	WRERR		    ; clear writing error flag	
	bcf	EEIF		    ; clear EEPROM interrupt flag
	
	incf	EEADR, f, A	    ; increment EEADR to the next location
	decfsz	EECounter, A	    
	bra	writeLp		    ; repeat for all (4) keys
	
	; reset system and return 
	bsf	GIE		; enable interupt again
	clrf	EECON1, A	; clears WREN to disable write-in to EEPROM 
	bsf	EEPGD		; reset EEPGD to select flash data memory 

	return 
	
	
	
;;resetEEPROM: 
;;	clrf	EEADR
;;	clrf	EEADRH
;;	bcf	EECON1, 6
;;	bcf	EECON1, 7
;;	bcf	GIE
;;	bsf	EECON1, 2
;;resetLp:	
;;	bsf	EECON1, 0
;;	movlw	0x55
;;	movwf	EECON2
;;	movlw	0xAA
;;	movwf	EECON2
;;	bsf	EECON1, 1
;;	btfsc	EECON1, 1
;;	bra	$-2
;;	incfsz	EEADR, F
;;	bra	resetLp 
;;	incfsz	EEADRH, F
;;	bra	resetLp
;;	
;;	bcf	EECON1, 2
;;	bsf	GIE
;;	
;;	return 