#include <xc.inc>

extrn		storedKey, testKey
global		readEEPROM, writeEEPROM 

psect	udata_acs ;=============================================================
;savedKey:	ds 4
saveInt:	ds 1
EEAddr:		ds 2
EECounter:	ds 1
    
EEPGDbit	EQU 7	; EEPROM memory select bit
CFGSbit		EQU 6	; EEPROM config select bit
EEIFbit		EQU 4	; EEPROM flag interrupt bit
WRERRbit	EQU 3	; EEPROM write error flag bit
WRENbit	    	EQU 2	; EEPROM write enable bit
WRbit		EQU 1	; EEPROM write control bit
RDbit		EQU 0	; EEPROM read control bit

psect	EEPROM_code, class=CODE	;===============================================

readEEPROM: 
    ; read data in EEPROM (@EEAddr) to storedKey	    
	; specify EEPROM address to be written-in with EEADR
	clrf	EEADR
	clrf	EEADRH
	
	; setup EEPROM for reading 
	banksel	EECON1
	clrf	EECON1		    ; clears EEPGD/CFGS to select EEPROM memory

	; read EEADR to EEADR+4 into storedKey in FSR1
	lfsr	1, testKey	    ; load FSR1 with storedKey memory location -- CHANGE TEST KEY
	movlw	4
	movwf	EECounter, A	    ; load counter with 4 (keys) 
readLp:
	bsf	EECON1, RDbit, 1    ; initialise read cycle 
	nop			    ; leave one cycle for reading 
	movf	EEDATA, W	    ; move data read from EEPROM to W register
	movwf	POSTINC1	    ; move data to storedKey
	incf	EEADR, f	    ; increment EEADR to the next location
	decfsz	EECounter, A	    
	bra	readLp		    ; repeat for all 4 keys
	
	; reset system and return 
	bsf	EECON1, EEPGDbit, 1 ; reset EEPGD to select flash data memory 
	return
	
writeEEPROM:
    ; write data from storedKey to EEPROM (@EEAddr)
	; specify EEPROM address to be written-in with EEADR
	clrf	EEADR
	clrf	EEADRH
	
	; setup EEPROM for writing 
	banksel	EECON1
	movlw	0b00000100	    ; clears EEPGD/CFGS and sets WREN to enable
	movwf	EECON1, f	    ; writing to EEPROM     
	bcf	GIE		    ; disable interrupt whilst writing

	; write storedKey in FSR1 into EEADR to EEADR+4
	lfsr	1, storedKey	    ; load FSR1 with storedKey memory location
	movlw	4		    ; load counter with 4 (keys)
	movwf	EECounter, A
writeLp:
	movf	POSTINC1, W	    ; dump storedKey value to W
	movwf	EEDATA, f	    ; 8-bit data to be written to EEDATA
errLp:	bcf	EECON1, WRERRbit, 1 ; clear writing error flag	
	movlw	0x55		    ; required sequence for writing to EEPROM
	movwf	EECON2, 1
	movlw	0xAA
	movwf	EECON2, 1
	bsf	EECON1, WRbit, 1    ; initialise write cycle 
	btfsc	EECON1, WRbit, 1    ; check if writing is done
	bra	$-2		    ; wait until write-completed flag is up
	btfsc	EECON1, WRERRbit, 1 ; check if writing error flag came up 
	bra	errLp

	incf	EEADR, f	    ; increment EEADR to the next location
	decfsz	EECounter, A	    
	bra	writeLp		    ; repeat for all 4 keys
	
	; reset system and return 
	bsf	GIE		    ; enable interupt again
	movlw	0b10000000	    ; clears WREN to disable write-in to EEPROM 
	movwf	EECON1, f	    ; and resets EEPGD to select flash data

	return 
	
	
;resetEEPROM: 
;	clrf	EEADR
;	clrf	EEADRH
;	bcf	EECON1, 6
;	bcf	EECON1, 7
;	bcf	GIE
;	bsf	EECON1, 2
;resetLp:	
;	bsf	EECON1, 0
;	movlw	0x55
;	movwf	EECON2
;	movlw	0xAA
;	movwf	EECON2
;	bsf	EECON1, 1
;	btfsc	EECON1, 1
;	bra	$-2
;	incfsz	EEADR, F
;	bra	resetLp 
;	incfsz	EEADRH, F
;	bra	resetLp
;	
;	bcf	EECON1, 2
;	bsf	GIE
;	
;	return 