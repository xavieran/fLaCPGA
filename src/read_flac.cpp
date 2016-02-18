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


void read_frame(FileReader *fr){
    FLACFrameHeader *frame = new FLACFrameHeader();
    frame->read(fr);
    fprintf(stderr, "FRAME HEADER\n");
    frame->print(stderr);
    
    FLACSubFrameHeader *subframe = new FLACSubFrameHeader();
    subframe->read(fr);
    fprintf(stderr, "SUBFRAME HEADER\n");
    subframe->print(stderr);
    
    fprintf(stderr, "SUBFRAME TYPE :: %d\n\n", subframe->getSubFrameType());
    
    
    switch (subframe->getSubFrameType()){
        case 0:
        case 1:
        case 2:
        case 3:
            FLACSubFrameLPC *l = new FLACSubFrameLPC(frame->getSampleSize(), \
                                                    frame->getBlockSize(), \
                                                    subframe->getLPCOrder());
            l->read(fr);
            printf("READED LPC\n");
            break;
    }
    frame->read_padding(fr);
    frame->read_footer(fr);
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
    
    read_frame(fr);
    read_frame(fr);
    read_frame(fr);
    read_frame(fr);
    
    fclose(fin);

    
    return 0;
}