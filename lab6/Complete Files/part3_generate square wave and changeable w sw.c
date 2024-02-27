//
/*
Part III: Write a C-language program that will generate a square wave to go to the audio output device (no input). Make
 it so that the frequency of the audio output is changeable (across the audible range from about 100Hz to 2KHz)
 using the 10 switches on the DE1-Soc to create a fine-grained selection of the frequency
*/
/*
Idea:
 - the sample are 24 bits: make the low value 0, and the biggest 24 bit value be 1? <try other number to see will it be louder?>
 task1: C code that produce the square wave:
 task2: freq adjustment: could has 2^10 distinct values
 
 Requirements:
 - code needs to generate individual, discrete samples, over tiem, such h,h,h,h,l,l,l,l,h...
 - since 8Khz  = 1 period = 0.000125s, thus the speaker is every 0.000125s
 
*/
#include <stdio.h>

#define AUDIO_BASE 0xFF203040
#define SW_BASE 0xFF200040

//Prototype

void generate_square_wave(void);
// the switches provide binary values that determ8nes the freq of the square wave
// period is T = 1/freq, high and low each is 1/2
// high state:
// delay: wait half period that calculated earlier. This delay determines how long the output remains in its current state before toggling.
// low state : set to be 0
// delay
// If a change is detected, recalculate the period and adjust the timing period of high or low status

void delay(double half_period);

int main (void){
    //Audio Codec Register address
 /*   volatile int *audio_ptr = (int*)AUDIO_BASE; //pointing to the control/status register, and use for ldwio, stwio
    volatile int *SW_ptr = (int*)SW_BASE;
    
    //freq range from 100Hz - 2000Hz
    const int minFreq = 100;
    const int maxFreq = 2000;
    int freq;

  */
    while(1){        //infinite loop using polling method
        generate_square_wave();
    }
    return 0;
}

void generate_square_wave(void){

    //Audio Codec Register address
    volatile int *audio_ptr = (int*)AUDIO_BASE; //pointing to the control/status register, and use for ldwio, stwio
    volatile int *SW_ptr = (int*)SW_BASE;
    
    //freq range from 100Hz - 2000Hz = 0.00000156s - 0.00003125s
    const int minFreq = 100;
    const int maxFreq = 2000;
    double freq;
    double curr_freq = -1;
    int sw_value;
    
    while(1){
        sw_value = *SW_ptr & 0x3FF; //enable to the 10 sw
        freq = minFreq + (sw_value * (maxFreq - minFreq) / 1023); //since 10 sw generates 2^10 binary numbers, thus the value is range from 2^0 - 2^10; = 1023
        //double period = 1 / freq; //now in s
        //double half_period = period / 2;
        double half_period = 1 / (2 * freq);
        
        // check if the freq has changed or not
        if (freq != curr_freq){
            curr_freq = freq; //update the freq to currt freq
            break; //break the loop to generate the square wave
        }
        
        *audio_ptr = 0xFF; //high
        delay(half_period);
        *audio_ptr = 0; //Low
        delay(half_period);
         
    }
    
}

void delay(double half_period){
    // dealy_
    for (int i = 0; i < half_period; i++){
        
    }
}
