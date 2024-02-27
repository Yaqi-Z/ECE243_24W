/*******************************************************************************
 * This program performs the following:
 *  1. checks if there is a sample ready to be read.
 * 	2. reads that sample from microphone channels.
 * 	3. writes that sample to the audio output channels.
 ******************************************************************************/
#define AUDIO_BASE			0xFF203040
int main(void) {
    // Audio codec Register address
    volatile int * audio_ptr = (int *) AUDIO_BASE;

    // intermediate values
    int left, right, fifospace;
	
	// This is an infinite loop checking the RARC to see if there is at least a single
	// entry in the input fifos.   If there is, just copy it over to the output fifo.
	// The timing of the input fifo controls the timing of the output

    while (1) {
        fifospace = *(audio_ptr + 1); // read the audio port fifospace register
        if ((fifospace & 0x000000FF) > 0) // check RARC to see if there is data to read
        {
            // load both input microphone channels - just get one sample from each
            int left = *(audio_ptr + 2);
            int right = *(audio_ptr + 3);
			
            // store both of those samples to output channels
            *(audio_ptr + 2) = left;
            *(audio_ptr + 3) = right;
        }
    }
}
