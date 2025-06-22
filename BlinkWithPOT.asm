;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file

;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer


;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------
init:

			bis.b #01h, &P1DIR 			;P1.0 output (LED1)
			bic.b #0001h, &P1OUT 		;P1.0 is zero
			bic.w #0001h, &PM5CTL0 		;GPIO power on
			bis.b   #BIT2, &P1SEL0		;Select the port register
            bis.b   #BIT2, &P1SEL1      ;We use P1.2 as the ADC input
            ;ADC Setup
			mov.w   #0210h, &ADCCTL0	;ADC ON & 4 clk cycle
			mov.w   #0220h, &ADCCTL1	;sample timer
			mov.w   #0020h, &ADCCTL2	;10 bit res
			mov.w   #0002h, &ADCMCTL0	;memory control
			;Timer B Setup
            mov.w   #32768, &TB0CCR0            ;Starting value for blink period
            bis.w	#TBCLR, &TB0CTL				;We set the clear bit in the control register
			bis.w	#TBSSEL__ACLK, &TB0CTL		;We select ACLK as source
			bis.w	#MC__UP, &TB0CTL			;We select up mode counting to TB0CL0
            mov.w   #CCIE,  &TB0CCTL0			;We enable capture/compare interrupt

            nop
            bis.w   #GIE, SR                    ;We enable maskable interrupts
			nop

main:
			jmp main

ISR_TB0:										;clk interrupt
		   	xor.b   #BIT0, &P1OUT               ;toggle LED P1OUT
			mov.w   #0213h, &ADCCTL0			;adc conversion

here:  		bit.w   #BIT0, &ADCIFG				;test interrupt
            jz      here						;loop zero
            mov.w   ADCMEM0, R4                 ;R4 to store ADC value to use as blinking period
            bic.w   #ADCIFG0, &ADCIFG			;clear interrupt flag

            add.w   #2000, R4                   ;We make a floor so R4 is never zero
            cmp.w   #0xFFFE, R4					;flag test vs value
store:      mov.w   R4, &TB0CCR0				;update timer
            bic.w   #CCIFG, &TB0CCTL0           ;Clear timer flag
            reti
;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack

;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET

			.sect ".int43"
			.short ISR_TB0
