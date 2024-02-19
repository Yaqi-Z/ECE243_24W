char message[] = "U of t ECE-243      U of t"; 

// used to exit the program cleanly
char display_char(char);
void start_timer (volatile int *, int);
void stop_timer (volatile int *);

/* Program that scrolls a message across the 7-segment displays */
int main(void)
{
    char *pmessage;
    // Set address pointers to the I/O ports
    volatile int * HEX3_HEX0_ptr = (int *) 0xFF200020;
    volatile int * HEX5_HEX4_ptr = (int *) 0xFF200030;
    volatile int * KEY_ptr = (int *) 0xFF200050;
    volatile int * Timer_ptr = (int *) 0xFF202000;
    int count = 0, scroll = 1, dir = 1;
    int press = 0;                // to hold KEY port data

    /* set up the FPGA timer */
    count = 50000000;             // 1/(100 MHz) x 50x10^6 = 0.5 sec
    start_timer (Timer_ptr, count);
    pmessage = message;           // point to start of message
    while (1)                        
    {
        /* display scrolling message */
        *HEX5_HEX4_ptr =  display_char(*pmessage) << 8;
        *HEX5_HEX4_ptr |= display_char(*(pmessage+1));
        *HEX3_HEX0_ptr =  display_char(*(pmessage+2)) << 24;
        *HEX3_HEX0_ptr |= display_char(*(pmessage+3)) << 16;
        *HEX3_HEX0_ptr |= display_char(*(pmessage+4)) << 8;
        *HEX3_HEX0_ptr |= display_char(*(pmessage+5));

        if (scroll) {
            if (dir) {
                ++pmessage;
                if (pmessage >= message + 20) // check for "wrap around"
                    pmessage = message;
            }
            else {
                --pmessage;
                if (pmessage <= message)      // check for "wrap around"
                    pmessage = message + 20;
            }
        }
        if ((press = *(KEY_ptr + 3)))         // check for KEY press
        {
            if (press & 0b1) {
                scroll ^= 1;
                *(KEY_ptr + 3) = 0b1;         // clear KEY
            }
            else if (press & 0b10) {
                stop_timer (Timer_ptr);
                count = count >> 1;
                *(KEY_ptr + 3) = 0b10;        // clear KEY
                start_timer (Timer_ptr, count);
            }
            else if (press & 0b100) {
                stop_timer (Timer_ptr);
                count = count << 1;
                *(KEY_ptr + 3) = 0b100;       // clear KEY
                start_timer (Timer_ptr, count);
            }
            else {
                dir ^= 1;
                *(KEY_ptr + 3) = 0b1000;      // clear KEY
            }
        }
        /* wait for timer */
        while ((*Timer_ptr & 1) == 0)
            ;
        *Timer_ptr = 0;                   // reset timeout bit
    }
    return 0;
}

void start_timer (volatile int *Timer_ptr, int count) {
    *(Timer_ptr+2) = count;
    *(Timer_ptr+3) = count >> 16;
    *(Timer_ptr+1) = 0x6;                 // start timer
}

void stop_timer (volatile int *Timer_ptr) {
    *(Timer_ptr+1) = 0x0;                 // stop timer
}

char display_char(char c)
{
    char seg7_code;
    switch (c)
    {
        case 'U': seg7_code = 0b0111110; break;
        case 'o': seg7_code = 0b1011100; break;
        case 'f': seg7_code = 0b1110001; break;
        case 't': seg7_code = 0b1111000; break;
        case 'E': seg7_code = 0b1111001; break;
        case 'C': seg7_code = 0b0111001; break;
        case '2': seg7_code = 0b1011011; break;
        case '4': seg7_code = 0b1100110; break;
        case '3': seg7_code = 0b1001111; break;
        case ' ': seg7_code = 0b0000000; break;
        case '-': seg7_code = 0b1000000; break;
      default: seg7_code = 0;
    }
    return seg7_code;
}

