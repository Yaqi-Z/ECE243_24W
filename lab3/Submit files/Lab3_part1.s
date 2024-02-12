/* Program to Count the number of 1's in a 32-bit word,
located at InputWord */

/* Part1 Goal: count number of 1s in 32 bit word */
.global _start
_start:
	/* Put your code here */
# store answer into word Answer
	movia r1, Answer
	movia r2, 0 # hold answer of #of 1's in r6
	movia r3, InputWord
	ldw r4, (r3)
	movi r5, 0x01 #use for AND gate
				#Question: can I use movi instead, is the upper bits will assign to 0?

LOOP: # use AND gate to check if is 1
	#if result is 1, then add 1 to the result, otherwise, 0
	AND r6, r4, r5 #add r3, r4, and put the result into r5 as temp result
	srli r4, r4,1
	beq r6, r5, Add1
	br LOOP
	


Add1: addi r2, r2, 1
	  br LOOP

	 
	 stw r2, (r1) #store answer into result

endiloop: br endiloop

InputWord: .word 0x4a01fead

Answer: .word 0
	
	