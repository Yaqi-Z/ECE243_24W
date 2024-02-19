int main(void)
{
    int pattern = 1;
	 volatile int * LEDR_ptr = (int *) 0xFF200000;
    volatile int * KEY_ptr = (int *) 0xFF200050;
	 volatile int * Timer_ptr = (int *) 0xFF202000;
	 int count = 0, dir = 1;

    /* set up the FPGA timer */
    count = 25000000;               // 1/(100 MHz) x 25x10^6 = 0.25 sec
    *(Timer_ptr+2) = count;
    *(Timer_ptr+3) = count >> 16;
    *(Timer_ptr+1) = 0x6;           // start timer
	 while (1) {
        /* display scrolling light */
        *LEDR_ptr = pattern;
        /* wait for timer */
        while ((*Timer_ptr & 1) == 0)
            ;
        *Timer_ptr = 0;             // reset timeout bit

        if (dir) {                  // left
            pattern = pattern << 1;
            if (pattern == 0b10000000000)
                pattern = 1;
        }
        else {                      // right
            pattern = pattern >> 1;
            if (pattern == 0)
                pattern = 0b1000000000;
        }
        if (*(KEY_ptr + 3))         // check for KEY press
        {
            dir ^= 1;
            *(KEY_ptr + 3) = 0xF;   // clear KEY
        }
    }
}
