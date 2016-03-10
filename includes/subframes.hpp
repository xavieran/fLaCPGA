/* subframe.cpp - Read in FLAC subframes */

#ifndef FLAC_SUBFRAME_H
#define FLAC_SUBFRAME_H

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <vector>
#include <memory>

#include "bitreader.hpp"
#include "constants.hpp"

class FLACSubFrameHeader {
private:
    /* Zero bit padding, to prevent sync-fooling string of 1s */
    uint8_t _zeroBit;
 /* Subframe type:

    000000 : SUBFRAME_CONSTANT
    000001 : SUBFRAME_VERBATIM
    00001x : reserved
    0001xx : reserved
    001xxx : if(xxx <= 4) SUBFRAME_FIXED, xxx=order ; else reserved
    01xxxx : reserved
    1xxxxx : SUBFRAME_LPC, xxxxx=order-1 */
    uint8_t _subFrameType;
    
/* 'Wasted bits-per-sample' flag:

    0 : no wasted bits-per-sample in source subblock, k=0
    1 : k wasted bits-per-sample in source subblock, k-1 follows, unary coded;
    e.g. k=3 => 001 follows, k=7 => 0000001 follows. */
    uint16_t _wastedBitsPerSample;

public:
    FLACSubFrameHeader();
    void reconstruct();
    
    void print(FILE *f);
    int read(std::shared_ptr<BitReader> fr);
    
    uint8_t getFixedOrder();
    uint8_t getLPCOrder();
    
    FLAC_const getSubFrameType();
    //int write(FileWriter *fw);
};


/*******************************************/
/********** Subframe Superclass ***********/
/*****************************************/

class FLACSubFrame {
public:
    FLACSubFrameHeader * getHeader(){
        return _header;
    }
    
    void setHeader(FLACSubFrameHeader * h){
        _header = h;
    }
    
    virtual int read(std::shared_ptr<BitReader> fr) = 0;
    virtual void print(FILE *f) = 0;
    
private:
    FLACSubFrameHeader *_header;
};


/*************************************
 * FIXED SUBFRAME ********************
 *************************************/

class FLACSubFrameFixed {
private: 
    uint32_t _blockSize;
    uint8_t _bitsPerSample;
    uint8_t _predictorOrder;
public:
    FLACSubFrameFixed();
    
    FLACSubFrameFixed(uint8_t bitsPerSample, uint32_t blockSize, uint8_t predictorOrder);
    void reconstruct(uint8_t bitsPerSample, uint32_t blockSize, uint8_t predictorOrder);
    
    int read(std::shared_ptr<BitReader> fr);
    int read(std::shared_ptr<BitReader> fr, int32_t *dst);
    void print(FILE *f);
};


/*************************************
 * LPC SUBFRAME **********************
 *************************************/

class FLACSubFrameLPC {
private: 
    uint32_t _blockSize;
    uint8_t _bitsPerSample;
    uint8_t _lpcOrder;
    
    uint8_t _qlpPrecis;
    int8_t _qlpShift;
    int32_t _qlpCoeff[12]; /* Maximum of 12 order LPC ... */
public:
    FLACSubFrameLPC();
    FLACSubFrameLPC(uint8_t bitsPerSample, uint32_t blockSize, uint8_t lpcOrder);
    void reconstruct(uint8_t bitsPerSample, uint32_t blockSize, uint8_t lpcOrder);
    
    int read(std::shared_ptr<BitReader> fr);
    int read(std::shared_ptr<BitReader> fr, int32_t *dst);
    
    void setLPCOrder(uint8_t lpcOrder);
    void print(FILE *f);
};


class FLACSubFrameConstant {
private: 
    uint8_t _bitsPerSample;
    uint32_t _blockSize;
public:
    FLACSubFrameConstant();
    FLACSubFrameConstant(uint8_t bitsPerSample, uint32_t blockSize);
    void reconstruct(uint8_t bitsPerSample, uint32_t blockSize);
    
    int read(std::shared_ptr<BitReader> fr);
    int read(std::shared_ptr<BitReader> fr, int32_t *dst);
    
    int setSampleSize(uint8_t bitsPerSample);
    int setBlockSize(uint32_t blockSize);
    void print(FILE *f);
};


class FLACSubFrameVerbatim {
private: 
    uint8_t _bitsPerSample;
    uint32_t _blockSize;
public:
    FLACSubFrameVerbatim();
    FLACSubFrameVerbatim(uint8_t bitsPerSample, uint32_t blockSize);
    void reconstruct(uint8_t bitsPerSample, uint32_t blockSize);
    
    int read(std::shared_ptr<BitReader> fr);
    int read(std::shared_ptr<BitReader> fr, int32_t *dst);
    
    int setSampleSize(uint8_t bitsPerSample);
    int setBlockSize(uint32_t blockSize);
    void print(FILE *f);
};

#endif