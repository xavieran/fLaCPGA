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

extern "C" {
    #include "bitreader.h"
    #include "bitwriter.h"
}

#define READSIZE 1024


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
    
    struct FileReader fr = new_file_reader(fin);
    
    FLACMetaData *meta = new FLACMetaData();
    meta->read(fin);
    meta->print(stderr);
    
    FLACFrameHeader *frame = new FLACFrameHeader();
    frame->read(&fr);
    frame->print(stderr);    
    
    
    
    FLACFrameHeader *frame2 = new FLACFrameHeader();
    /*
    frame2->read(&fr);
    frame2->print(stderr);  */
    //FLACSubFrameHeader *subframe = new FLACSubFrameHeader();
/*    subframe->read(&fr);
    subframe->print(stderr);*/
    
    fclose(fin);
    
    
    return 0;
}