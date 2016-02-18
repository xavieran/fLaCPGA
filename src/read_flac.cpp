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


int read_frame(FileReader *fr){
    FLACFrameHeader *frame = new FLACFrameHeader();
    frame->read(fr);
    fprintf(stderr, "FRAME HEADER\n");
    frame->print(stderr);
    
    FLACSubFrameHeader *subframe = new FLACSubFrameHeader();
    subframe->read(fr);
    fprintf(stderr, "SUBFRAME HEADER\n");
    subframe->print(stderr);
    
    fprintf(stderr, "SUBFRAME TYPE :: %d\n\n", subframe->getSubFrameType());
    
    int samplesRead = 0;
    
    switch (subframe->getSubFrameType()){
        case 0:
        {            
            FLACSubFrameConstant *c = new FLACSubFrameConstant(frame->getSampleSize(), \
                                                               frame->getBlockSize());
            samplesRead += c->read(fr);
            printf("READED CONSTANT\n");
            break;
            
        }
        case 1:
        {
            FLACSubFrameVerbatim *v = new FLACSubFrameVerbatim(frame->getSampleSize(), \
                                                               frame->getBlockSize());
            samplesRead += v->read(fr);
            printf("READED VERBATIM\n");
            break;
        }
        case 2:
        {
            FLACSubFrameFixed *f = new FLACSubFrameFixed(frame->getSampleSize(), \
                                                         frame->getBlockSize(), \
                                                         subframe->getFixedOrder());
            samplesRead += f->read(fr);
            printf("READED FIXED\n");
            break;
        }
        case 3:
        {
            FLACSubFrameLPC *l = new FLACSubFrameLPC(frame->getSampleSize(), \
                                                    frame->getBlockSize(), \
                                                    subframe->getLPCOrder());
            samplesRead += l->read(fr);
            printf("READED LPC\n");
            break;
        }
    }
    frame->read_padding(fr);
    frame->read_footer(fr);
    
    return samplesRead;
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
    
    int totalSamples = meta->getStreamInfo()->getTotalSamples();
    
    printf("NEED TO GET %d SAMPLES !!!\n", totalSamples);
    int samplesRead = 0;
    
    
    while (samplesRead < totalSamples){
        samplesRead += read_frame(fr);
        printf("READ ::: %d samples\n", samplesRead);
    }
    
    fclose(fin);

    
    return 0;
}