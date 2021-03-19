#include <xc.inc>

extrn		storedKey
global		readEEPROM, writeEEPROM 

psect	udata_acs
savedKey:	ds 4
saveInt:	ds 1
EEAddr:		ds 1
    
EEPGD		EQU 7	; EEPROM memory select bit
CFGS		EQU 6	; EEPROM config select bit
EEIF		EQU 4	; EEPROM flag interrupt bit
WREN		EQU 2	; EEPROM write enable bit
WR		EQU 1	; EEPROM write control bit
RD		EQU 0	; EEPROM read control bit

psect	EEPROM_code, class=CODE	;===============================================

readEEPROM: 
    ; read data in EEPROM (@EEAddr) to storedKey
	
	;movf	EEPROMADDr+1, W, A
	;movwf	EEADRH
    
	movf	EEPROMAddr, W, A
	movwf	EEADR		; move address in access to be read to EEADR
	
	bcf	EECON1, EEPGD	; clear EEPGD to select EEPROM data memory
	bcf	EECON1, CFGS	; clear CFGS to access EEPROM data memory -- DONE IN SETUP??
	
	lfsr	1, storedKey	; load FSR1 with storedKey memory location
	bsf	EECON1, RD	; initialise read cycle 
	nop			; leave one cycle for reading 
	movf	EEDATA, W
	movwf	savedKey	; read data in EEPROM to savedKey
	
	bsf	EECON1, EEPGD	; reset EEPGD to select flash data memory again 
	return
	
writeEEPROM:
	movf	EEPROMAddr, W, A
	movwf	EEADR		; move address to be written-in to EEADR
	movf	storedKey, W, A
	movff	EEDATA		; 8-bit data to be written 
	
	bcf	EECON1, EEPGD	; clear EEPGD to select EEPROM data memory
	; 	bcf	EECON1, CFGS
	bsf	EECON1, WREN	; set WREN to enable writing to EEPROM 
	
	;;;movff	INTCON, saveInt, A	; backup INTCON interupt register
	bcf	INTCON, GIE		; disable interrupt whilst writing
	
	movlw	0x55		; required sequence for writing to EEPROM
	movwf	EECON2
	movlw	0xAA
	movwf	EECON2
	
	bsf	EECON1, WR	; initialise write cycle 
	btfsc	EECON1, WR	; check if writing is done
	bra	$-2		; wait until write-completed flag is up
	
	bsf	INTCON, GIE
	;;;movff	saveInt, INTCON, A	; enable interupt again 
	bcf	EECON1, WREN	; clear WREN to disable writing to EEPROM 
	bsf	EECON1, EEPGD	; reset EEPGD to select flash data memory again 
	return 
	
