//
/*
Part II: Write a C-language program that takes the input from the microphone jack on the DE1-SoC board, and connects
 it to the output speaker jack on the board, using the audio input and output system described in class. From class,
 you will know that this involves collecting samples of the input from the input FIFO of the audio interface and
 sending them to the output FIFO.
 
 “Audio recording is functional, but will record a sawtooth wave with period 32 samples (250 Hz at 8 kHz sampling
 rate).
 uses the 8khz
 sampling rate, and it is here: https://cpulator.01xz.net/?sys=nios-de1soc.
*/
/*
Idea:
Input = output
*/
#define AUDIO_BASE 0xFF203040

int main (void){
    //Audio Codec Register address
    volatile int*audio_ptr = (int*)AUDIO_BASE; //pointing ti tge control/status register, and use for ldwio, stwio
    
    // intermediate values
    int left,right, fifospace;
    // An inf loop checking the RARC to see if there is at least one entry in the input FIFOs.
    // if there is, just copy it over to the output fifo
    // the timing of the input fifo controls the timing of the oputput
    while(1){        //infinite loop using polling method
        fifospace = *(audio_ptr +1); //read the audio port fifospace register,
                                    // add 1 since we are interested in RARC, and we dont want the 1st address that control status register,
                                    // 1 = 4 bytes
        if ((fifospace & 0x000000FF) > 0) // isolate and only check RARC to see if there is data to read
        {
            // load both input microphone channels - just get one sample from each
            int left = *(audio_ptr + 2); // +2 to the left data
            int right = *(audio_ptr + 3); // +3 to the right data
            
            // store both of those samples to output channels
            *(audio_ptr + 2) = left;  // store, put it to the output fifo
            *(audio_ptr + 3) = right;
        }
    }
}
    
