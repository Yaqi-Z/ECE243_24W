#include <stdio.h>

#define AUDIO_BASE 0xFF203040
#define SAMPLE_RATE 8000 // Sample rate in Hz
#define DELAY_IN_SECONDS 0.4 // Echo delay in seconds
#define DAMPING_FACTOR 0.5 // Damping factor for the echo
#define BUFFER_SIZE 3200

struct audio_t {
    volatile unsigned int control; // The control/status register
    volatile unsigned char rarc; // the 8 bit RARC register
    volatile unsigned char ralc; // the 8 bit RALC register
    volatile unsigned char wsrc; // the 8 bit WSRC register
    volatile unsigned char wslc; // the 8 bit WSLC register
    volatile unsigned int ldata;
    volatile unsigned int rdata;
};

// Initialize the audio port structure
struct audio_t *const audiop = (struct audio_t *) AUDIO_BASE;

// Circular buffer and index for implementing the echo effect

/*
Idea: make echo buffer 
and then mix the echo with current input
after generate the output t, it will go into the echo buffer to make new echo --> [echoindex +1]
point of the echo get replace when the buffer size is full
*/


int main(void) {
    int big_buffer[BUFFER_SIZE];
    int left_input, right_input;
    int i = 0;
    while (1) {
        if (audiop->rarc > 0) { // Check if there is data to read
            // Load the input samples
            {
                left_input = audiop->ldata;
                right_input = audiop->rdata;

                // now make the output = input + damping factor * previous output with a delay of N samples
                // Mix the echo with the current input

                left_input = left_input + big_buffer[i] * DAMPING_FACTOR;
                right_input = right_input + big_buffer[i] * DAMPING_FACTOR;

                big_buffer[i] = left_input;

                audiop->ldata = left_input;
                audiop->rdata = right_input;

                i = (i + 1) % BUFFER_SIZE;

            }
        }
    }
		
}
