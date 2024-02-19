char message[] = "ECE243"; 
char blank[] =   "      "; 

// used to exit the program cleanly
char display_char(char);

/* Program that shows ECE243 on the 7-segment displays */
int main(void)
{
    char *pmessage;
    int display = 1, count = 0;
    // Set address pointers to the I/O ports
    volatile unsigned int * HEX3_HEX0_ptr = (unsigned int *) 0xFF200020;
    volatile unsigned int * HEX5_HEX4_ptr = (unsigned int *) 0xFF200030;

    while (1) {
        if (display) pmessage = message;	// point to start of message
        else pmessage = blank;            // point to blank message
        /* display message */
        *HEX5_HEX4_ptr =  display_char(*pmessage) << 8;
        *HEX5_HEX4_ptr |= display_char(*(pmessage+1));
        *HEX3_HEX0_ptr =  display_char(*(pmessage+2)) << 24;
        *HEX3_HEX0_ptr |= display_char(*(pmessage+3)) << 16;
        *HEX3_HEX0_ptr |= display_char(*(pmessage+4)) << 8;
        *HEX3_HEX0_ptr |= display_char(*(pmessage+5));

        for (count = 0; count < 500000; ++count)
            ;
        display ^= 1;   // toggle
    }
}

char display_char(char c)
{
	char seg7_code;
	switch (c)
	{
		case 'E': seg7_code = 0b1111001; break;
		case 'C': seg7_code = 0b0111001; break;
		case '2': seg7_code = 0b1011011; break;
		case '4': seg7_code = 0b1100110; break;
		case '3': seg7_code = 0b1001111; break;
      default: seg7_code = 0;
	}
	return seg7_code;
}
