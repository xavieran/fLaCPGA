/**************************************/
/* frames.cpp - Read in a FLAC Frame */
/************************************/

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <vector>

#include "frames.hpp"

#include "bitreader.hpp"

/******** Classes for storing FLAC metadata *******/

uint32_t FLACFrameHeader::_sampleRateLUT[12] = {0, 88200, 176400, 192000, 8000, 16000, 22050,\
                                               24000, 32000, 44100, 48000, 96000};
uint8_t FLACFrameHeader::_sampleSizeLUT[8] = {0, 8, 12, 0, 16, 20, 24, 0};


void FLACFrameHeader::print(FILE *f){
    fprintf(f, "\
Sync Code: 0x%x\n\
reserved1: %d\n\
Blocking Strategy: %d\n\
Block Size Hint: 0x%x\n\
Sample Rate Hint: 0x%x\n\
Block Size: %d\n\
Sample Rate: %d\n\
Channel Assignment: %d\n\
Sample Size: %d\n\
reserved2: %d\n\
Frame Number: %d\n\
CRC Code: 0x%x\n\n", _syncCode, _reserved1, _blockingStrategy, 
        _blockSizeHint, _sampleRateHint, _blockSize, _sampleRate,
        _channelAssign, _sampleSize, _reserved2, _frameNumber, 
        _CRC8Poly);
}

FLACFrameHeader::FLACFrameHeader(){    
    _syncCode = 0;
    _reserved1 = 0;
    _blockingStrategy = 0;
    _blockSizeHint = 0;
    _sampleRateHint = 0;
    _channelAssign = 0;
    _sampleSize = 0;
    _reserved2 = 0;
    _sampleNumber = 0;
    _frameNumber  = 0;
    _blockSize = 0;
    _sampleRate = 0;
    _CRC8Poly = 0;
    _frameFooter = 0;
}

int FLACFrameHeader::getSampleSize(){
    return _sampleSize;
}

uint64_t FLACFrameHeader::getBlockSize(){
    return _blockSize;
}

int FLACFrameHeader::read(FileReader *fr){
    fr->read_bits_uint16(&_syncCode, 14);
    fr->read_bits_uint8(&_reserved1, 1);
    fr->read_bits_uint8(&_blockingStrategy, 1);
    fr->read_bits_uint8(&_blockSizeHint, 4);
    fr->read_bits_uint8(&_sampleRateHint, 4);
    fr->read_bits_uint8(&_channelAssign, 4);
    fr->read_bits_uint8(&_sampleSizeHint, 3);
    
    
    /* Interpret sample size */
    _sampleSize = _sampleSizeLUT[_sampleSizeHint];
    //Check for errors after here...
    
    /* Read one reserved bit, should be zero ... */
    fr->read_bits_uint8(&_reserved2, 1);
    
    /* Read sample or frame number.... */
    if (_blockingStrategy){
        uint64_t xx = 0;
        fr->read_utf8_uint64(&xx);
        _sampleNumber = xx;
    } else {
        uint32_t x = 0;
        fr->read_utf8_uint32(&x);
        _frameNumber = x;
    }
    
    /* Read in the block size ... */
    switch (_blockSizeHint){
        case 0b0110:
            fr->read_bits_uint16(&_blockSize, 8);
            _blockSize++;
            break;
        case 0b0111:
            fr->read_bits_uint16(&_blockSize, 16);
            _blockSize++;
            break;
        case 0b0001:
            _blockSize = 192;
            break;
    }
    
    if (_blockSizeHint >= 0b0010 && _blockSizeHint <= 0b0101){
        _blockSize = 576 * (1 << (_blockSizeHint - 2));
    } else if (_blockSizeHint >= 0b1000 && _blockSizeHint <= 0b1111){
        _blockSize = 256 * (1 << (_blockSizeHint - 8));
    }
    
    
    /* Read in the sample rate */
    if (_sampleRateHint == 0){
        // Get from STREAMINFO
    } else if (_sampleRateHint < 12){
        _sampleRate = _sampleRateLUT[_sampleRateHint];
    } else if (_sampleRateHint == 12){
        fr->read_bits_uint32(&_sampleRate, 8) * 1000;
    } else if (_sampleRateHint == 13){
        fr->read_bits_uint32(&_sampleRate, 16);
    } else if (_sampleRateHint == 14){
        fr->read_bits_uint32(&_sampleRate, 16) * 10;
    } else {
        // ERROR !!!
    }
    
    fr->read_bits_uint8(&_CRC8Poly, 8);
    return 1; // Add error handling
}

int FLACFrameHeader::read_padding(FileReader *fr){
    uint8_t x;
    while (fr->get_current_bit() % 8 != 0){
        fr->read_bits_uint8(&x, 1);
        //fprintf(stderr, "Padding... cb: %ld b: %d\nread_", fr->get_current_bit(), x);
    }
    return 1;
}

int FLACFrameHeader::read_footer(FileReader *fr){
    fr->read_bits_uint16(&_frameFooter, 16);
}