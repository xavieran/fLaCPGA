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
#include <memory>

#include "bitreader.hpp"
#include "bitwriter.hpp"

#define READSIZE 1024

class FLACMetaBlockHeader {
public:
    FLACMetaBlockHeader();
    FLACMetaBlockHeader(int isLast, int blockType, int blockLength);
    int isLast();
    int getBlockType();
    int getBlockLength();
    void print(FILE *f);
    int read(std::shared_ptr<BitReader> fr);
    int write(FILE *f);
private:
    uint8_t _lastBlock;
    uint8_t _blockType;
    uint32_t _blockLength;
};

/*******************************************/
/********** Metadata Block Superclass *****/
/*****************************************/

class FLACMetaDataBlock {
public:
    FLACMetaBlockHeader * getHeader(){
        return _header;
    }
    
    void setHeader(FLACMetaBlockHeader * h){
        _header = h;
    }
    
    virtual int read(std::shared_ptr<BitReader> fr) = 0;
    virtual void print(FILE *f) = 0;
    
private:
    FLACMetaBlockHeader *_header;
};


/********************************************/
/************** STREAMINFO *******************/
/********************************************/

class FLACMetaStreamInfo : public FLACMetaDataBlock {
private:
    uint16_t _minBlockSize; /* Minimum block size in stream */
    uint16_t _maxBlockSize; /* Maximum block size in stream */
    uint32_t _minFrameSize; /* Minimum frame size (bytes) used in stream */
    uint32_t _maxFrameSize; /* Maximum frame size (bytes) used in stream */
    uint32_t _sampleRate; /* Sample rate in Hz */
    uint8_t _numChannels; /* Maximum of 8 channels (-1)*/
    uint8_t _bitsPerSample; /* bits per sample 4 to 32 bits (-1) */
    /*Total samples in stream. 'Samples' means inter-channel sample, i.e. one 
     * second of 44.1Khz audio will have 44100 samples regardless of the 
     * number of channels */
    uint64_t _totalSamples; 
    uint64_t _MD5u; /* Upper bits of the MD5 signature */
    uint64_t _MD5l; /* lower bits of the MD5 signature */ 
    
public:
    FLACMetaStreamInfo();
    FLACMetaStreamInfo(uint16_t min_blk_sz, uint16_t max_blk_sz,
                       uint32_t min_frm_sz, uint32_t max_frm_sz, 
                       uint32_t samp_rate, uint8_t num_chan, uint8_t bps, 
                       uint64_t total_samp, uint64_t MD5u, uint64_t MD5l);
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
    
    void setTotalSamples(uint64_t samples);
    void print(FILE *f);
    int read(std::shared_ptr<BitReader> fr);
    bool write(std::shared_ptr<BitWriter> bw);
    
}; 
/****************************************************/
/************** OTHER METABLOCKS *******************/
/**************************************************/

class FLACMetaBlockOther : public FLACMetaDataBlock {
private:
    uint8_t * _data;
public:
    FLACMetaBlockOther();
    void print(FILE *f);
    int read(std::shared_ptr<BitReader> fr);
    int write(FILE *f);
};

/********************************************/
/******* Holds all Metadata ****************/
/******************************************/

class FLACMetaData {
private:
    FLACMetaStreamInfo *_streaminfo;
    std::vector<FLACMetaDataBlock *> *_metadata;
public:
    FLACMetaData();
    void print(FILE *f);
    int read(std::shared_ptr<BitReader> fr);
    int write(FILE *f);
    int addBlock(FLACMetaDataBlock *b);
    FLACMetaStreamInfo * getStreamInfo();
};

#endif