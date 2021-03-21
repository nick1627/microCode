#include <xc.inc>

extrn		storedKey
global		readEEPROM, writeEEPROM 

psect	udata_acs
savedKey:	ds 4
saveInt:	ds 1
EEAddr:		ds 1
    
EEPGDbit	EQU 7	; EEPROM memory select bit
CFGSbit		EQU 6	; EEPROM config select bit
EEIFbit		EQU 4	; EEPROM flag interrupt bit
WRENbit	    	EQU 2	; EEPROM write enable bit
WRbit		EQU 1	; EEPROM write control bit
RDbit		EQU 0	; EEPROM read control bit

psect	EEPROM_code, class=CODE	;===============================================

readEEPROM: 
    ; read data in EEPROM (@EEAddr) to storedKey
	
;	movf	EEPROMAddr, W
;	banksel	EEADR	
;	movwf	EEADR		; move address in access to be read to EEADR
;	
;	banksel	EECON1	
;	bcf	EEPGD	; clear EEPGD to select EEPROM data memory
;	bcf	CFGS	; clear CFGS to access EEPROM data memory -- DONE IN SETUP??
;	
;	lfsr	1, storedKey	; load FSR1 with storedKey memory location
;	bsf	RD	; initialise read cycle 
;	nop			; leave one cycle for reading 
;	
;	banksel	EEDATA
;	movf	EEDATA, W
;	movwf	savedKey, A	; read data in EEPROM to savedKey
;	
;	banksel	EECON1	
;	bsf	EEPGD	; reset EEPGD to select flash data memory again 
;	return
    
	movf	EEAddr, W, A
	banksel EEADR
	movwf	EEADR, 1		; move address in access to be read to EEADR
	banksel	EECON1
	bcf	EECON1, EEPGDbit, 1;EEPGD	; clear EEPGD to select EEPROM data memory
	bcf	EECON1, CFGSbit, 1;CFGS	; clear CFGS to access EEPROM data memory -- DONE IN SETUP??
	
	lfsr	1, storedKey	; load FSR1 with storedKey memory location
	bsf	EECON1, RDbit, 1	; initialise read cycle 
	nop			; leave one cycle for reading 
	banksel	EEDATA
	movf	EEDATA, W
	movwf	savedKey, A	; read data in EEPROM to savedKey
	
	banksel	EECON1
	bsf	EECON1, EEPGDbit, 1;EEPGD	; reset EEPGD to select flash data memory again 
	return
	
writeEEPROM:
	movf	EEAddr, W, A
	banksel EEADR
	movwf	EEADR, 1		; move address to be written-in to EEADR
	movf	storedKey, W, A
	banksel	EEDATA
	movwf	EEDATA, 1		; 8-bit data to be written 
	
	banksel	EECON1
	bcf	EECON1, EEPGDbit, 1;EEPGD	; clear EEPGD to select EEPROM data memory
	; 	bcf	EECON1, CFGS
	bsf	EECON1, WRENbit, 1	; set WREN to enable writing to EEPROM 
	
	;;;movff	INTCON, saveInt, A	; backup INTCON interupt register
	bcf	GIE		; disable interrupt whilst writing
	
	banksel	EECON2
	movlw	0x55		; required sequence for writing to EEPROM
	movwf	EECON2, 1
	movlw	0xAA
	movwf	EECON2, 1
	
	banksel	EECON1
	bsf	EECON1, WRbit, 1	; initialise write cycle 
	btfsc	EECON1, WRbit, 1	; check if writing is done
	bra	$-2		; wait until write-completed flag is up
	
	bsf	GIE
	;;;movff	saveInt, INTCON, A	; enable interupt again 
	bcf	EECON1, WRENbit, 1	; clear WREN to disable writing to EEPROM 
	bsf	EECON1, EEPGDbit, 1;EEPGD	; reset EEPGD to select flash data memory again 
	return 
	
