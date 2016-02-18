/***************************************************/
/******** Classes for storing FLAC metadata *******/
/*************************************************/

#ifndef FLAC_METADATA_H
#define FLAC_METADATA_H

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <vector>

#include "bitreader.hpp"

#define READSIZE 1024

class FLACMetaBlockHeader {
public:
    FLACMetaBlockHeader();
    int isLast();
    int getBlockType();
    int getBlockLength();
    void print(FILE *f);
    int read(FileReader *fr);
    int write(FILE *f);
private:
    uint8_t lastBlock;
    uint8_t blockType;
    uint32_t blockLength;
};

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
    int read(FileReader *fr);
    int write(FILE *f);
    
}; 
/****************************************************/
/************** OTHER METABLOCKS *******************/
/**************************************************/

class FLACMetaBlockOther : public FLACMetaDataBlock {
private:
    uint8_t * data;
public:
    FLACMetaBlockOther();
    void print(FILE *f);
    int read(FileReader *fr);
    int write(FILE *f);
};

/********************************************/
/******* Holds all Metadata ****************/
/******************************************/

class FLACMetaData {
private:
    FLACMetaStreamInfo *streaminfo;
    std::vector<FLACMetaDataBlock *> *metadata;
public:
    FLACMetaData();
    void print(FILE *f);
    int read(FileReader *fr);
    int write(FILE *f);
    int addBlock(FLACMetaDataBlock *b);
    FLACMetaStreamInfo * getStreamInfo();
};

#endif