.text
/* Program to Count the number of 1's and Zeroes in a sequence of 32-bit words,
and determines the largest of each */

.global _start
_start:

	/* Your code here  */
	movia r3, TEST_NUM
	movi r2, 1 # use for compare
	movia sp, 0x20000
	movia r4, LargestOnes
	movia r5, LargestZeroes
	movia r11, 0xFFFFFFFF

	ldw r12, (r4)
	ldw r13, (r5)

	
Search: 
		ldw r8, (r3) #this has to be inside of the loop is because we are finding the largest of a group of numvber
		beq r8, r0, STORE
		addi r3, r3, 4 #goes to the next number
		call ONES 		
		
		#compare longest 1 and 0 between words:
		#current r6 holds longest 1s, and r7 holds longest 0s
		#r12 - hold final result of 1
		#r13 - hold final result of 0
		#movia r12, r6

		bgt r14, r12, SwitchOnes
		
		# what if the answer is the same?
		#movia r13, r7
		br Call_ZEROS
		#cmpgt r13, r14, r13
		#cannot use compare since it only write 1 to r13, not the number
		
	

ONES:	subi sp, sp, 4 #push ra into the stack
		stw ra, (sp)
		
		subi sp, sp, 4 #push test num into the stack
		stw r3, (sp)
		
		subi sp, sp, 4 #push Largest ones into the stack
		stw r12, (sp) 
		
		subi sp, sp, 4 #push Largest zeros into the stack
		stw r13, (sp)
		
		subi sp, sp, 4 #push Largest zeros into the stack
		stw r8, (sp)
		
		
		movia r6,0 #r6 holds the largest 1s

ONESLOOP: beq r8, r0, ONESOVER
		  ANDi r10, r8, 1 # r6=r8+1 -> AND Gate 
		  srli r8, r8, 1
		  #beq r6, r2, Add1 # r6 holds the current numbers longest 1
		  add r6, r6, r10
		  br ONESLOOP

/*Add1: addi r6, r6, 1
		br ONESLOOP
*/		
ONESOVER: 	
			mov r14, r6
			
			ldw r8, (sp) #pop
			addi sp, sp, 4
			
			ldw r13, (sp) #pop
			addi sp, sp, 4
			
			ldw r12, (sp) #pop
			addi sp, sp, 4
			
			ldw r3, (sp) #pop
			addi sp, sp, 4

			ldw ra, (sp) #pop
			addi sp, sp, 4
			ret #return to search

SwitchOnes: mov r12, r14

Call_ZEROS: 
		call ZEROS
		bgt r14, r13, SwitchZeros

		br Search
	   
		

ZEROS: subi sp, sp, 4 #push ra into the stack
		stw ra, (sp)
		xor r8, r8, r11
		call ONES
		ldw ra, (sp) #pop
		addi sp, sp, 4
		ret
		
SwitchZeros: mov r13, r14
			br Search



/*
Zeros:	subi sp, sp, 4 #push ra into the stack
		stw ra, (sp)
		
		movia r7, 0
		
		#movia r10, r8 #copy r8 into r10, in case r8 changed in main?
		sub r11, r11, r8
		
ZerosLOOP: #loop until the input data contains no more 1s
		beq r11, r0, ZerosOver
		ANDi r7, r8, 1 
		srli r8, r8, 1
		beq r7, r2, AddZeros  # r7 holds the current numbers longest 0
		
AddZeros: addi r7, r7, 1
		br ZerosLOOP			
		
ZerosOver: ldw ra, (sp) #pop
			addi sp, sp, 4
			ret
*/

STORE: 	
	stw r12, (r4)  #r12 holds the largest 1s
	stw r13, (r5)  #r13 holds the largest 0s
	
endiloop: br endiloop

.data
TEST_NUM:  .word 0x4a01fead, 0xF677D671,0xDC9758D5,0xEBBD45D2,0x8059519D
            .word 0x76D8F0D2, 0xB98C9BB5, 0xD7EC3A9E, 0xD9BADC01, 0x89B377CD
            .word 0  # end of list 

LargestOnes: .word 0
LargestZeroes: .word 0