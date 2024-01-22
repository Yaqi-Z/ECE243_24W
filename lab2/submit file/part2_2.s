.text  # The numbers that turn into executable instructions
.global _start
_start:

/* r13 should contain the grade of the person with the student number, -1 if not found */
/* r10 has the student number being searched */


	movia r10, 644370		# r10 is where you put the student number being searched for

/* Your code goes here  */
		# load data
		movia r1, Snumbers
		movia r2, Grades 
		movia r11, result
	    #method: count for turns, needs #round to search up to Snumber,
		#and then count down to find the grade
		movi r3, 0  #holds for #of rounds; 1 round = 4 byte to address
		movi r5, 4 #use for load Grade, 1 word = 4 byte
		
Search: ldw r4, (r1) #currently search
		# if no match
		beq r4, r10, getgrade #if match
		beq r4, r0, nofound
		addi r1, r1, 4 #go to next student number that is searching
		addi r3, r3, 4 #1 rounf take - add 4 to address
		br Search


getgrade: # r3: number of rounds it took to found the Snumbers
		  # r2: where holde the Grades
		div r3, r3, r5 # Calculate the offset in bytes to the grade
		add r2, r2, r3 #get the grade
		ldb r6, (r2) #load the content in r2 to r6
		stw r6,(r11)
		br iloop
		
nofound: movi r6, -1
		 stw r6, (r11)


iloop: br iloop


.data  	# the numbers that are the data 

/* result should hold the grade of the student number put into r10, or
-1 if the student number isn't found */ 

result: .word 0
		
/* Snumbers is the "array," terminated by a zero of the student numbers  */
Snumbers: .word 10392584, 423195, 644370, 496059, 296800
        .word 265133, 68943, 718293, 315950, 785519
        .word 982966, 345018, 220809, 369328, 935042
        .word 467872, 887795, 681936, 0

/* Grades is the corresponding "array" with the grades, in the same order*/
Grades: .byte 99, 68, 90, 85, 91, 67, 80
        .byte 66, 95, 91, 91, 99, 76, 68  
        .byte 69, 93, 90, 72
	
	
