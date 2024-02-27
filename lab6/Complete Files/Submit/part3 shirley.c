#include <stdio.h>
#include <stdlib.h>
#include <math.h>
	
int samples_n = 80000; // audio will run for 30s

void square_wave_gen(int *samples, double frequency){
	int low = 1;
	int multiplier = 1;
	double fund_period = 1 / frequency;
	double sample_per_period = fund_period / 0.000125;
	for (int i = 0; i < samples_n; i++){
		if(i < multiplier * sample_per_period/2 && low){
			samples[i] = 0;
		}
		else if (i == multiplier * round(sample_per_period/2) && low){
			multiplier++;
			low = 0;
			samples[i] = 0x0FFFFFFF;
		}
		else if (i == multiplier * round(sample_per_period/2) && !(low)){
			multiplier++;
			low = 1;
			samples[i] = 0;
		}
		else{
			samples[i] = 0x0FFFFFFF;
		}
	
	}
}

struct audio_t {
	volatile unsigned int control;
	volatile unsigned char rarc;
	volatile unsigned char ralc;
	volatile unsigned char warc;
	volatile unsigned char walc;
    volatile unsigned int ldata;
	volatile unsigned int rdata;
};

struct audio_t *const audiop = ((struct audio_t *)0xff203040);


void play_audio(int *samples, int n) {
    int i;
    audiop->control = 0x8; // clear the output FIFOs
    audiop->control = 0x0; // resume input conversion
    for (i = 0; i < n; i++) {
        // output data if there is space in the output FIFOs
        if (audiop->warc) {
            audiop->ldata = samples[i];
            audiop->rdata = samples[i];
        }
    }
}


int main(){
    // Write C code here
	int samples_n = 240000; // audio will run for 30s
	int* samples; 
	samples = (int*)calloc(samples_n, sizeof(int));
	volatile int *SW_ptr = 0xFF200040;
	while (1){
		int SW_value = *SW_ptr;
		switch(SW_value){
			case 0b1:
				square_wave_gen(samples, 100);
				play_audio(samples,samples_n);
				break;
			case 0b10:
				square_wave_gen(samples, 200);
				play_audio(samples,samples_n);
				 break;
			case 0b100:
				square_wave_gen(samples, 400);
				play_audio(samples,samples_n);
				break;
			case 0b1000:
				square_wave_gen(samples, 800);
				play_audio(samples,samples_n);
				break;
			case 0b10000:
				square_wave_gen(samples, 1000);
				play_audio(samples,samples_n);
				break;
			case 0b100000:
				square_wave_gen(samples, 2000);
				play_audio(samples,samples_n);
				break;
			/*case 0b1000000:
				square_wave_gen(samples, );
				play_audio(samples,samples_n);
				break;
			case 0b10000000:
				square_wave_gen(samples,);
				play_audio(samples,samples_n);
				break;
			case 0b100000000:
				square_wave_gen(samples, );
				play_audio(samples,samples_n);
				break;
			case 0b1000000000:
				square_wave_gen(samples, );
				play_audio(samples,samples_n);
				break;*/
			default:
				square_wave_gen(samples, 1000);
				play_audio(samples,samples_n);
				
		}
	}
}