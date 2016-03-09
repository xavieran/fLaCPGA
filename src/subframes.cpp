/* subframe.cpp - Read in FLAC subframes */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <vector>
#include <memory>

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
Wasted Bits: %d\n", _zeroBit, _subFrameType, _wastedBitsPerSample);
}

int FLACSubFrameHeader::read(std::shared_ptr<FileReader> fr){
    fr->read_bits(&_zeroBit, 1);
    fr->read_bits(&_subFrameType, 6);
    uint8_t x;
    fr->read_bits(&x, 1);
    if (x){
        fr->read_bits_unary(&_wastedBitsPerSample);
    }
    
    return true; /* FIXME: Add error handling.. */
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

void FLACSubFrameFixed::print(FILE *f){
    fprintf(f, " block size: %d\n", _blockSize);
    fprintf(f, " bps: %d\n", _bitsPerSample);
    fprintf(f, " order: %d\n", _predictorOrder);
}

void FLACSubFrameFixed::reconstruct(uint8_t bitsPerSample, uint32_t blockSize, \
                                     uint8_t predictorOrder){
    _blockSize = blockSize;
    _bitsPerSample = bitsPerSample;
    _predictorOrder = predictorOrder;
}

int FLACSubFrameFixed::read(std::shared_ptr<FileReader>fr){
    int i;
    int32_t *data = (int32_t *)malloc(sizeof(int32_t) * _blockSize);
    
    for(i = 0; i < _predictorOrder; i++){
        fr->read_bits_signed(data, _bitsPerSample);// Store these samples ...
    }
    
    int s = _predictorOrder;
    s += fr->read_residual(data, _blockSize, _predictorOrder);
    
    free(data);
    return s;
}

int FLACSubFrameFixed::read(std::shared_ptr<FileReader>fr, int32_t *data){
    unsigned i;
    for(i = 0; i < _predictorOrder; i++){
        fr->read_bits_signed(data + i, _bitsPerSample);
        //printf("\t\twarmup[%d]=%d\n", i, data[i]);
    }
    
    // Be VERY aware that this is written in the data array also...
    //int32_t *residuals = data + _predictorOrder; 
    int32_t *residuals = (int32_t *)malloc(sizeof(int32_t) * _blockSize);
    
    int s = _predictorOrder;
    s += fr->read_residual(residuals, _blockSize, _predictorOrder);
    
    /* Reconstruct the data ... */
    for (i = 0; i < _blockSize; i++){
        //printf("\t\tresidual[%d]=%d\n", i, residuals[i]);
    }
    
    switch(_predictorOrder) {
        case 0:
            memcpy(data, residuals, sizeof(int32_t)*_blockSize);
            break;
        case 1:
            for(i = 1; i < _blockSize; i++)
                data[i] = residuals[i - 1] + data[i-1];
            break;
        case 2:
            for(i = 2; i < _blockSize; i++)
                data[i] = residuals[i - 2] + 2*data[i-1] - data[i-2];
            break;
        case 3:
            for(i = 3; i < _blockSize; i++)
                data[i] = residuals[i - 3] + 3*data[i-1] - 3*data[i-2] + data[i-3];
            break;
        case 4:
            for(i = 4; i < _blockSize; i++)
                data[i] = residuals[i - 4] + 4*data[i-1] - 6*data[i-2] + 4*data[i-3] - data[i-4];
            break;
        default:
            break;
    }
    
    free(residuals);
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

void FLACSubFrameLPC::print(FILE *f){
    fprintf(f, " block size: %d\n", _blockSize);
    fprintf(f, " bps: %d\n", _bitsPerSample);
    fprintf(f, " order: %d\n", _lpcOrder);
    fprintf(f, " precision: %d\n", _qlpPrecis);
    fprintf(f, " shift: %d\n", _qlpShift);
    for (int i = 0; i < _lpcOrder; i++)
        fprintf(f, "   coeff[%d]: %d\n", i, _qlpCoeff[i]);
}

FLACSubFrameLPC::FLACSubFrameLPC(uint8_t bitsPerSample, uint32_t blockSize, \
                                     uint8_t lpcOrder){
    _blockSize = blockSize;
    _bitsPerSample = bitsPerSample;
    _lpcOrder = lpcOrder;
    
    _qlpPrecis = 0;
    _qlpShift = 0;
}

void FLACSubFrameLPC::reconstruct(uint8_t bitsPerSample, uint32_t blockSize, \
                                     uint8_t lpcOrder){
    _blockSize = blockSize;
    _bitsPerSample = bitsPerSample;
    _lpcOrder = lpcOrder;
    
    _qlpPrecis = 0;
    _qlpShift = 0;
}

void FLACSubFrameLPC::setLPCOrder(uint8_t lpcOrder){
    _lpcOrder = lpcOrder;
}

int FLACSubFrameLPC::read(std::shared_ptr<FileReader>fr){
    int i;
    int32_t *data = (int32_t *)malloc(sizeof(int32_t) * _blockSize);
    
    /* Read warm up samples */
    for(i = 0; i < _lpcOrder; i++){
        fr->read_bits_signed(data + i, _bitsPerSample);// Store these samples ... (are they signed???)
    }
    
    /* Read lpc coefficient precision */
    fr->read_bits(&_qlpPrecis, 4);
    _qlpPrecis++; /* Precision needs to be +1d */
    
    /* Read the coefficient shift */
    fr->read_bits_signed(&_qlpShift, 5); /* Signed two's complement  */
    
    /* Read unencoded predictor coefficients... */
    for (i = 0; i < _lpcOrder; i++){
        fr->read_bits_signed(_qlpCoeff + i, _qlpPrecis);
    }
    
    int s = _lpcOrder; // The sum of all samples read by this subframe...
    s += fr->read_residual(data, _blockSize, _lpcOrder);
    
    free(data);
    
    return s;
}

int FLACSubFrameLPC::read(std::shared_ptr<FileReader>fr, int32_t *data){
    unsigned i, j;
    int sum;
    int32_t *residuals = (int32_t *)malloc(sizeof(int32_t) * _blockSize);

    for(i = 0; i < _lpcOrder; i++){
        fr->read_bits_signed(data + i, _bitsPerSample);
    }

    fr->read_bits(&_qlpPrecis, 4);
    _qlpPrecis++; /* Precision needs to be +1d */

    fr->read_bits_signed(&_qlpShift, 5); /* Signed two's complement  */

    int32_t coeff;
    for (i = 0; i < _lpcOrder; i++){
        fr->read_bits_signed(_qlpCoeff + i, _qlpPrecis);
    }
    int s = _lpcOrder; // The sum of all samples read by this subframe...
    s += fr->read_residual(residuals, _blockSize, _lpcOrder);
    
    for(i = _lpcOrder; i < _blockSize; i++) {
        sum = 0;
        for(j = 0; j < _lpcOrder; j++)
            sum += _qlpCoeff[j] * data[i-j-1];
        data[i] = (sum >> _qlpShift) + residuals[i - _lpcOrder];
    }
    
    free(residuals);
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

void FLACSubFrameConstant::print(FILE *f){
    fprintf(f, " block size: %d\n", _blockSize);
    fprintf(f, " bps: %d\n", _bitsPerSample);
}

void FLACSubFrameConstant::reconstruct(uint8_t bitsPerSample, uint32_t blockSize){
    _bitsPerSample = bitsPerSample;
    _blockSize = blockSize;
    //Rezero data or somethign?
}

int FLACSubFrameConstant::read(std::shared_ptr<FileReader>fr){
    int32_t constantValue;
    fr->read_bits_signed(&constantValue, _bitsPerSample);
    return _blockSize;
}

int FLACSubFrameConstant::read(std::shared_ptr<FileReader>fr, int32_t *data){
    unsigned i;
    int32_t constantValue;
    fr->read_bits_signed(&constantValue, _bitsPerSample);
    
    for (i = 0; i < _blockSize; i++){
        data[i] = constantValue;
    }
    
    return _blockSize;
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

void FLACSubFrameVerbatim::print(FILE *f){
    fprintf(f, " block size: %d\n", _blockSize);
    fprintf(f, " bps: %d\n", _bitsPerSample);
}

void FLACSubFrameVerbatim::reconstruct(uint8_t bitsPerSample, uint32_t blockSize){
    _bitsPerSample = bitsPerSample;
    _blockSize = blockSize;
}

int FLACSubFrameVerbatim::read(std::shared_ptr<FileReader>fr){
    unsigned i;
    int32_t data;
    for (i = 0; i < _blockSize; i++){
        fr->read_bits_signed(&data, _bitsPerSample);
    }
    
    return _blockSize;
}

int FLACSubFrameVerbatim::read(std::shared_ptr<FileReader>fr, int32_t *data){
    unsigned i;
    for (i = 0; i < _blockSize; i++){
        fr->read_bits_signed(data + i, _bitsPerSample);
    }
    
    return _blockSize;
}


int FLACSubFrameVerbatim::setSampleSize(uint8_t bitsPerSample){
    _bitsPerSample = bitsPerSample;
    return 1;
}
int FLACSubFrameVerbatim::setBlockSize(uint32_t blockSize){
    _blockSize = blockSize;
    return 1;
}


