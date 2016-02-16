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
    fprintf(stderr, "METADATA\n");
    meta->print(stderr);
    
    
    FLACFrameHeader *frame = new FLACFrameHeader();
    
    frame->read(fr);
    fprintf(stderr, "FRAME HEADER\n");
    frame->print(stderr);
    FLACSubFrameHeader *subframe = new FLACSubFrameHeader();
    subframe->read(fr);
    fprintf(stderr, "SUBFRAME HEADER\n");
    subframe->print(stderr);
    
    /*FLACSubFrameFixed *fixed = new FLACSubFrameFixed(frame->getSampleSize(),\
                                                        frame->getBlockSize(), \
                                                        subframe->getFixedOrder());
    fixed->read(fr);*/
    
    FLACSubFrameVerbatim *v = new FLACSubFrameVerbatim(frame->getSampleSize(), frame->getBlockSize());
    v->read(fr);
    
    frame->read_footer(fr);
    frame->read(fr);
    frame->print(stderr);
    
    subframe->read(fr);
    subframe->print(stderr);
    
    v->read(fr);
    
    frame->read_footer(fr);
    
    fclose(fin);
    
    delete subframe;
    delete frame;
    delete fr;
    delete meta;
    
    return 0;
}