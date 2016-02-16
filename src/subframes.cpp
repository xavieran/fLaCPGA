/* subframe.cpp - Read in FLAC subframes */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <vector>

#include "subframes.hpp"

#include "bitreader.hpp"


/***********************************
 * SUB FRAME HEADER ****************
 * *********************************/

FLACSubFrameHeader::FLACSubFrameHeader(){
    this->zeroBit = 1;
    this->subFrameType = 0b000100; //Reserved, so this should never occur
    this->wastedBitsPerSample = 0;
}

void FLACSubFrameHeader::print(FILE *f){
    fprintf(f, "\
Zero Bit: %d\n\
Sub-Frame type: 0x%x\n\
Wasted Bits: %d\n\n", this->zeroBit, this->subFrameType, this->wastedBitsPerSample);
}

int FLACSubFrameHeader::read(FileReader *fr){
    fr->read_bits_uint8(&this->zeroBit, 1);
    fr->read_bits_uint8(&this->subFrameType, 6);
    uint8_t x;
    fr->read_bits_uint8(&x, 1);
    if (x){
        fr->read_bits_unary(&this->wastedBitsPerSample);
    }
}

uint8_t FLACSubFrameHeader::getFixedOrder(){
    return this->subFrameType & 0x7;
}
/*************************************
 * FIXED SUBFRAME ********************
 *************************************/

FLACSubFrameFixed::FLACSubFrameFixed(uint8_t bitsPerSample, uint32_t blockSize, \
                                     uint8_t predictorOrder){
    _blockSize = blockSize;
    _bitsPerSample = bitsPerSample;
    _predictorOrder = predictorOrder;
}

int FLACSubFrameFixed::read(FileReader *fr){
    uint32_t x = 0;
    int i;
    for(i = 0; i < _predictorOrder; i++){
        fr->read_bits_uint32(&x, _bitsPerSample);// Store these samples ...
    }
    int s = fr->read_residual(_data, _blockSize, _predictorOrder);
    fprintf(stderr, "Samples Read FIXED: %d\n", s);
    
    return 1;
}




/*************************************
 * VERBATIM SUBFRAME *****************
 *************************************/

FLACSubFrameVerbatim::FLACSubFrameVerbatim(uint8_t bitsPerSample, uint32_t blockSize){
    this->bitsPerSample = bitsPerSample;
    this->blockSize = blockSize;
}

int FLACSubFrameVerbatim::read(FileReader *fr){
    data = (uint32_t*)malloc(sizeof(uint32_t) * this->blockSize);
    int i;
    for (i = 0; i < this->blockSize; i++){
        fr->read_bits_uint32(data + i, this->bitsPerSample);
    }
    return 1;
}


int FLACSubFrameVerbatim::setSampleSize(uint8_t bitsPerSample){
    this->bitsPerSample = bitsPerSample;
    return 1;
}
int FLACSubFrameVerbatim::setBlockSize(uint32_t blockSize){
    this->blockSize = blockSize;
    return 1;
}
