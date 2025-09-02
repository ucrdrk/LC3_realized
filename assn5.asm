; Name & Email must be EXACTLY as in Gradescope roster!
; Name: 
; Email: 
; 
; Assignment name: Assignment 5
; Lab section: 
; TA: 
; 
; I hereby certify that I have not received assistance on this assignment,
; or used code, from ANY outside source other than the instruction team
; (apart from what was provided in the starter file).
;
;=================================================================================
; PUT ALL YOUR CODE AFTER THE main LABEL
;=================================================================================

;---------------------------------------------------------------------------------
;  Initialize program by setting stack pointer and calling main subroutine
;---------------------------------------------------------------------------------
.ORIG x3000

; initialize the stack
ld r6, stack_addr

; call main subroutine
lea r5, main
jsrr r5

;---------------------------------------------------------------------------------
; Main Subroutine
;---------------------------------------------------------------------------------
main
; get a string from the user
lea r1, user_prompt
lea r2, user_string
ld r5, get_user_string_addr
jsrr r5

; find size of input string
add r1, r0, #0
ld r5, strlen_addr
jsrr r5

; call palindrome method
; move the string address into first parameter of palindrome sub
add r2, r1, r0
add r2, r2, #-1

; determine of stirng is a palindrome
ld r5, palindrome_addr
jsrr r5
add r3, r0, #0

; print the result to the screen
lea r0, result_string
puts

; decide whether or not to print "not"
add r3, r3, #0
brnp not_palindrome

lea r0, not_string
puts

not_palindrome
lea r0, final_string
puts

HALT

; Addresses of subroutines, other than main
get_user_string_addr .FILL    x3200
strlen_addr          .FILL    x3300
palindrome_addr      .FILL	  x3400
stack_addr           .FILL    xFE00

; Reserve memory for strings in the progrtam
user_prompt          .STRINGZ "Enter a string: "
result_string        .STRINGZ "The string is "
not_string           .STRINGZ "not "
final_string         .STRINGZ	"a palindrome\n"

; Reserve memory for user input string
user_string          .BLKW	  32

.END

;---------------------------------------------------------------------------------
; get_user_string - Get a strin from the user. Reads chars until user hit new line
;
; parameter: R1 - User prompt
; parameter: R2 - Address to store user input
;
; returns: Noting
;---------------------------------------------------------------------------------
.ORIG x3200
get_user_string
add r6, r6, #-1
str r7, r6, #0
add r6, r6, #-1
str r2, r6, #0

add r0, r1, #0
puts 

get_user_string_beg
getc
out
str r0, r2, #0
add r0, r0, #-10
brz get_user_string_end

add r2, r2, #1
br get_user_string_beg

get_user_string_end
and r0, r0, #0
str r0, r2, #0


ldr r2, r6, #0
add r0, r2, #0

add r6, r6, #1
ldr r7, r6, #0
add r6, r6, #1
RET
.END

;---------------------------------------------------------------------------------
; strlen function - Compute the length of a zero terminated string
;
; parameter: R1 - Address of zero terminated string to compute length
;
; return: The number of non-zero characters in given string
;---------------------------------------------------------------------------------
.ORIG x3300
strlen
add r6, r6, #-1
str r7, r6, #0
add r6, r6, #-1
str r1, r6, #0
add r6, r6, #-1
str r2, r6, #0

and r0, r0, #0

strlen_begin
ldr r2, r1, #0
brz strlen_end
add r0, r0, #1
add r1, r1, #1
br strlen_begin

strlen_end

ldr r2, r6, #0
add r6, r6, #1
ldr r1, r6, #0
add r6, r6, #1 
ldr r7, r6, #0
add r6, r6, #1
RET
.END

;---------------------------------------------------------------------------------
; palindrome function - Recursively determin if a string is a palindrome
; 
; parameter: R1 - Address of first character in string
; parameter: R2 - Address of last charachter in string
; 
; return: 1 if string is palindrome, 0 otherwise
;---------------------------------------------------------------------------------
.ORIG x3400
palindrome
add r6, r6, #-1
str r7, r6, #0
add r6, r6, #-1
str r1, r6, #0
add r6, r6, #-1
str r2, r6, #0
add r6, r6, #-1
str r3, r6, #0
add r6, r6, #-1
str r4, r6, #0
add r6, r6, #-1
str r5, r6, #0

; initialize result to 0
and r0, r0, #0
add r0, r0, #1

; base case 1, the begin address is greater than or equal to the end address
not r3, r2
add r3, r3, #1
add r3, r1, r3
brzp palindrome_done

; base case 2, the characters at begin and end are not equal
ldr r3, r1, #0
ldr r4, r2, #0
not r4, r4
add r4, r4, #1
add r3, r3, r4
brz recurse
and r0, r0, #0
br palindrome_done

recurse
add r1, r1, #1
add r2, r2, #-1
lea r5, palindrome
jsrr r5

palindrome_done
ldr r5, r6, #0
add r6, r6, #1
ldr r4, r6, #0
add r6, r6, #1
ldr r3, r6, #0
add r6, r6, #1
ldr r2, r6, #0
add r6, r6, #1
ldr r1, r6, #0
add r6, r6, #1
ldr r7, r6, #0
add r6, r6, #1
RET
.END
