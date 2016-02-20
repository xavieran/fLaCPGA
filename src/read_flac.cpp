/**********************************
 * Simple prog to read a flac file *
 **********************************/

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <vector>

#include "flacreader.hpp"

int main(int argc, char *argv[])
{
    if(argc < 2) {
        fprintf(stderr, "usage: %s infile.wav [outfile.wav]\n", argv[0]);
        return 1;
    }

    FILE *fin;
    FILE *fout;
    
    if((fin = fopen(argv[1], "rb")) == NULL) {
        fprintf(stderr, "ERROR: opening %s for input\n", argv[1]);
        return 1;
    }
    
    FLACReader *flac_reader = new FLACReader(fin);
    int32_t *buf = NULL;
    
    int64_t samples = flac_reader->read(&buf);
    
    int i;
    for (i = 0; i < samples; i++){
        printf("%d\n", buf[i]);
    }
    
    free(buf);
    fclose(fin);

    
    return 0;
}