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
    _subFrameType = 0b000100; //Reserved, so this should never occur
    this->wastedBitsPerSample = 0;
}

void FLACSubFrameHeader::print(FILE *f){
    fprintf(f, "\
Zero Bit: %d\n\
Sub-Frame type: 0x%x\n\
Wasted Bits: %d\n\n", this->zeroBit, _subFrameType, this->wastedBitsPerSample);
}

int FLACSubFrameHeader::read(FileReader *fr){
    fr->read_bits_uint8(&this->zeroBit, 1);
    fr->read_bits_uint8(&_subFrameType, 6);
    uint8_t x;
    fr->read_bits_uint8(&x, 1);
    if (x){
        fr->read_bits_unary_uint16(&this->wastedBitsPerSample);
    }
}

uint8_t FLACSubFrameHeader::getFixedOrder(){
    return _subFrameType & 0x7;
}

uint8_t FLACSubFrameHeader::getLPCOrder(){
    return (_subFrameType & 0x1F) + 1 ; /* Order is order - 1 ... */
}

int FLACSubFrameHeader::getSubFrameType(){
    if (_subFrameType == 0){
        return 0;
    } else if (_subFrameType == 1){
        return 1;
    } else if ((_subFrameType & 0x20) == 0x20){
        return 3; // LPC...
    } else if ((_subFrameType & 0x8) == 8){
        return 2; // FIXED...
    } else {
        return -1;
    }
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
    int s = _predictorOrder;
    s += fr->read_residual(_data, _blockSize, _predictorOrder);
    fprintf(stderr, "Samples Read FIXED: %d\n", s);
    
    return s;
}




/*************************************
 * LPC SUBFRAME **********************
 *************************************/

FLACSubFrameLPC::FLACSubFrameLPC(uint8_t bitsPerSample, uint32_t blockSize, \
                                     uint8_t lpcOrder){
    _blockSize = blockSize;
    _bitsPerSample = bitsPerSample;
    _lpcOrder = lpcOrder;
    
    _qlpPrecis = 0;
    _qlpShift = 0;
    //_qlpCoeff = new vector<int32_t>() ... make appropriate sized array for storing coeffs.
}

int FLACSubFrameLPC::setLPCOrder(uint8_t lpcOrder){
    _lpcOrder = lpcOrder;
}

int FLACSubFrameLPC::read(FileReader *fr){
    uint32_t x = 0;
    int i;
    
    /* Read warm up samples */
    for(i = 0; i < _lpcOrder; i++){
        fr->read_bits_uint32(&x, _bitsPerSample);// Store these samples ... (are they signed???)
    }
    
    /* Read lpc coefficient precision */
    fr->read_bits_uint8(&_qlpPrecis, 4);
    _qlpPrecis++; /* Precision needs to be +1d */
    
    /* Read the coefficient shift */
    fr->read_bits_int8(&_qlpShift, 5); /* Signed two's complement  */
    
    // Read unencoded predictor coefficients...
    int32_t coeff;
    for (i = 0; i < _lpcOrder; i++){
        fr->read_bits_int32(&coeff, _qlpPrecis);
    }
    
    fprintf(stderr, "L O: %d Precis: %d shift: %d\n", _lpcOrder, _qlpPrecis, _qlpShift);
    
    int s = _lpcOrder; // The sum of all samples read by this subframe...
    s += fr->read_residual(_data, _blockSize, _lpcOrder);
    fprintf(stderr, "Samples Read LPC: %d\n", s);
    return s;
}


/*************************************
 * VERBATIM SUBFRAME *****************
 *************************************/

FLACSubFrameVerbatim::FLACSubFrameVerbatim(uint8_t bitsPerSample, uint32_t blockSize){
    _bitsPerSample = bitsPerSample;
    _blockSize = blockSize;
}

int FLACSubFrameVerbatim::read(FileReader *fr){
    _data = (uint32_t*)malloc(sizeof(uint32_t) * _blockSize);
    int i;
    for (i = 0; i < _blockSize; i++){
        fr->read_bits_uint32(_data + i, _bitsPerSample);
    }
    
    return _bitsPerSample*_blockSize;
}


int FLACSubFrameVerbatim::setSampleSize(uint8_t bitsPerSample){
    _bitsPerSample = bitsPerSample;
    return 1;
}
int FLACSubFrameVerbatim::setBlockSize(uint32_t blockSize){
    _blockSize = blockSize;
    return 1;
}


/*************************************
 * CONSTANT SUBFRAME *****************
 *************************************/

FLACSubFrameConstant::FLACSubFrameConstant(uint8_t bitsPerSample, uint32_t blockSize){
    _bitsPerSample = bitsPerSample;
    _blockSize = blockSize;
}

int FLACSubFrameConstant::read(FileReader *fr){
    _data = (uint32_t*)malloc(sizeof(uint32_t) * _blockSize);
    uint32_t constantValue;
    fr->read_bits_uint32(&constantValue, _bitsPerSample);
    return _bitsPerSample*_blockSize;
}


int FLACSubFrameConstant::setSampleSize(uint8_t bitsPerSample){
    _bitsPerSample = bitsPerSample;
    return 1;
}
int FLACSubFrameConstant::setBlockSize(uint32_t blockSize){
    _blockSize = blockSize;
    return 1;
}
