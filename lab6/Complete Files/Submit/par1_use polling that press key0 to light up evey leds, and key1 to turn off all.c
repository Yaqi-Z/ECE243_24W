/*
Part I: Write a C-language program that turns on all ten Red LEDs when button KEY0 is pressed and
released, and turns them off when KEY1 is pressed and released.

Do not use interrupts, just use polling on the edge capture register.
*/
/*
Idea: 
1.Initialize: Set up the LEDs and button edge capture registers.
2.Polling Loop:
-Continuously check the edge capture register to detect a button press and release.
-When KEY0 is pressed and released, turn on all LEDs.
-When KEY1 is pressed and released, turn off all LEDs.
-Clear the edge capture register after detecting a press and release to be ready for the next event.
*/

int main (void){
    volatile int*LEDR_ptr = 0xFF200000;
    volatile int*KEY_ptr = 0xFF200050;
    int value;
    
    *LEDR_ptr = 0; //initialize, to turn off all the leds
    
    while(1){        //infinite loop using polling method
        // 1st: to get the value of the key pointer
        value = *KEY_ptr;
        
        //check if key0 is pressed
        if (value & 0x1){ //isloate key 0
            *LEDR_ptr = 0x3FF; //Turn on all ten Red LEDs (binary 1111111111)
            *KEY_ptr = 0x1; // wirte 1 to turn the edge capture to 0
        }
        //check if key1 is pressed
        if (value & 0x2){ //isoloate key 1
            *LEDR_ptr = 0; //Turn on all ten Red LEDs (binary 1111111111)
            *KEY_ptr = 0x2;
        }
       
    }
    
}