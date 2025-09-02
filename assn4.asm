;=========================================================================
; Name & Email must be EXACTLY as in Gradescope roster!
; Name: Brian Linard
; Email: aknig007@ucr.edu
; 
; Assignment name: Assignment 4
; Lab section: n/a
; TA: n/a
; 
; I hereby certify that I have not received assistance on this assignment,
; or used code, from ANY outside source other than the instruction team
; (apart from what was provided in the starter file).
;
;=================================================================================
;THE BINARY REPRESENTATION OF THE USER-ENTERED DECIMAL NUMBER MUST BE STORED IN R4
;=================================================================================

					.ORIG x3000			; Program begins here


firstChar:			LD R0, introPromptPtr  ; Get pointer to Intro prompt
					PUTS
					
					AND R3, R3, #0			; zero out negative flag
					
					AND R6, R6, #0			; set up R6 as counter for 5 digits
					ADD R6, R6, #5
					
					AND R5, R5, #0			; zero out accumulator of binary number (R5)
					; NOTE:this program uses *R5* as the target register: 
					; at line "finish", R5 is copied into target register specified for this assignment instance

; Get first character, test for '+', '-', digit, or other					
					GETC
					OUT
					
					LD R1, nlChar
					NOT R1, R1
					ADD R1, R1, #1
					ADD R1, R0, R1			; is very first character = '\n'?
					BRz exit 				; if so, just quit!

					LD R1, plusChar
					NOT R1, R1
					ADD R1, R1, #1
					ADD R1, R0, R1			; is R0 = '+'?
					BRz getDigits			; if so, ignore it, go get first digit
					
					LD R1, minusChar
					NOT R1, R1
					ADD R1, R1, #1
					ADD R1, R0, R1			; is R0 = '-'?
					BRz minus				; if so, set neg flag, get first digit
					
					LD R1, zeroChar
					NOT R1, R1
					ADD R1, R1, #1
					ADD R1, R0, R1			; is R0 < '0'?
					BRn invalid 					
					
					LD R1, nineChar
					NOT R1, R1
					ADD R1, R1, #1
					ADD R1, R0, R1			; is R0 > '9'?
					BRp invalid					
				
			; to get this far, R0 is first numeric digit!
					LD R1, asciiOffset		; convert R0 from ascii digit to number
					NOT R1, R1	
					ADD R1, R1, #1
					ADD R0, R0, R1
					
					ADD R5, R5, R0			; push first digit into accumulator
					ADD R6, R6, #-1			; got first digit, 
					BRnzp getDigits			; now go get 2nd digit

minus:				ADD R3, R3, #-1			; set negative flag to -1
					BRnzp getDigits

invalid:			LD R0, nlChar
					OUT
					LD R0, errorMessagePtr	; ok to wipe R0 - it was invalid!
					PUTS
					BRnzp firstChar			; start over
					
					
getDigits:			GETC
					OUT
					
					LD R1, nlChar
					NOT R1, R1
					ADD R1, R1, #1
					ADD R1, R0, R1			; is R0 = '\n'?
					BRz finish 				; user has terminated input with a nl			
					
					LD R1, zeroChar
					NOT R1, R1
					ADD R1, R1, #1
					ADD R1, R0, R1			; is R0 < '0'?
					BRn invalid 					
					
					LD R1, nineChar
					NOT R1, R1
					ADD R1, R1, #1
					ADD R1, R0, R1			; is R0 > '9'?
					BRp invalid					
				
			; R0 is nth digit
					LD R1, asciiOffset		; convert R0 from ascii digit to number
					NOT R1, R1	
					ADD R1, R1, #1
					ADD R0, R0, R1
					
			; multiply accumulator by 10:
					AND R2, R2, #0			; zero out loop counter
					ADD R2, R2, #9			; set counter to (10-1)
					ADD R1, R5, #0			; copy accumulator into R1 in prep for addition
times10:			ADD R5, R5, R1			; add it back into accumulator (9 times)
					ADD R2, R2, #-1
					BRp times10

					ADD R5, R5, R0			; add most recent digit into accumulator
					ADD R6, R6, #-1			; decrement digit counter
					
					BRp getDigits			; < 5 digits, go back get next.
					
					LD R0, nlChar			; user did not get a chance to terminate with a nl, 
					OUT						; so program must do it ...
					
finish:				ADD R3, R3, #0			; test neg flag
					BRzp exit
					
					NOT R5, R5				; take 2's complement of number
					ADD R5, R5, #1

exit:				ADD R4, R5, #0			; copy result into R4
					HALT

;---------------	
;Data
;---------------


introPromptPtr		.FILL x3A00
errorMessagePtr		.FILL x3B00
plusChar			.FILL x2B ; '+'
minusChar			.FILL x2D ; '-'
zeroChar			.FILL x30 ; '0'
nineChar			.FILL x39 ; '9'
nlChar				.FILL x0A ; '\n'
asciiOffset			.FILL x30

.END

;------------
;Remote data
;------------
					.ORIG x3A00			; intro prompt
					.STRINGZ	"Input a positive or negative decimal number (max 5 digits), followed by ENTER\n"
					
					.END
					
					.ORIG x3B00			; error message					
					.STRINGZ	"ERROR: invalid input\n"
;---------------
;END of PROGRAM
;---------------
					.END

;-------------------
;PURPOSE of PROGRAM
;-------------------
; Convert a sequence of up to 5 user-entered ascii numeric digits into a 16-bit two's complement binary representation of the number.
; if the input sequence is less than 5 digits, it will be user-terminated with a newline (ENTER).
; Otherwise, the program will emit its own newline after 5 input digits.
; The program must also output a final newline.
; Input validation is performed on the individual characters as they are input, but not on the magnitude of the number.
