# Digital Lock Project
Authors:     Nicholas Rayns

             Hana Douglas
             
Last Update: 26/03/2021

          
This repository includes all XC8 Assembly files necessary for programming a PIC18F87K22 microcontroller as a digital security lock. Some files have been expanded from the Microcontroller Labs repository by Imperial College London https://github.com/ImperialCollegeLondon/MicroprocessorsLab.


Functionality: 

The security lock is connected to a locking mechanism that opens when voltage is set HIGH. The correct 4-digit passcode unlocks the device. The third incorrect attempt to access the device will set off a minute-long alarm including loud buzzers and flashing LEDs. The device includes passcode changing abilities, non-volatile memory storage for passcodes, a small LCD screen for instructions, and alarm disabling options. 


Applications and tools required: 

MPLAB XC8 IDE
MPLAB XC8 IPE 
PIC18F87K22 Microcontroller
PICKIT4 In-Circuit Debugger 


Circuit:

RE0-RE7 > M5160PBMA001 Alphanumeric Keypad P0-P7
RD0-RD7 > 2473084 Light Bar and 470R Resistor Network
RC0-RC7 > Locking Mechanism 


Programming Guide: 

1. Download the Lock Branch of this repository. 
2. Open as project in MPLAB IDE. 
3. Connect microprocessor to operator via PICKIT4. 
4. Ensure microprocessor has power and necessary circuit is connected. 
5. "Run Program" 


FILES: 

config.s --- Includes configuration setup required for connecting to PIC18F87K22
main.s ----- Includes main program and timer interrupt
keypad.s --- Includes keypad reading and decoding program 
LCD.s ------ Includes LCD writing program and all possible display messages
EEPROM.s --- Includes program for reading and writing to non-volatile memory
otherPeripherals.s - Inludes program for interacting with external circuit 
