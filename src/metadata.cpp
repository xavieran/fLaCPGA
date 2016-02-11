/***************************************************/
/******** Classes for storing FLAC metadata *******/
/*************************************************/

#ifndef FLAC_METADATA_C
#define FLAC_METADATA_C

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <vector>

extern "C" {
    #include "bitreader.h"
    #include "bitwriter.h"
}

#define READSIZE 1024

class FLACMetaBlockHeader {
public:
    FLACMetaBlockHeader();
    int isLast();
    int getBlockType();
    int getBlockLength();
    void print(FILE *f);
    int read(struct FileReader *fr);
    int write(FILE *f);
private:
    uint8_t lastBlock;
    uint8_t blockType;
    uint32_t blockLength;
};

FLACMetaBlockHeader::FLACMetaBlockHeader(){
    this->lastBlock = 0;
    this->blockType = 0;
    this->blockLength = 0;
}

int FLACMetaBlockHeader::read(struct FileReader *fr){
    read_bits_uint8(fr, &this->lastBlock, 1);
    read_bits_uint8(fr, &this->blockType, 7);
    read_bits_uint32(fr, &this->blockLength, 24);
    return 1; // Add error handling
}

void FLACMetaBlockHeader::print(FILE *f){
    fprintf(f,\
"Type: %d\n\
Length: %d\n\
Last Block? %d\n\n", this->blockType, this->blockLength, this->lastBlock);
}

int FLACMetaBlockHeader::write(FILE *f){
    return 1;
}

int FLACMetaBlockHeader::isLast(){
    return this->lastBlock;
}

int FLACMetaBlockHeader::getBlockType(){
    return this->blockType;
}

int FLACMetaBlockHeader::getBlockLength(){
    return this->blockLength;
}


/*******************************************/
/********** Metadata Block Superclass *****/
/*****************************************/

class FLACMetaDataBlock {
public:
    FLACMetaBlockHeader * getHeader(){
        return this->header;
    }
    
    FLACMetaBlockHeader * setHeader(FLACMetaBlockHeader * h){
        this->header = h;
    }
    
    virtual int read(FileReader *fr) = 0;
    virtual void print(FILE *f) = 0;
    
private:
    FLACMetaBlockHeader *header;
};



/********************************************/
/************** STREAMINFO *******************/
/********************************************/

class FLACMetaStreamInfo : public FLACMetaDataBlock {
private:
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
    
public:
    FLACMetaStreamInfo();
    uint16_t getMinBlockSize();
    uint16_t getMaxBlockSize();
    uint32_t getMinFrameSize();
    uint32_t getMaxFrameSize();
    uint32_t getSampleRate();
    uint8_t getNumChannels();
    uint8_t getBitsPerSample();
    uint64_t getTotalSamples();
    uint64_t getMD5u();
    uint64_t getMD5l();
    void print(FILE *f);
    int read(struct FileReader *fr);
    int write(FILE *f);
    
}; 

FLACMetaStreamInfo::FLACMetaStreamInfo(){
    uint16_t minBlockSize = 0;
    uint16_t maxBlockSize = 0;
    uint32_t minFrameSize = 0;
    uint32_t maxFrameSize = 0;
    uint32_t sampleRate = 0;
    uint8_t numChannels = 0;
    uint8_t bitsPerSample = 0;
    uint64_t totalSamples = 0;
    uint64_t MD5u = 0;
    uint64_t MD5l = 0;
}

void FLACMetaStreamInfo::print(FILE* f){
    this->getHeader()->print(f);
    fprintf(f, "\
    minBlockSize: %d\n\
    maxBlockSize: %d\n\
    minFrameSize: %d\n\
    maxFrameSize: %d\n\
    sampleRate: %d\n\
    numChannels: %d\n\
    bitsPerSample: %d\n\
    totalSamples: %ld\n\n",
    this->minBlockSize, this->maxBlockSize, this->minFrameSize, this->maxFrameSize,\
    this->sampleRate, this->numChannels, this->bitsPerSample, this->totalSamples);
}


int FLACMetaStreamInfo::read(struct FileReader *fr){
    /* Read a streaminfo block */
    this->setHeader(new FLACMetaBlockHeader());
    this->getHeader()->read(fr);
    read_bits_uint16(fr, &this->minBlockSize, 16);
    read_bits_uint16(fr, &this->maxBlockSize, 16);
    read_bits_uint32(fr, &this->minFrameSize, 24);
    read_bits_uint32(fr, &this->maxFrameSize, 24);
    read_bits_uint32(fr, &this->sampleRate, 20);
    read_bits_uint8(fr, &this->numChannels, 3);
    read_bits_uint8(fr, &this->bitsPerSample, 5);
    read_bits_uint64(fr, &this->totalSamples, 36);
    read_bits_uint64(fr, &this->MD5u, 64);
    read_bits_uint64(fr, &this->MD5l, 64);
    // Add error handling
    return 1;
}

/****************************************************/
/************** OTHER METABLOCKS *******************/
/**************************************************/

class FLACMetaBlockOther : public FLACMetaDataBlock {
private:
    uint8_t * data;
public:
    FLACMetaBlockOther();
    void print(FILE *f);
    int read(struct FileReader *fr);
    int write(FILE *f);
};

FLACMetaBlockOther::FLACMetaBlockOther(){
    ;
}

int FLACMetaBlockOther::read(struct FileReader *fr){
    FLACMetaBlockHeader * h = new FLACMetaBlockHeader();
    this->setHeader(h);
    this->getHeader()->read(fr);
    this->data = (uint8_t *)malloc(sizeof(uint8_t) * h->getBlockLength());
    fread(this->data, 1, h->getBlockLength(), fr->fin);
    // Add error handling
    return 1;
}

void FLACMetaBlockOther::print(FILE *f){
    this->getHeader()->print(f);
}



/********************************************/
/******* Holds all Metadata ****************/
/******************************************/

class FLACMetaData {
private:
    std::vector<FLACMetaDataBlock *> *metadata;
public:
    FLACMetaData();
    void print(FILE *f);
    int read(FILE *f);
    int write(FILE *f);
    int addBlock(FLACMetaDataBlock *b);
};


FLACMetaData::FLACMetaData(){
    this->metadata = new std::vector<FLACMetaDataBlock *>();
}

void FLACMetaData::print(FILE *f){
    std::vector<FLACMetaDataBlock *>::iterator it;
    for(it = this->metadata->begin(); it < this->metadata->end(); it++){
        (*it)->print(f);
    }
}

int FLACMetaData::read(FILE *fin){
    uint8_t buffer[READSIZE * 2 * 2];
    
    struct FileReader fr = new_file_reader(fin);
    
    FLACMetaDataBlock *temp = new FLACMetaStreamInfo();
    

    fread(buffer, 1, 4, fin);
    if (memcmp(buffer, "fLaC",4)) read_error(fin);
    
    temp->read(&fr);
    
    this->addBlock(temp);
    
    if (!temp->getHeader()->isLast()){
        do {
            temp = new FLACMetaBlockOther();
            temp->read(&fr);
            this->addBlock(temp);
        } while  (!temp->getHeader()->isLast());
    }
}

int FLACMetaData::addBlock(FLACMetaDataBlock *b){
    this->metadata->push_back(b);
}

#endif
