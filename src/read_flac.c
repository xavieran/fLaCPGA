/**********************************
 * Simple prog to read a wav file *
 **********************************/

/* Lot's of this code borrowed from libFLAC */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "read_write.h"


/* **********   Structs ********** */
struct FLACMetaBlockHeader {
    uint8_t last_block;
    uint8_t block_type;
    uint32_t block_length;
};

/* I only include the relevant stuff from the STREAMINFO block */
struct FLACMetaStreamInfo {
    struct FLACMetaBlockHeader *header;
    uint16_t minBlockSize; /* Minimum block size in stream */
    uint16_t maxBlockSize; /* Maximum block size in stream */
    uint32_t minFrameSize; /* Minimum frame size (bytes) used in stream */
    uint32_t maxFrameSize; /* Maximum frame size (bytes) used in stream */
    uint32_t sampleRate; /* Sample rate in Hz */
    uint8_t numChannels; /* Maximum of 8 channels (-1)*/
    uint8_t bitsPerSample; /* bits per sample 4 to 32 bits (-1) */
    /*Total samples in stream. 'Samples' means inter-channel sample, i.e. one 
     * second of 44.1Khz audio will have 44100 samples regardless of the 
     * number of channels */
    uint64_t totalSamples; 
    uint64_t MD5u; /* Upper bits of the MD5 signature */
    uint64_t MD5l; /* lower bits of the MD5 signature */ 
}; 

struct FLACMetaBlockOther {
    struct FLACMetaBlockHeader *header;
    uint8_t * data;
};

union FLACMetaDataBlock {
    struct FLACMetaStreamInfo streaminfo;
    struct FLACMetaBlockOther other;
};

struct FLACMetaData {
    union FLACMetaDataBlock * metadata;
    int num_blocks;
};

#define READSIZE 1024

void printFLACMetaBlockHeader(struct FLACMetaBlockHeader *meta, FILE* f){
    printf("header\n");
    printf("%d ", meta->last_block);
    printf("%d ", meta->block_type);
    printf("%d ", meta->block_length);
    fprintf(f, "\
last_block: %d\n\
type: %d\n\
length: %d\n", meta->last_block, meta->block_type, meta->block_length);
}

void printFLACMetaBlockOther(struct FLACMetaBlockOther *meta, FILE *f){
    printFLACMetaBlockHeader(&meta->header, f);
}

void printFLACMetaStreamInfo(struct FLACMetaStreamInfo *meta, FILE* f){
    printf("streamingo\n");
    printFLACMetaBlockHeader(&(meta->header), f);
    fprintf(f, "\
    minBlockSize: %d\n\
    maxBlockSize: %d\n\
    minFrameSize: %d\n\
    maxFrameSize: %d\n\
    sampleRate: %d\n\
    numChannels: %d\n\
    bitsPerSample: %d\n\
    totalSamples: %ld\n",
    meta->minBlockSize, meta->maxBlockSize, meta->minFrameSize, meta->maxFrameSize,\
    meta->sampleRate, meta->numChannels, meta->bitsPerSample, meta->totalSamples);
}

void print_FLACMetaData(struct FLACMetaData *meta, FILE *f){
    int i;
    printf("STREAMINFO\n");
    printFLACMetaStreamInfo(&(meta->metadata[0].streaminfo), f);
    for (i = 1; i < meta->num_blocks; i++){
        printf("OTHER\n");
        printFLACMetaBlockOther(&meta->metadata[i].other, f);
    }
}


struct FLACMetaBlockHeader * read_meta_block_header(struct FileReader *fr){
    struct FLACMetaBlockHeader *h = malloc(sizeof(struct FLACMetaBlockHeader));
    h->last_block = read_bits_uint8(fr, 1);
    h->block_type = read_bits_uint8(fr, 7);
    h->block_length = read_bits_uint32(fr, 24);
    return h;
}

union FLACMetaDataBlock * read_meta_other(struct FileReader *fr){
    union FLACMetaDataBlock *b = malloc(sizeof(union FLACMetaDataBlock));
    b.other.header = read_meta_block_header(fr);
    b.other.data = malloc(sizeof(uint8_t) * b.other.header.block_length);
    fread(b.other.data, 1, b.other.header.block_length, fr->fin);
    return b;
}


union FLACMetaDataBlock read_meta_streaminfo(struct FileReader *fr){
    /* Read a streaminfo block */
    union FLACMetaDataBlock b;
    b.streaminfo.header = read_meta_block_header(fr);
    b.streaminfo.minBlockSize = read_bits_uint16(fr, 16);
    b.streaminfo.maxBlockSize = read_bits_uint16(fr, 16);
    b.streaminfo.minFrameSize = read_bits_uint32(fr, 24);
    b.streaminfo.maxFrameSize = read_bits_uint32(fr, 24);
    b.streaminfo.sampleRate = read_bits_uint32(fr, 20);
    b.streaminfo.numChannels = read_bits_uint8(fr, 3);
    b.streaminfo.bitsPerSample = read_bits_uint8(fr, 5);
    b.streaminfo.totalSamples = read_bits_uint64(fr, 36);
    b.streaminfo.MD5u = read_bits_uint64(fr, 64);
    b.streaminfo.MD5l = read_bits_uint64(fr, 64);
    return b;
}

int add_metadata_block(struct FLACMetaData *meta, union FLACMetaDataBlock b){
    /* Insert a meta data block into the metadata structure */
    meta->metadata = realloc(meta->metadata, sizeof(union FLACMetaDataBlock) * (++meta->num_blocks));
    meta->metadata[meta->num_blocks] = b;
}

struct FLACMetaData * read_flac(FILE *fin){
    uint8_t buffer[READSIZE * 2 * 2];
    
    struct FLACMetaData *meta = malloc(sizeof(struct FLACMetaData));
    union FLACMetaDataBlock *temp = malloc(sizeof(union FLACMetaDataBlock));
    
    struct FileReader fr = new_file_reader(fin);
    
    /* Read fLaC section 32 bits */
    fread(buffer, 1, 4, fin);
    if (memcmp(buffer, "fLaC",4)) read_error(fin);
    temp = read_meta_streaminfo(&fr);
    add_metadata_block(&meta, temp);
    if (temp->streaminfo->header->last_block == 0){
        do {
            temp = read_meta_other(&fr);
            add_metadata_block(&meta, temp);
        } while  (temp->other->header->last_block == 0);
    }
    /* Add validation */
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
    
    if((fin = fopen(argv[1], "rb")) == NULL) {
        fprintf(stderr, "ERROR: opening %s for output\n", argv[1]);
        return 1;
    }

    /*struct FileReader fr = new_file_reader(fin);
    uint8_t a;
    uint8_t b;
    uint8_t c;
    a = read_bits_uint8(&fr, 1);
    b = read_bits_uint8(&fr, 3);
    c = read_bits_uint8(&fr, 8);
    printf("%x %x %x",a, b, c);*/
    struct FLACMetaData meta = read_flac(fin);
    print_FLACMetaData(&meta, stderr);
    
    fclose(fin);
    
    return 0;
}