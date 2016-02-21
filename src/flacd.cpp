/**********************************
 * Simple prog to read a flac file *
 **********************************/

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <vector>

#include "wavereader.hpp"
#include "bitwriter.hpp"
#include "flacdecoder.hpp"

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
    
    FLACDecoder *flac_reader = new FLACDecoder(fin);
    int32_t **buf = NULL;
    
    int64_t samples = flac_reader->read(&buf);
    int channels = flac_reader->getMetaData()->getStreamInfo()->getNumChannels();
    
    if (argc == 3){
        fout = fopen(argv[2], "wb");
        BitWriter *bw = new BitWriter(fout);
        WaveMetaData *meta = new WaveMetaData(channels, 44100, 16, samples*channels);
        meta->print(stderr);
        WaveWriter * w= new WaveWriter(meta);
        w->write(bw, (int32_t **)buf);
        bw->flush();
        fclose(fout);   
    }
    
    free(buf);
    fclose(fin);
    
    return 0;
}