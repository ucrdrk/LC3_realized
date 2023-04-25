;=========================================================================
; Name & Email must be EXACTLY as in Gradescope roster!
; Name: Allan Knight
; Email: aknig007@ucr.edu
; 
; Assignment name: Assignment 3
; Lab section: n/a
; TA: n/a
; 
; I hereby certify that I have not received assistance on this assignment,
; or used code, from ANY outside source other than the instruction team
; (apart from what was provided in the starter file).
;
;=========================================================================

.ORIG x3000			; Program begins here
;-------------
;Instructions
;-------------
			LD R6, Value_ptr		; R6 <-- pointer to value to be displayed as binary
			LDR R1, R6, #0			; R1 <-- value to be displayed as binary 
;-------------------------------
;INSERT CODE STARTING FROM HERE
;--------------------------------
; store ascii '0' in R2, ascii '1' in R3:
			LD R2, zero
			LD R3, one
			
;  set up loop counter in R4, nibble size in R5
			LD R4, word_size
			LD R5, nibble
			
start_lp	ADD R5, R5, #0			; set cc's on nibble size
			BRp number
			LD R0, space			; have printed 4 character, time for space`
			OUT
			LD R5, nibble			; restart nibble counter			

number		ADD R1, R1, #0			; set cc's on value to be printed		
			BRn print_one
			ADD R0, R2, #0			; msb is 0, output zero
			OUT
			BRnzp continue
print_one	ADD R0, R3, #0			; msb is 1, output one
			OUT
			
continue	ADD R1, R1, R1			; left shift R1
			ADD R5, R5, #-1			; decrement nibble counter
			ADD R4, R4, #-1			; decrement word counter
			BRp start_lp
			
; counter has reached 0 (16 iterations)
			LD R0, newline
			OUT
			
			HALT
;---------------	
;Data
;---------------
Value_ptr	.FILL xCA01	; The address where value to be displayed is stored
newline		.FILL x0A
zero		.FILL x30
one			.FILL x31
space		.FILL x20
word_size	.FILL #16
nibble		.FILL #4

.END

.ORIG xCA01					; Remote data
Value .FILL xABCD			; <----!!!NUMBER TO BE DISPLAYED AS BINARY!!! Note: label is redundant.
;---------------	
;END of PROGRAM
;---------------	
.END
