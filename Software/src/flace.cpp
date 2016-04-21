/* flace*/
#include <getopt.h>
#include<ctype.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <vector>

#include "metadata.hpp"
#include "wavereader.hpp"
#include "bitwriter.hpp"
#include "flacencoder.hpp"


void exit_with_help(char *argv[]){
    fprintf(stderr, "usage: %s [ OPTIONS ] infile.flac [outfile.wav]\n", argv[0]);
    fprintf(stderr, "  -f : Use fixed frames\n");
    fprintf(stderr, "  -v : Encode verbatim (no compression)\n");
    exit(1);
}

int main(int argc, char *argv[]){
    int opt = 0, fixed = 0, verbatim = 0, decode = 1;
    int print_residuals = 0;
    while ((opt = getopt(argc,argv,"fv:")) != EOF)
        switch(opt)
        {
            case 'f': fixed = 1; break;
            case 'v': verbatim = 1; break;
            case 'h':
            case '?': 
            default:
                exit_with_help(argv);
        }
        
    std::shared_ptr<std::fstream> fin;
    std::shared_ptr<std::fstream> fout;
    
    if (optind == 1) exit_with_help(argv);
    
    if (optind < argc){
        fin = std::make_shared<std::fstream>(argv[optind], std::ios::in | std::ios::binary);
        if(fin->fail()) {
            fprintf(stderr, "ERROR: opening %s for input\n", argv[optind]);
            return 1;
        }
    }
        
    if (decode){
        fout = std::make_shared<std::fstream>(argv[optind + 1], std::ios::out | std::ios::binary);
        if(fout->fail()) {
            fprintf(stderr, "ERROR: opening %s for output\n", argv[optind + 1]);
            return 1;
        }
    }
    
    auto fr = std::make_shared<BitReader>(fin);
    WaveReader *wr = new WaveReader();
    wr->read_metadata(fr);
    WaveMetaData *meta = wr->getMetaData();
    meta->print(stderr);
    
    int spb = 4096;
    
    int16_t pcm[spb];
    int32_t pcm32[spb];
    unsigned i;
    fprintf(stderr, "%ld samples to read\n", meta->getNumSamples());
    auto fe = FLACEncoder(fout);
    fe.setSamples(meta->getNumSamples());
    fe.write_header();
    
    for (i = 0; i + spb < meta->getNumSamples(); i += spb){
        wr->read_data(fr, pcm, spb);
        for (unsigned j = 0; j < spb; j++) pcm32[j] = pcm[j];
        fe.write_frame(pcm32, spb, i/spb);
    }
    
    if (i != meta->getNumSamples()){
        int remainder = meta->getNumSamples() - i;
        wr->read_data(fr, pcm, remainder);
        for (int j = 0; j < remainder; j++){
        }
    }
    
}