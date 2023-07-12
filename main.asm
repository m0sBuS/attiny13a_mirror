;	Program written by Maxim Dorokhin https://github.com/m0sBuS
;	This simple program was written for control door mounted outer rear view mirrors on Mitsubishi Galant VIII EA3A from Japan version
;	Main chip is ATTINY13A. This MCU control two relays for two directions, opening and closing mirrors.
;	This program using 1 external interrupt INT0 and 8-bit timer TIM0
;	
;	Used ATTINY13A pins:
;		PB5 - Reset pin, must be pull-up to VCC via 10K res and 0.1 uF cap
;		PB4, PB3 - Relays control pins. For my curcuit this pins control npn BC337 transistors
;		PB1 - External interrupt pin. I was used 12V signal and for voltage compilance must N-channel MOSFET.

;	declarate interrupt vectors
.CSEG
.ORG 0000
	RJMP MAIN				;	RESET or Power-ON vector

.ORG 0001
	RJMP EXT_INT			;	External interrupt vector

.ORG 0003
	RJMP TIM0_OVF			;	Timer overflow vector

;	definition timer overflow vector
TIM0_OVF:
	CLR R16					;	clear R16 register
	OUT PORTB, R16			;	writing PORTB is 0
	OUT TIMSK0, R16			;	clearing interrupt mask for TIMSK0 
	LDI R16, 0b01000000		;	return extended interrupt mask for INT0
	OUT GIMSK, R16			;	writing extended interrupt mask for INT0
	RETI					;	return with interrupt flag
	
;	definition opening mirror function
OPENING:
	SBI PORTB, PB3			;	switching-on PB3 for opening
	CLR R19					;	clear R19 register
	OUT TCNT0, R19			;	clear timer counter
	LDI R19, (1<<TOIE0)		;	set TOIE0 in R19 register
	OUT TIMSK0, R19			;	switching-on timer overflow interrupt flag
	LDI R20, (1<<CS02)		;	set CS02 in R20 register
	OUT TCCR0B, R20			;	setup timer clock divider by 256
	RETI					;	return with interrupt flag

;	definition closing mirror function
CLOSING:
	CLR R18					;	clear opened/closed flag
	SBI PORTB, PB4			;	switching-on PB4 for opening
	CLR R19					;	clear R19 register
	OUT TCNT0, R19			;	clear timer counter
	LDI R19, (1<<TOIE0)		;	set TOIE0 in R19 register
	OUT TIMSK0, R19			;	switching-on timer overflow interrupt flag
	LDI R20, (1<<CS02)		;	set CS02 in R20 register
	OUT TCCR0B, R20			;	setup timer clock divider by 256
	RETI					;	return with interrupt flag

;	definition external interrupt function
EXT_INT:
	INC R18					;	increment opened/closed flag
	CLR R16					;	clear R16 register
	OUT GIMSK, R16			;	clearing external interrupt mask
	OUT GIFR, R16			;	clearing external interrupt flag
	CPI R18, 1				;	if opened/closed flag is 1
		BREQ OPENING		;	Using opening function
	CPI R18, 2				;	if opened/closed flag is 2
		BREQ CLOSING		;	Using closing function
	RETI					;	return with interrupt flag

;	main program
MAIN:
	INC R18					;	increment opened/closed flag			
	LDI R16, (1 << PB3) | (1 << PB4)	;	set PB3 and PB4 for output pins
	OUT DDRB, R16			;	writing R16 in DDRB register
	RCALL OPENING			;	Using auto opening function
	LDI R16, (1 << INT0)	;	set INT0 in R16 register
	OUT GIMSK, R16			;	setup external interrupt mask
	LDI R16, (1 << ISC01)	;	set ISC01 in R16 register
	OUT MCUCR, R17			;	setup external interrupt for falling-edge trigger
	SEI						;	switching-on all interrupt
SLEEPMODE:					;	sleepmode loop
	SLEEP					;	sleepmode on
	RJMP SLEEPMODE			;	return back