/******************************************************************************
 * Write an interrupt service routine
 *****************************************************************************/
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
        beq     r20, r0, END_ISR    # if not, ignore this interrupt
		
        call    KEY_ISR             # if yes, call the pushbutton ISR
		
END_ISR:
        ldw     et, 0(sp)           # restore registers
        ldw     ra, 4(sp)
        ldw     r20, 8(sp)
        ldw     ea, 12(sp)
        addi    sp, sp, 16          # restore stack pointer

        eret                        # return from exception

/*********************************************************************************
 * set where to go upon reset
 ********************************************************************************/
.section .reset, "ax"
        movia   r8, _start
        jmp    r8

/*********************************************************************************
 * Main program
 ********************************************************************************/
.equ HEX_BASE1, 0xff200020
.equ HEX_BASE2, 0xff200030
.equ KEY_BASE, 0xff200050

.text
.global  _start
_start:
	# Initialize the stack pointer
	movia sp, 0x20000 
	
	# set up keys to generate interrupts
	movia r2, KEY_BASE
	movi r3, 0xF
	movi r4, 0x1 # also for checking key 0
	stwio r3, 0xC(r2) # clears the edge capture register of all keys
	stwio r3, 8(r2) # turns on interrupt mask reg for keys
	
	# enable interrupts in NIOS II
	movi r5, 0x2 # also for checking key1
	wrctl ctl3, r5 # enables interrupts from the KEY buttons
	wrctl ctl0, r4 # turns PIE to 1, allows interrupts in general to happen, still in supervisor mode
	
MAIN:
	# the main program doesn't do much ngl      
IDLE:   br  IDLE

KEY_ISR: 
	# stack everything from non-interrupt onto the stack
	# ***************EDIT THIS FOR CLOBBERED REGISTERS ***************#
	subi sp, sp, 32
	stw r4, 0(sp)
	stw r5, 4(sp)
	stw r6, 8(sp)
	stw r7, 12(sp)
	stw r8, 16(sp)
	stw r9, 20(sp)
	stw r10, 24(sp)
	stw r11, 28(sp)
	
	movi r9, 4 # for checking key 2
	movi r10, 8 # for checking key 3
	ldwio r11, 0xc(r2) # check the edge capture register to see which button was pressed
	andi r11, r11, 0xF # isolate the key
	beq r11, r4, KEY0 # key 0 did it
	beq r11, r5, KEY1 # key 1 did it
	beq r11, r9, KEY2 # key 2 did it
	beq r11, r10, KEY3 # key 3 did it
	
CLEAR_HEX:
	movi r4, 0b10000
	br DISPLAY
	
KEY0:
	mov r5, r0
	movia r8, HEX_BASE1
	ldwio r11, (r8) # read the LED lights and see if anything is in there
	andi r11, r11, 0x3F
	bne r11, r0, CLEAR_HEX # if there is something in there
	mov r4, r0
	br DISPLAY
	
KEY1:
	movi r5, 1
	movia r8, HEX_BASE1
	ldwio r11, (r8)
	andi r11, r11, 0x3F00
	bne r11, r0, CLEAR_HEX
	movi r4, 1
	br DISPLAY
	
KEY2:
	movi r5, 2
	movia r8, HEX_BASE1
	ldwio r11, (r8)
	andhi r11, r11, 0x3F
	bne r11, r0, CLEAR_HEX
	movi r4, 2
	br DISPLAY

KEY3:
	movi r5, 3
	movia r8, HEX_BASE1
	ldwio r11, (r8)
	andhi r11, r11, 0x3F00
	bne r11, r0, CLEAR_HEX
	movi r4, 3
	br DISPLAY

DISPLAY:
	subi sp, sp, 4
	stw ra, (sp)
	call HEX_DISP
	ldw ra, (sp)
	addi sp, sp, 4
	movia r2, KEY_BASE
	stwio r3, 0xc(r2) # to reset the edge cpature register
	
	# **** WE ARE ABOUT TO LEAVE THE INTERRUPT POP EVERYTHING OFF THE STACK ******
	
	ldw r11, 28(sp)
	ldw r10, 24(sp)
	ldw r9, 20(sp)
	ldw r8, 16(sp)
	ldw r7, 12(sp)
	ldw r6, 8(sp)
	ldw r5, 4(sp)
	ldw r4, 0(sp)
	addi sp, sp, 32
	ret
	
# once again this subroutine does the following
# r4 takes in 4 bit value which is the number to be displayed ont he hex
# bit 5 of r4 will blank the hex indicated if 1
# r5 will take in a number that tells us which hex to display it on
HEX_DISP:   
		movia    r8, BIT_CODES         # starting address of the bit codes
	    andi     r6, r4, 0x10	   # get bit 4 of the input into r6
	    beq      r6, r0, not_blank 
	    mov      r2, r0
	    br       DO_DISP
		
not_blank:  andi     r4, r4, 0x0f	   # r4 is only 4-bit
            add      r4, r4, r8            # add the offset to the bit codes
            ldb      r2, 0(r4)             # index into the bit codes

#Display it on the target HEX display
DO_DISP:    
			movia    r8, HEX_BASE1         # load address
			movi     r6,  4
			blt      r5,r6, FIRST_SET      # hex4 and hex 5 are on 0xff200030
			sub      r5, r5, r6            # if hex4 or hex5, we need to adjust the shift
			addi     r8, r8, 0x0010        # we also need to adjust the address
FIRST_SET:
			slli     r5, r5, 3             # hex*8 shift is needed
			addi     r7, r0, 0xff          # create bit mask so other values are not corrupted
			sll      r7, r7, r5 
			addi     r4, r0, -1
			xor      r7, r7, r4  
    		sll      r4, r2, r5            # shift the hex code we want to write
			ldwio    r5, 0(r8)             # read current value       
			and      r5, r5, r7            # and it with the mask to clear the target hex
			or       r5, r5, r4	           # or with the hex code
			stwio    r5, 0(r8)		       # store back
END:			
			ret
			
BIT_CODES:  .byte     0b00111111, 0b00000110, 0b01011011, 0b01001111
			.byte     0b01100110, 0b01101101, 0b01111101, 0b00000111
			.byte     0b01111111, 0b01100111, 0b01110111, 0b01111100
			.byte     0b00111001, 0b01011110, 0b01111001, 0b01110001

            .end
			