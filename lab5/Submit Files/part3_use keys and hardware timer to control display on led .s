.section .exceptions, "ax"

IRQ_HANDLER:
        # save registers on the stack (et, ra, ea, others as needed)
        subi    sp, sp, 16          # make room on the stack
        stw     et, 0(sp)
        stw     ra, 4(sp)
        stw     r20, 8(sp)

        rdctl   et, ctl4            # read exception type
        beq     et, r0, SKIP_EA_DEC # not external?
        subi    ea, ea, 4           # decrement ea by 4 for external interrupts

SKIP_EA_DEC:
        stw     ea, 12(sp)
        andi    r20, et, 0x2        # check if interrupt is from pushbuttons
        beq     r20, r0, CHECK_TIMER    # if not, ignore this interrupt
        call    KEY_ISR             # if yes, call the pushbutton ISR
		
		# check timer interrupt
		
CHECK_TIMER:
		andi r20, et, 0x1 # check if interrupt is from the timer
		beq r20, r0, END_ISR # if not from the timer or keys ggs somethings wrong
		call TIMER_ISR # if yes it means the timer has reached 0
		
END_ISR:
        ldw     et, 0(sp)           # restore registers
        ldw     ra, 4(sp)
        ldw     r20, 8(sp)
        ldw     ea, 12(sp)
        addi    sp, sp, 16          # restore stack pointer

        eret                        # return from exception


.equ LED_BASE, 0xff200000
.equ TIMER_BASE, 0xff202000
.equ KEY_BASE, 0xff200050
.equ COUNTER_DELAY, 5000000

.text
.global  _start
_start:
    /* Set up stack pointer */
	movia sp, 0x20000
    call    CONFIG_TIMER        # configure the Timer
    call    CONFIG_KEYS         # configure the KEYs port
    /* Enable interrupts in the NIOS-II processor */
	
	# enable interrupts in NIOS II
	movi r4, 0x1
	movi r5, 0x3 
	wrctl ctl3, r5 # for enabling interrupts from keys and timer
	wrctl ctl0, r4 # turns PIE to 1, allows interrupts in general to happen, still in supervisor mode
    
	movia   r8, LED_BASE        # LEDR base address (0xFF200000)
    movia   r9, COUNT           # global variable
	movia r10, RUN # ALSO GLOBAL
	
	stw r4, (r10) # sets the initial RUN to 1
	stw r0, (r9) # sets the initial COUNT to 0
	
	br LOOP
	
CONFIG_TIMER:
	movia r2, TIMER_BASE
	stwio r0, (r2)
	movia r3, COUNTER_DELAY
	srli r4, r3, 16 # r16 has the higer 16 bits
	andi r5, r3, 0xFFFF # r15 has the lower 16 bits
	stwio r5, 0x8(r2)
	stwio r4, 0xc(r2)
	movi r3, 0b1111 # turns on start and cont and interrupt of control register
	stwio r3, 0x4(r2) # makes it actually happen
	ret
	
CONFIG_KEYS:
	# set up keys to generate interrupts
	movia r5, KEY_BASE
	movi r3, 0xF
	stwio r3, 0xC(r5) # clears the edge capture register of all keys
	stwio r3, 8(r5) # turns on interrupt mask reg for keys
	ret

LOOP:
    ldw     r10, 0(r9)          # global variable
    stwio   r10, 0(r8)          # write to the LEDR lights
    br      LOOP

KEY_ISR:
	subi sp, sp, 16
	stw r5, 0(sp)
	stw r6, 4(sp)
	stw r10, 8(sp)
	stw r11, 12(sp)

	movia r5, KEY_BASE
	movia r10, RUN # ALSO GLOBAL
	ldw r11, (r10) # check RUN
	beq r11, r0, START_TIMER # if run is currently 0 we will start it again
	
	# otherwise its currently on and we must pause the timer
	stw r0, (r10) # KEY is now 0
	movi r6, 0b1010
	stwio r6, 0x4(r2) # stop the timer
	stwio r0, (r2)
	movia r5, KEY_BASE
	stwio r3, 0xC(r5) # reset edge capture register
	
	ldw r11, 12(sp)
	ldw r10, 8(sp)
	ldw r6, 4(sp)
	ldw r5, 0(sp)
	addi sp, sp, 16
	ret # otherwise no adding occurs
	
START_TIMER:
	stw r4, (r10) # makes the RUN variable 1 meaning its now running
	movi r5, 0b0111
	stwio r5, 0x4(r2) # start the timer
	stwio r0, (r2)
	movia r5, KEY_BASE
	stwio r3, 0xC(r5) # reset edge capture register'
	
	ldw r11, 12(sp)
	ldw r10, 8(sp)
	ldw r6, 4(sp)
	ldw r5, 0(sp)
	addi sp, sp, 16
	ret
	
TIMER_ISR:
	subi sp, sp, 16
	stw r5, 0(sp)
	stw r6, 4(sp)
	stw r10, 8(sp)
	stw r11, 12(sp)
	movia r2, TIMER_BASE
	stwio r0, (r2) # resets the interrupt bit
	
	subi sp, sp, 4
	stw ra, (sp)
	call ADD_COUNT
	ldw ra, (sp)
	addi sp, sp, 4
	
	ldw r11, 12(sp)
	ldw r10, 8(sp)
	ldw r6, 4(sp)
	ldw r5, 0(sp)
	addi sp, sp, 16
	ret
	
ADD_COUNT:
	ldwio  r10, (r8) # loads value from led light to r10
	addi r10, r10, 1 # increase count
	stw r10, (r9) # stores back into count
	ret # leave timer interrupt
	

.data
/* Global variables */
.global  COUNT
COUNT:  .word    0x0            # used by timer

.global  RUN                    # used by pushbutton KEYs
RUN:    .word    0x1            # initial value to increment COUNT

.end