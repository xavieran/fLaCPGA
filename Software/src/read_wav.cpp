#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#include "bitreader.hpp"
#include "wavereader.hpp"
#include <memory>

#define CHUNK_SIZE 28192

int main(int argc, char *argv[])
{
    if(argc < 2) {
        fprintf(stderr, "usage: %s infile.wav [outfile.wav]\n", argv[0]);
        return 1;
    }

    std::shared_ptr<std::fstream> fin;
    
    
    fin = std::make_shared<std::fstream>(argv[1], std::ios::in | std::ios::binary);
    if(fin->fail()) {
        fprintf(stderr, "ERROR: opening %s for input\n", argv[1]);
        return 1;
    }

    std::shared_ptr<BitReader>fr = std::make_shared<BitReader>(fin);
    fr->refill_buffer();
    
    WaveReader *wr = new WaveReader();
    wr->read_metadata(fr);
    WaveMetaData *meta = wr->getMetaData();
    meta->print(stderr);
    
    int16_t pcm[CHUNK_SIZE];
    unsigned i;
    fprintf(stderr, "%ld samples to read\n", meta->getNumSamples());
    for (i = 0; i + CHUNK_SIZE < meta->getNumSamples(); i += CHUNK_SIZE){
        wr->read_data(fr, pcm, CHUNK_SIZE);
        for (unsigned j = 0; j < CHUNK_SIZE; j++)
            printf("%d\n", pcm[j]);
    }
    
    if (i != meta->getNumSamples()){
        int remainder = meta->getNumSamples() - i;
        wr->read_data(fr, pcm, remainder);
        for (int j = 0; j < remainder; j++){
            printf("%d\n", pcm[j]);
        }
    }
    
    fin->close();
    return 0;
}