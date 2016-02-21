/**********************************
 * Simple prog to read a flac file *
 **********************************/

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
#include "flacdecoder.hpp"

void exit_with_help(char *argv[]){
    fprintf(stderr, "usage: %s [ OPTIONS ] infile.flac [outfile.wav]\n", argv[0]);
    fprintf(stderr, "  -m : Print fLaC metadata headers\n");
    fprintf(stderr, "  -M : Print ALL metadata. This includes frame and subframe headers.\n");
    fprintf(stderr, "  -p : Print input file PCM values, interleaved\n");
    fprintf(stderr, "  -d : Decode input file to WAV\n");
    exit(1);
}

int main(int argc, char *argv[]){
    int opt = 0, metadata = 0, all_metadata = 0, print_pcm = 0, decode = 0;
    while ((opt = getopt(argc,argv,"mMpdh:")) != EOF)
        switch(opt)
        {
            case 'm': metadata = 1; break;
            case 'M': all_metadata = 1; break;
            case 'p': print_pcm = 1; break;
            case 'd': decode = 1; break;
            case 'h':
            case '?': 
            default:
                exit_with_help(argv);
        }
        
    FILE *fin = NULL;
    FILE *fout = NULL;    
    
    if (optind == 1) exit_with_help(argv);
    
    if (optind < argc)
        if((fin = fopen(argv[optind], "rb")) == NULL) {
            fprintf(stderr, "ERROR: opening %s for input\n", argv[optind]);
            return 1;
        }
        
    if (optind + 1 < argc)
        if((fout = fopen(argv[optind + 1], "wb")) == NULL) {
            fprintf(stderr, "ERROR: opening %s for output\n", argv[optind + 1]);
            return 1;
        }
        
    FLACDecoder *flac_reader = new FLACDecoder(fin);
    int32_t **buf = NULL;
    
    if (metadata){
        /* Print file header and metadata*/
        flac_reader->print_meta();
    } else if (all_metadata){
        flac_reader->print_all_metadata();
        /* Print each frame... */
    } else if (print_pcm){
        /* Print the PCM values to stdout, interleaved */        
        BitWriter *bw = new BitWriter(fout);
        /* First get flac stream info */
        flac_reader->read_meta();
        FLACMetaStreamInfo *info = flac_reader->getMetaData()->getStreamInfo();
        
        int channels = info->getNumChannels();
        int intraSamples = info->getTotalSamples();
        
        buf = (int32_t **)malloc(sizeof(int32_t *)*channels);
    
        for (int ch = 0; ch < channels; ch++)
            buf[ch] = (int32_t *)malloc(sizeof(int32_t)*intraSamples);
        
        /* Now read and print a frame at a time */
        int64_t samples = 0;        
        int current_sample_size = 0;
        while (samples < intraSamples){
            current_sample_size = flac_reader->read_frame(buf, 0) / channels;
            samples += current_sample_size;
            for (int i = 0; i < current_sample_size; i++)
                for (int ch = 0; ch < channels; ch++)
                    fprintf(stdout, "%d\n", buf[ch][i]);
        }
        
        for (int ch = 0; ch < channels; ch++)
            free(buf[ch]);
        free(buf);
        fclose(fin);
        
    } else if (fout == NULL){
        /* Print file header and metadata*/
        flac_reader->read_meta();
        flac_reader->getMetaData()->print(stdout);
    } else if (decode || !decode){ // Haha
        
        BitWriter *bw = new BitWriter(fout);
        /* First get flac stream info */
        flac_reader->read_meta();
        FLACMetaStreamInfo *info = flac_reader->getMetaData()->getStreamInfo();
        
        int channels = info->getNumChannels();
        int intraSamples = info->getTotalSamples();
        
        buf = (int32_t **)malloc(sizeof(int32_t *)*channels);
    
        for (int ch = 0; ch < channels; ch++)
            buf[ch] = (int32_t *)malloc(sizeof(int32_t)*intraSamples);
        
        /* Now set the WAVE file info and write it's header. */
        WaveMetaData *meta = new WaveMetaData(channels, 44100, 16, 0);
        WaveWriter * w = new WaveWriter(meta);
        meta->write(bw);
        
        /* Now read and write a frame at a time */
        int64_t samples = 0;        
        int current_sample_size = 0;
        while (samples < intraSamples){
            current_sample_size = flac_reader->read_frame(buf, 0) / channels;
            w->write_data(bw, buf, current_sample_size);
            samples += current_sample_size;
            bw->flush();
        }
        
        /* Now that we have the correct number of samples, we rewrite the header */
        meta->setNumSamples(samples*channels);
        bw->reset();
        meta->write(bw);
        bw->flush();
        
        for (int ch = 0; ch < channels; ch++)
            free(buf[ch]);
        free(buf);
        fclose(fin);
        fclose(fout);
    }
    
    /*
    if (buf != NULL)
        free(buf); // FIXME: You're doing this wrong... 
    if (fin != NULL)
        fclose(fin);
    if (fout != NULL)
        fclose(fout);
    */
    return 0;
}