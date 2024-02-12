/* Program to Count the number of 1's in a 32-bit word,
located at InputWord */

.global _start
_start:

	/* Put your code here */


endiloop: br endiloop

InputWord: .word 0x4a01fead

Answer: .word 0
	
	