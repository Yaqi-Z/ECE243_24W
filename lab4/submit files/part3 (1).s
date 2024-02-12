.global _start
_start:
	.equ COUNTER_DELAY, 500000
	.equ LED_BASE, 0xFF200000
	.equ KEY_BASE, 0xFF200050
	.equ TIMER_BASE, 0xFF202000
	movia sp, 0x20000
	movia r8, LED_BASE
	movia r9, KEY_BASE
	movia r14, TIMER_BASE
	movi r10, 0 # r10 has the counter number
	movi r12, 0 # r12 is 1, counter is going; r12 is 0, counter is paused
	movi r13, 0xFF # for resetting edge capture and comparing with 255

CONFIG_TIMER:
	stwio r0, (r14)
	movia r15, COUNTER_DELAY
	srli r16, r15, 16 # r16 has the higer 16 bits
	andi r15, r15, 0xFFFF # r15 has the lower 16 bits
	stwio r15, 0x8(r14)
	stwio r16, 0xc(r14)
	movi r15, 0b0110 # turns on start and cont of control register
	stwio r15, 0x4(r14) # makes it actually happen


POLL_KEY:
	ldwio r11, 0xc(r9) # load the edge capture register into r11
	andi r11, r11, 15
	beq r11, r0, CHECK_ADD_LOOP # edge capture register is 0, no key is pressed
	# otherwise a button is pressed
	bne r12, r0, RESET_EDGE_CAPTURE #if the counter is going, we need to stop the counter now
	br ADD_COUNT

RESET_EDGE_CAPTURE:
	stwio r13, 0xC(r9) # resets the edge capture register
	mov r12, r0
	br POLL_KEY
	
CHECK_ADD_LOOP:
	bne r12, r0, ADD_COUNT # no key pressed, add continues
	br POLL_KEY # was never adding before so we keep on polling

ADD_COUNT:
	bge r10, r13, RESET_ZERO
	stwio r13, 0xC(r9)
	movi r12, 1 # indicates that the counter has started
	addi r10, r10, 1 #increases the counter
	call DO_DELAY
	stwio r10, (r8)
	br POLL_KEY

RESET_ZERO:
	mov r10, r0
	br ADD_COUNT
	
DO_DELAY:
	subi sp, sp, 4
	stw r17, (sp)
DELAY_LOOP:
	ldwio r17, (r14)
	andi r17, r17, 0b1
	beq r17, r0, DELAY_LOOP #if the timer isnt 0 yet keep on going
	stwio r0, (r14) # if the timer reaches 0, reset
	ldw r17, (sp)
	addi sp, sp, 4
	ret





	
	
	