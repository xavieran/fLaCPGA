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

uint32_t FLACFrameHeader::sampleRateLUT[12] = {0, 88200, 176400, 192000, 8000, 16000, 22050,\
                                               24000, 32000, 44100, 48000, 96000};
uint8_t FLACFrameHeader::sampleSizeLUT[8] = {0, 8, 12, 0, 16, 20, 24, 0};


void FLACFrameHeader::print(FILE *f){
    fprintf(f, "\
Sync Code: %x\n\
reserved1: %d\n\
Blocking Strategy: %d\n\
Block Size Indicator: %x\n\
Sample Rate Indicator: %x\n\
Block Size: %d\n\
Sample Rate: %d\n\
Channel Assignment: %d\n\
Sample Size: %d\n\
reserved2: %d\n\
Frame Number: %d\n\
CRC Code: %x\n\n", this->syncCode, this->reserved1, this->blockingStrategy, 
        this->blockSizeHint, this->sampleRateHint, this->blockSize, this->sampleRate,
        this->channelAssign, this->sampleSize, this->reserved2, this->frameNumber, 
        this->CRC8Poly);
}

FLACFrameHeader::FLACFrameHeader(){    
    syncCode = 0;
    reserved1 = 0;
    blockingStrategy = 0;
    blockSizeHint = 0;
    sampleRateHint = 0;
    channelAssign = 0;
    sampleSize = 0;
    reserved2 = 0;
    sampleNumber = 0;
    frameNumber  = 0;
    blockSize = 0;
    sampleRate = 0;
    CRC8Poly = 0;
    frameFooter = 0;
}

int FLACFrameHeader::getSampleSize(){
    return this->sampleSize;
}

uint64_t FLACFrameHeader::getBlockSize(){
    return this->blockSize;
}

int FLACFrameHeader::read(FileReader *fr){
    fr->read_bits_uint16(&this->syncCode, 14);
    fr->read_bits_uint8(&this->reserved1, 1);
    fr->read_bits_uint8(&this->blockingStrategy, 1);
    fr->read_bits_uint8(&this->blockSizeHint, 4);
    fr->read_bits_uint8(&this->sampleRateHint, 4);
    fr->read_bits_uint8(&this->channelAssign, 4);
    fr->read_bits_uint8(&this->sampleSizeHint, 3);
    
    
    /* Interpret sample size */
    sampleSize = sampleSizeLUT[sampleSizeHint];
    //Check for errors after here...
    
    /* Read one reserved bit, should be zero ... */
    fr->read_bits_uint8(&this->reserved2, 1);
    
    /* Read sample or frame number.... */
    if (blockingStrategy){
        uint64_t xx = 0;
        fr->read_utf8_uint64(&xx);
        this->sampleNumber = xx;
    } else {
        uint32_t x = 0;
        fr->read_utf8_uint32(&x);
        this->frameNumber = x;
    }
    
    /* Read in the block size ... */
    switch (blockSizeHint){
        case 0b0110:
            fr->read_bits_uint16(&this->blockSize, 8);
            break;
        case 0b0111:
            fr->read_bits_uint16(&this->blockSize, 16);
            break;
        case 0b0001:
            this->blockSize = 192;
            break;
    }
    
    if (this->blockSizeHint >= 0b0010 && this->blockSizeHint <= 0b0101){
        this->blockSize = 576 * (2 << ((this->blockSizeHint - 2) - 1));
    } else if (this->blockSizeHint >= 0b1000 && this->blockSizeHint <= 0b1111){
        this->blockSize = 256 * (2 << ((this->blockSizeHint - 8) - 1));
    }
    
    
    /* Read in the sample rate */
    if (sampleRateHint == 0){
        // Get from STREAMINFO
    } else if (this->sampleRateHint < 12){
        sampleRate = sampleRateLUT[sampleRateHint];
    } else if (sampleRateHint == 12){
        fr->read_bits_uint32(&sampleRate, 8) * 1000;
    } else if (sampleRateHint == 13){
        fr->read_bits_uint32(&sampleRate, 16);
    } else if (sampleRateHint == 14){
        fr->read_bits_uint32(&sampleRate, 16) * 10;
    } else {
        // ERROR !!!
    }
    
    fr->read_bits_uint8(&this->CRC8Poly, 4);
    return 1; // Add error handling
}

int FLACFrameHeader::read_footer(FileReader *fr){
    fr->read_bits_uint16(&this->frameFooter, 16);
}