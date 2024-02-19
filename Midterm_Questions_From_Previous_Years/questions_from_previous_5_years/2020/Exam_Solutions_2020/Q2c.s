/*********************************************************************************
 * Initialize the exception vector table
 ********************************************************************************/
        .section .vectors, "ax"

        B         _start         // reset vector
        .word    0               // undefined instruction vector
        .word    0               // software interrrupt vector
        .word    0               // aborted prefetch vector
        .word    0               // aborted data vector
        .word    0               // unused vector
        B        SERVICE_IRQ     // IRQ interrupt vector
        .word    0               // FIQ interrupt vector

/*********************************************************************************
   This program shows the digits 543210 on the HEX displays. Each digit has to be 
   selected by using the SW switches. Setting SW=0 displays 0, SW=1 displays 1, and 
   so on. The selected digit flashes on/off each .5 seconds using interrupts
 ********************************************************************************/
        .text
        .global  _start
_start:        
        /* Set up stack pointers for IRQ and SVC processor modes */
        MOV      R1, #0b11010010
        MSR      CPSR_c, R1                // change to IRQ mode
        LDR      SP, =0x40000              // set IRQ stack
        /* Change to SVC (supervisor) mode with interrupts disabled */
        MOV      R1, #0b11010011
        MSR      CPSR, R1                  // change to supervisor mode
        LDR      SP, =0x20000              // set SVC stack

        BL       CONFIG_GIC                // configure the ARM GIC
        BL       CONFIG_PRIV_TIMER         // configure the MPCore private timer

        /* enable IRQ interrupts in the processor */
        MOV      R1, #0b01010011
        MSR      CPSR_c, R1

        LDR      R2, =SEG7        // 7-segment display patterns
        LDR      R3, =WORD3_0     // memory word for HEX data
        LDR      R4, =0xFF200000  // I/O pointer
        LDR      R0, [R4, #0x40]  // read switches
        MOV      R7, #0           // initialize 7-seg pattern to 0

LOOP:   LDR      R5, =BLANK       // should display pattern or not?
        LDR      R5, [R5]         // check if we should blank
        CMP      R5, #1
        BNE      SHOW
        MOV      R7, #0           // show blank
        BEQ      NOSHOW
SHOW:   CMP      R7, #0           // currently showing blank?
        MOVEQ    R7, #1           // if it was 0, reset it to non-zero
        BEQ      NOREAD           // don't read new SW value for this loop iteration
READ:   LDR      R0, [R4, #0x40]  // read switches
        CMP      R0, #0x5         // use supports up to digit 5
        MOVGT    R0, #0           // use 0 if too large
NOREAD: LDRB     R7, [R2, R0]     // load the 7-segment pattern
NOSHOW: STRB     R7, [R3, R0]     // store to data word

        LDR      R5, [R3]         // load word for WORD3_0
        STR      R5, [R4, #0x20]  // write to HEX3_0
        LDR      R5, [R3, #4]     // load word for HEX4_0
        STR      R5, [R4, #0x30]  // write to HEX5_4
        B        LOOP
/* Configure the MPCore private timer to create interrupts every 1/2 seconds */
CONFIG_PRIV_TIMER:
        LDR      R0, =0xFFFEC600
        LDR      R1, =100000000            // timeout = 1/(200 MHz) x 100x10^6 = 0.5 sec
        STR      R1, [R0]                  // write to timer load register
        MOV      R1, #0b111                // set bits: int = 1, mode = 1 (auto), enable = 1
        STR      R1, [R0, #0x8]            // write to timer control register
        MOV      PC, LR
                   
/*--- IRQ ---------------------------------------------------------------------*/
        .global  SERVICE_IRQ
SERVICE_IRQ:
        PUSH     {R0-R7, LR}
    
        /* Read the ICCIAR from the CPU interface */
        LDR      R4, =0xFFFEC100
        LDR      R5, [R4, #0x0C]         // read the interrupt ID

PRIV_TIMER_CHECK:
        CMP      R5, #29                 // check for private timer interrupt
HERE:   BNE      HERE    
        BL       PRIV_TIMER_ISR
        /* Write to the End of Interrupt Register (ICCEOIR) */
        STR      R5, [R4, #0x10]
    
        POP      {R0-R7, LR}
        SUBS     PC, LR, #4

        .global  CONFIG_GIC
CONFIG_GIC:
        PUSH     {LR}
        /* Configure the A9 Private Timer interrupt, FPGA KEYs, and FPGA Timer
        /* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
        MOV      R0, #29
        MOV      R1, #0x01
        BL       CONFIG_INTERRUPT

        /* configure the GIC CPU interface */
        LDR      R0, =0xFFFEC100        // base address of CPU interface
        /* Set Interrupt Priority Mask Register (ICCPMR) */
        LDR      R1, =0xFFFF             // enable interrupts of all priorities levels
        STR      R1, [R0, #0x04]
        /* Set the enable bit in the CPU Interface Control Register (ICCICR). This bit
         * allows interrupts to be forwarded to the CPU(s) */
        MOV      R1, #1
        STR      R1, [R0]
    
        /* Set the enable bit in the Distributor Control Register (ICDDCR). This bit
         * allows the distributor to forward interrupts to the CPU interface(s) */
        LDR      R0, =0xFFFED000
        STR      R1, [R0]    

        POP      {PC}
/* 
 * Configure registers in the GIC for an individual interrupt ID
 * We configure only the Interrupt Set Enable Registers (ICDISERn) and Interrupt 
 * Processor Target Registers (ICDIPTRn). The default (reset) values are used for 
 * other registers in the GIC
 * Arguments: R0 = interrupt ID, N
 *            R1 = CPU target
*/
CONFIG_INTERRUPT:
        PUSH      {R4-R5, LR}

        /* Configure Interrupt Set-Enable Registers (ICDISERn). 
         * reg_offset = (integer_div(N / 32) * 4
         * value = 1 << (N mod 32) */
        LSR      R4, R0, #3                            // calculate reg_offset
        BIC      R4, R4, #3                            // R4 = reg_offset
        LDR      R2, =0xFFFED100
        ADD      R4, R2, R4                            // R4 = address of ICDISER

        AND      R2, R0, #0x1F                       // N mod 32
        MOV      R5, #1                                // enable
        LSL      R2, R5, R2                            // R2 = value

        /* now that we have the register address (R4) and value (R2), we need to set the
         * correct bit in the GIC register */
        LDR      R3, [R4]                                // read current register value
        ORR      R3, R3, R2                            // set the enable bit
        STR      R3, [R4]                                // store the new register value

        /* Configure Interrupt Processor Targets Register (ICDIPTRn)
          * reg_offset = integer_div(N / 4) * 4
          * index = N mod 4 */
        BIC      R4, R0, #3                            // R4 = reg_offset
        LDR      R2, =0xFFFED800
        ADD      R4, R2, R4                            // R4 = word address of ICDIPTR
        AND      R2, R0, #0x3                        // N mod 4
        ADD      R4, R2, R4                            // R4 = byte address in ICDIPTR

        /* now that we have the register address (R4) and value (R2), write to (only)
         * the appropriate byte */
        STRB      R1, [R4]
    
        POP      {R4-R5, PC}

/******************************************************************************
 * MPCore private timer interrupt service routine
 *****************************************************************************/
        .global  PRIV_TIMER_ISR
PRIV_TIMER_ISR:
        LDR      R0, =0xFFFEC600    // base address of timer
        MOV      R1, #1
        STR      R1, [R0, #0xC]     // write 1 to F bit to reset it
                                    // and clear the interrupt
        LDR      R0, =BLANK         // point to global variable
        LDR      R1, [R0]           // load the variable
        EOR      R1, #1             // toggle value
        STR      R1, [R0]                        // write to the global variable

        MOV      PC, LR

SEG7:    .byte    0b00111111       // '0'
         .byte    0b00000110       // '1'
         .byte    0b01011011       // '2'
         .byte    0b01001111       // '3'
         .byte    0b01100110       // '4'
         .byte    0b01101101       // '5'
         .space   2
WORD3_0: .word    0
WORD5_4: .word    0
/* Global variable */
BLANK:  .word    0x0                       // used to turn LEDR on/off
        .end   
