.global _start
_start:
	
	/* PartIII : Goal is to sum 1 to 30 = r12 */
	.equ LEDs, 0xFF200000	
	
	movi r12, 0 	/* initialize r12 */
	movi r8, 1      /* r8 - starting point */
	movi r11, 30    /* set up breakpoint of the loop */
	 	
loop: add r12, r12, r8  /* sum  */
	  addi r8, r8, 1    /* increasing by 1 each time */
	  ble r8, r11, loop
	  
	   
done: 	movia r25, LEDs
		stwio r12, (r25)
		br done
	