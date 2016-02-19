/* subframe.cpp - Read in FLAC subframes */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <vector>

#include "subframes.hpp"

#include "bitreader.hpp"
#include "constants.hpp"


/***********************************
 * SUB FRAME HEADER ****************
 * *********************************/

FLACSubFrameHeader::FLACSubFrameHeader(){
    _zeroBit = 1;
    _subFrameType = 0b000100; //Reserved, so this should never occur
    _wastedBitsPerSample = 0;
}

void FLACSubFrameHeader::reconstruct(){
    _zeroBit = 1;
    _subFrameType = 0b000100;
    _wastedBitsPerSample = 0;
}

void FLACSubFrameHeader::print(FILE *f){
    fprintf(f, "\
Zero Bit: %d\n\
Sub-Frame type: 0x%x\n\
Wasted Bits: %d\n\n", _zeroBit, _subFrameType, _wastedBitsPerSample);
}

int FLACSubFrameHeader::read(FileReader *fr){
    fr->read_bits_uint8(&_zeroBit, 1);
    fr->read_bits_uint8(&_subFrameType, 6);
    uint8_t x;
    fr->read_bits_uint8(&x, 1);
    if (x){
        fr->read_bits_unary_uint16(&_wastedBitsPerSample);
    }
}

uint8_t FLACSubFrameHeader::getFixedOrder(){
    return _subFrameType & 0x7;
}

uint8_t FLACSubFrameHeader::getLPCOrder(){
    return (_subFrameType & 0x1F) + 1 ; /* Order is order - 1 ... */
}

FLAC_const FLACSubFrameHeader::getSubFrameType(){
    if (_subFrameType == 0){
        return SUB_CONSTANT;
    } else if (_subFrameType == 1){
        return SUB_VERBATIM;
    } else if ((_subFrameType & 0x20) == 0x20){
        return SUB_LPC;
    } else if ((_subFrameType & 0x8) == 8){
        return SUB_FIXED;
    } else {
        return SUB_INVALID;
    }
}

/*************************************
 * FIXED SUBFRAME ********************
 *************************************/

FLACSubFrameFixed::FLACSubFrameFixed(){
    _blockSize = 0;
    _bitsPerSample = 0;
    _predictorOrder = 0;
}

FLACSubFrameFixed::FLACSubFrameFixed(uint8_t bitsPerSample, uint32_t blockSize, \
                                     uint8_t predictorOrder){
    _blockSize = blockSize;
    _bitsPerSample = bitsPerSample;
    _predictorOrder = predictorOrder;
}

void FLACSubFrameFixed::reconstruct(uint8_t bitsPerSample, uint32_t blockSize, \
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
    return s;
}


/*************************************
 * LPC SUBFRAME **********************
 *************************************/

FLACSubFrameLPC::FLACSubFrameLPC(){
    _blockSize = 0;
    _bitsPerSample = 0;
    _lpcOrder = 0;
    
    _qlpPrecis = 0;
    _qlpShift = 0;
    //_qlpCoeff = new vector<int32_t>() ... make appropriate sized array for storing coeffs.
}

FLACSubFrameLPC::FLACSubFrameLPC(uint8_t bitsPerSample, uint32_t blockSize, \
                                     uint8_t lpcOrder){
    _blockSize = blockSize;
    _bitsPerSample = bitsPerSample;
    _lpcOrder = lpcOrder;
    
    _qlpPrecis = 0;
    _qlpShift = 0;
    //_qlpCoeff = new vector<int32_t>() ... make appropriate sized array for storing coeffs.
}

void FLACSubFrameLPC::reconstruct(uint8_t bitsPerSample, uint32_t blockSize, \
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
    
    int s = _lpcOrder; // The sum of all samples read by this subframe...
    s += fr->read_residual(_data, _blockSize, _lpcOrder);
    return s;
}


/*************************************
 * CONSTANT SUBFRAME *****************
 *************************************/

FLACSubFrameConstant::FLACSubFrameConstant(){
    _bitsPerSample = 0;
    _blockSize = 0;
}

FLACSubFrameConstant::FLACSubFrameConstant(uint8_t bitsPerSample, uint32_t blockSize){
    _bitsPerSample = bitsPerSample;
    _blockSize = blockSize;
    //Allocate space for data or something?
}

void FLACSubFrameConstant::reconstruct(uint8_t bitsPerSample, uint32_t blockSize){
    _bitsPerSample = bitsPerSample;
    _blockSize = blockSize;
    //Rezero data or somethign?
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


/*************************************
 * VERBATIM SUBFRAME *****************
 *************************************/

FLACSubFrameVerbatim::FLACSubFrameVerbatim(){
    _bitsPerSample = 0;
    _blockSize = 0;
}

FLACSubFrameVerbatim::FLACSubFrameVerbatim(uint8_t bitsPerSample, uint32_t blockSize){
    _bitsPerSample = bitsPerSample;
    _blockSize = blockSize;
}

void FLACSubFrameVerbatim::reconstruct(uint8_t bitsPerSample, uint32_t blockSize){
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


