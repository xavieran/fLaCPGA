#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#include "bitreader.hpp"
#include "wavereader.hpp"

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
    
    int16_t pcm[4096];
    
    for (int i = 0; i < meta->getNumSamples()/4096; i++){
        wr->read_data(fr, pcm, 4096);
        for (int j = 0; j < 4096; j++)
            printf("%d\n", pcm[j]);
    }
    
    fclose(fin);
    return 0;
}