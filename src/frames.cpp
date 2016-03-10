/**************************************/
/* frames.cpp - Read in a FLAC Frame */
/************************************/

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <vector>
#include <memory>

#include "frames.hpp"
#include "bitreader.hpp"

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

void FLACFrameHeader::reconstruct(){    
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

int FLACFrameHeader::getChannelAssign(){
    return _channelAssign;
}

FLAC_const FLACFrameHeader::getChannelType(){
    switch (_channelAssign){
        case 0: case 1: case 2: case 3: case 4: case 5: case 6: case 7: 
            return CH_INDEPENDENT; // Independents...
        case 8: 
            return CH_LEFT; // Left side
        case 9: 
            return CH_RIGHT; //Right side
        case 10:
            return CH_MID; // Mid side
        default:
            return CH_INVALID;
    }
}


int FLACFrameHeader::getNumChannels(){
    switch (_channelAssign){
        case 0: case 1: case 2: case 3: case 4: case 5: case 6: case 7: 
            return _channelAssign + 1;
        case 8: case 9: case 10:
            return 2;
    }
    return -1;
}

int FLACFrameHeader::read(std::shared_ptr<BitReader> fr){
    fr->read_bits(&_syncCode, 14);
    if (_syncCode != FRAME_SYNC){ // 0x3ffe
        fprintf(stderr, "Invalid frame sync 0x%x\n", _syncCode);
        fr->read_error();
    }
    
    fr->read_bits(&_reserved1, 1);
    fr->read_bits(&_blockingStrategy, 1);
    fr->read_bits(&_blockSizeHint, 4);
    fr->read_bits(&_sampleRateHint, 4);
    fr->read_bits(&_channelAssign, 4);
    fr->read_bits(&_sampleSizeHint, 3);
    
    
    /* Interpret sample size */
    _sampleSize = _sampleSizeLUT[_sampleSizeHint];
    
    /* Read one reserved bit, should be zero ... */
    fr->read_bits(&_reserved2, 1);
    
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
            fr->read_bits(&_blockSize, 8);
            _blockSize++;
            break;
        case 0b0111:
            fr->read_bits(&_blockSize, 16);
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
        fr->read_bits(&_sampleRate, 8);
        _sampleRate *= 1000;
    } else if (_sampleRateHint == 13){
        fr->read_bits(&_sampleRate, 16);
    } else if (_sampleRateHint == 14){
        fr->read_bits(&_sampleRate, 16);
        _sampleRate *= 10;
    } else {
        // ERROR !!!
    }
    
    fr->read_bits(&_CRC8Poly, 8);
    return 1; // Add error handling
}

int FLACFrameHeader::read_padding(std::shared_ptr<BitReader> fr){
    uint8_t x;
    /* TODO: Fix this, all I have to do is reset the current bit right? */
    while (fr->get_current_bit() % 8 != 0){
        fr->read_bits(&x, 1);
    }
    return 1;
}

int FLACFrameHeader::read_footer(std::shared_ptr<BitReader> fr){
    return fr->read_bits(&_frameFooter, 16);
}