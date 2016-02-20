#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#include "bitreader.hpp"
#include "wavereader.hpp"

#define CHUNK_SIZE 28192

int main(int argc, char *argv[])
{
    if(argc < 2) {
        fprintf(stderr, "usage: %s infile.wav [outfile.wav]\n", argv[0]);
        return 1;
    }

    FILE *fin;
    
    
    if((fin = fopen(argv[1], "rb")) == NULL) {
        fprintf(stderr, "ERROR: opening %s for output\n", argv[1]);
        return 1;
    }

    FileReader *fr = new FileReader(fin);
    WaveReader *wr = new WaveReader();
    wr->read_metadata(fr);
    WaveMetaData *meta = wr->getMetaData();
    meta->print(stderr);
    
    int16_t pcm[CHUNK_SIZE];
    int i;
    fprintf(stderr, "%ld samples to read\n", meta->getNumSamples());
    for (i = 0; i + CHUNK_SIZE < meta->getNumSamples(); i += CHUNK_SIZE){
        wr->read_data(fr, pcm, CHUNK_SIZE);
        for (int j = 0; j < CHUNK_SIZE; j++)
            printf("%d\n", pcm[j]);
    }
    
    if (i != meta->getNumSamples()){
        int remainder = meta->getNumSamples() - i;
        wr->read_data(fr, pcm, remainder);
        for (int j = 0; j < remainder; j++){
            printf("%d\n", pcm[j]);
        }
    }
    
    fclose(fin);
    return 0;
}