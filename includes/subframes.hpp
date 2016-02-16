/* subframe.cpp - Read in FLAC subframes */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <vector>

#include "bitreader.hpp"

class FLACSubFrameHeader {
private:
    /* Zero bit padding, to prevent sync-fooling string of 1s */
    uint8_t zeroBit;
 /* Subframe type:

    000000 : SUBFRAME_CONSTANT
    000001 : SUBFRAME_VERBATIM
    00001x : reserved
    0001xx : reserved
    001xxx : if(xxx <= 4) SUBFRAME_FIXED, xxx=order ; else reserved
    01xxxx : reserved
    1xxxxx : SUBFRAME_LPC, xxxxx=order-1 */
    uint8_t subFrameType;
    
/* 'Wasted bits-per-sample' flag:

    0 : no wasted bits-per-sample in source subblock, k=0
    1 : k wasted bits-per-sample in source subblock, k-1 follows, unary coded;
    e.g. k=3 => 001 follows, k=7 => 0000001 follows. */
    uint16_t wastedBitsPerSample;

public:
    FLACSubFrameHeader();
    void print(FILE *f);
    int read(FileReader *fr);
    uint8_t getFixedOrder();
    //int write(FileWriter *fw);
};


/*******************************************/
/********** Subframe Superclass *****/
/*****************************************/

class FLACSubFrame {
public:
    FLACSubFrameHeader * getHeader(){
        return this->header;
    }
    
    FLACSubFrameHeader * setHeader(FLACSubFrameHeader * h){
        this->header = h;
    }
    
    virtual int read(FileReader *fr) = 0;
    virtual void print(FILE *f) = 0;
    
private:
    FLACSubFrameHeader *header;
};


class FLACSubFrameFixed {
private: 
    uint32_t *_data;
    uint32_t _blockSize;
    uint8_t _bitsPerSample;
    uint32_t _predictorOrder;
public:
    FLACSubFrameFixed(uint8_t bitsPerSample, uint32_t blockSize, uint8_t predictorOrder);
    int read(FileReader *fr);
};

class FLACSubFrameLPC {
private: 
    uint32_t *data;
    uint8_t bitsPerSample;
    uint32_t lpcOrder;
    
    uint8_t qlpPrecis;
    uint8_t qlpShift;
    uint32_t qlpCoeff[];
public:
    FLACSubFrameLPC(uint8_t bitsPerSample, uint32_t lpcOrder);
    int read(FileReader *fr);
};

class FLACSubFrameConstant {
private: 
    uint32_t *data;
    uint8_t bitsPerSample;
    uint32_t blockSize;
public:
    FLACSubFrameConstant(uint8_t bitsPerSample, uint32_t blockSize);
    int read(FileReader *fr);
};


class FLACSubFrameVerbatim {
private: 
    uint32_t *data;
    uint8_t bitsPerSample;
    uint32_t blockSize;
public:
    FLACSubFrameVerbatim(uint8_t bitsPerSample, uint32_t blockSize);
    int read(FileReader *fr);
    int setSampleSize(uint8_t bitsPerSample);
    int setBlockSize(uint32_t blockSize);
};