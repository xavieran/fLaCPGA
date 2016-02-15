/**********************************
 * Simple prog to read a flac file *
 **********************************/

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <vector>

#include "frames.hpp"
#include "subframes.hpp"
#include "metadata.hpp"

#include "bitreader.hpp"

extern "C" {
    #include "bitwriter.h"
}


int main(int argc, char *argv[])
{
    if(argc < 2) {
        fprintf(stderr, "usage: %s infile.wav [outfile.wav]\n", argv[0]);
        return 1;
    }

    FILE *fin;
    FILE *fout;
    
    int16_t * pcm;
    int32_t samples;
    
    uint8_t buffer[READSIZE];
    
    if((fin = fopen(argv[1], "rb")) == NULL) {
        fprintf(stderr, "ERROR: opening %s for input\n", argv[1]);
        return 1;
    }
    
    FileReader *fr = new FileReader(fin);
    
    FLACMetaData *meta = new FLACMetaData();
    meta->read(fr);
    meta->print(stderr);
    
    FLACFrameHeader *frame = new FLACFrameHeader();
    fprintf(stderr, "B4 frame 1 %ld\n", fr->get_current_bit());
    frame->read(fr);
    frame->print(stderr);
    
    FLACSubFrameHeader *subframe = new FLACSubFrameHeader();
    subframe->read(fr);
    subframe->print(stderr);
    
    FLACSubFrameVerbatim *verbatim = new FLACSubFrameVerbatim(16, 4096);//frame->getSampleSize(), frame->getBlockSize());
    verbatim->read(fr);
    //verbatim->print(stderr);
    
    frame->read_footer(fr);
    
    uint8_t x;
    fr->read_bits_uint8(&x, 4);
    
    fprintf(stderr, "B4 Frame 2 %ld\n", fr->get_current_bit());
    fr->reset_bit_count();
    fprintf(stderr, "AF Frame 2 %ld\n", fr->get_current_bit());
    
    frame->read(fr);
    frame->print(stderr);
    
    subframe->read(fr);
    subframe->print(stderr);
    
    
    fclose(fin);
    
    delete subframe;
    delete frame;
    delete fr;
    delete meta;
    
    return 0;
}