// This program shows the digits 543210 on the HEX displays. Each digit has to be selected
//  by using the SW switches. Setting SW=0 displays 0, SW=1 displays 1, and so on.
         .text
         .global  _start
_start:  LDR      R2, =SEG7        // 7-segment display patterns
         LDR      R3, =WORD3_0     // memory word for HEX data
         LDR      R4, =0xFF200000  // I/O pointer
         LDR      R0, [R4, #0x40]  // read switches

LOOP:    LDR      R0, [R4, #0x40]  // read switches
         CMP      R0, #0x5         // use supports up to digit 5
         MOVGT    R0, #0           // use 0 if too large
         LDRB     R7, [R2, R0]     // load the 7-segment pattern
         STRB     R7, [R3, R0]     // store to data word

         LDR      R5, [R3]         // load word for WORD3_0
         STR      R5, [R4, #0x20]  // write to HEX3_0
         LDR      R5, [R3, #4]     // load word for HEX4_0
         STR      R5, [R4, #0x30]  // write to HEX5_4
         B        LOOP

SEG7:    .byte    0b00111111       // '0'
         .byte    0b00000110       // '1'
         .byte    0b01011011       // '2'
         .byte    0b01001111       // '3'
         .byte    0b01100110       // '4'
         .byte    0b01101101       // '5'
         .space   2
WORD3_0: .word    0
WORD5_4: .word    0
Blank:   .word    0
