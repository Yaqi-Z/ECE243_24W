#define AUDIO_BASE 0xFF203040
int main(void) {
	// Audio port structure
	struct audio_t {
	volatile unsigned int control; // The control/status register
	volatile unsigned char rarc; // the 8 bit RARC register
	volatile unsigned char ralc; // the 8 bit RALC register
	volatile unsigned char wsrc; // the 8 bit WSRC register
	volatile unsigned char wslc; // the 8 bit WSLC register
	volatile unsigned int ldata;
	volatile unsigned int rdata;
	};

	struct audio_t *const audiop = ((struct audio_t *) AUDIO_BASE);
	volatile int *swp = 0xff200040;

    // unsigned int period_samples = 8000 / frequency; // Total samples per period
	int frequency;
    int high = 0x0FFFFFF; 
    int low = 0; 
    int value = 0; 
	int halfWaveSamples;
	int sampleCount = 0;

    while (1) {
		
		frequency = 100 + (*swp % 10) * 190; // maps 0-9 switch value to 100Hz to 2000Hz
		halfWaveSamples = 8000/(2*frequency); // recalculate for the current frequency
		
        // Toggle the value every half wave cycle
        if (sampleCount >= halfWaveSamples) {
			//Checks if the sampleCount has reached the number of samples for half a waveform. 
			//If so, it toggles value between high and low to generate a square wave and resets sampleCount.
            value = (value == high) ? low : high;
      
			
			sampleCount = 0; // Reset the counter after one complete cycle
        }

        // Check if there's space in the FIFO before writing
        if (audiop->wsrc > 0) {
            audiop->ldata = value; // Write to left channel
            audiop->rdata = value; // Write to right channel
        }
		sampleCount++;
    }
}