/**************************************/
/* frames.cpp - Read in a FLAC Frame */
/************************************/

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <vector>

extern "C" {
#include "bitreader.h"
}

#define READSIZE 1024

/******** Classes for storing FLAC metadata *******/

class FLACFrameHeader {
public:
    FLACFrameHeader();
    int isLast();
    int getBlockType();
    int getBlockLength();
    int getSampleSize();
    uint64_t getBlockSize();
    void print(FILE *f);
    int read(struct FileReader *fr);
    int read_footer(struct FileReader *fr);
    int write(FILE *f);
private:
/* Sync code '11111111111110' */
    uint16_t syncCode; 
    
/* This bit must remain reserved for 0 in order for a FLAC frame's initial 
 * 15 bits to be distinguishable from the start of an MPEG audio frame (see also). */
    uint8_t reserved1;
    
/* 0 : fixed-blocksize stream; frame header encodes the frame number
 * 1 : variable-blocksize stream; frame header encodes the sample number */
    uint8_t blockingStrategy;  
    
/* Block size in inter-channel samples 
 *   0000 : reserved
 *   0001 : 192 samples
 *   0010-0101 : 576 * (2^(n-2)) samples, i.e. 576/1152/2304/4608
 *   0110 : get 8 bit (blocksize-1) from end of header
 *   0111 : get 16 bit (blocksize-1) from end of header
 *   1000-1111 : 256 * (2^(n-8)) samples, i.e. 256/512/1024/2048/4096/8192/16384/32768 */
    uint8_t blockSizeHint; 
    
/* Sample rate:
 *  0000 : get from STREAMINFO metadata block
 *  0001 : 88.2kHz
 *  0010 : 176.4kHz
 *  0011 : 192kHz
 *  0100 : 8kHz
 *  0101 : 16kHz
 *  0110 : 22.05kHz
 *  0111 : 24kHz
 *  1000 : 32kHz
 *  1001 : 44.1kHz
 *  1010 : 48kHz
 *  1011 : 96kHz
 *  1100 : get 8 bit sample rate (in kHz) from end of header
 *  1101 : get 16 bit sample rate (in Hz) from end of header
 *  1110 : get 16 bit sample rate (in tens of Hz) from end of header
 *  1111 : invalid, to prevent sync-fooling string of 1s */
    uint8_t sampleRateHint;
    
/*
 *  0000-0111 : (number of independent channels)-1. Where defined, the channel order 
 *  follows SMPTE/ITU-R recommendations. The assignments are as follows:
 *      1 channel: mono
 *      2 channels: left, right
 *      3 channels: left, right, center
 *      4 channels: front left, front right, back left, back right
 *      5 channels: front left, front right, front center, back/surround left, back/surround right
 *      6 channels: front left, front right, front center, LFE, back/surround left, back/surround right
 *      7 channels: front left, front right, front center, LFE, back center, side left, side right
 *      8 channels: front left, front right, front center, LFE, back left, back right, side left, side right
 *  1000 : left/side stereo: channel 0 is the left channel, channel 1 is the side(difference) channel
 *  1001 : right/side stereo: channel 0 is the side(difference) channel, channel 1 is the right channel
 *  1010 : mid/side stereo: channel 0 is the mid(average) channel, channel 1 is the side(difference) channel
 *  1011-1111 : reserved */
    uint8_t channelAssign;
    
/* Sample size in bits:
 *  000 : get from STREAMINFO metadata block
 *  001 : 8 bits per sample
 *  010 : 12 bits per sample
 *  011 : reserved
 *  100 : 16 bits per sample
 *  101 : 20 bits per sample
 *  110 : 24 bits per sample
 *  111 : reserved */
    uint16_t sampleSize;
    
/* Reserved:
  * 0 : mandatory value
  * 1 : reserved for future use */
    uint8_t reserved2;

/* if(variable blocksize)
 *  <8-56>:"UTF-8" coded sample number (decoded number is 36 bits) [4]
 * else
 *   <8-48>:"UTF-8" coded frame number (decoded number is 31 bits) [4] */
    uint64_t sampleNumber;
    uint32_t frameNumber;
    
/* if(blocksize bits == 011x)
 * 8/16 bit (blocksize-1) */
    uint16_t blockSize;
    
/* if(sample rate bits == 11xx)
 * 8/16 bit sample rate  */
    uint32_t sampleRate;
    
/*CRC-8 (polynomial = x^8 + x^2 + x^1 + x^0, initialized with 0) of everything 
 * before the crc, including the sync code  */
    uint8_t CRC8Poly;
    
/* CRC-16 (polynomial = x^16 + x^15 + x^2 + x^0, initialized with 0) of 
 * everything before the crc, back to and including the frame header sync code */
    uint16_t frameFooter;
};

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
}

int FLACFrameHeader::getSampleSize(){
    return this->sampleSize;
}

uint64_t FLACFrameHeader::getBlockSize(){
    return this->blockSize;
}

int FLACFrameHeader::read(struct FileReader *fr){
    read_bits_uint16(fr, &this->syncCode, 14);
    read_bits_uint8(fr, &this->reserved1, 1);
    read_bits_uint8(fr, &this->blockingStrategy, 1);
    read_bits_uint8(fr, &this->blockSizeHint, 4);
    read_bits_uint8(fr, &this->sampleRateHint, 4);
    read_bits_uint8(fr, &this->channelAssign, 4);
    read_bits_uint16(fr, &this->sampleSize, 3);
    
    
    /* Interpret sample size */
    switch (this->sampleSize){
        case 0b000:
            // GET FROM STREAMINFO...
            break;
        case 0b001:
            this->sampleSize = 8;
            break;
        case 0b010:
            this->sampleSize = 12;
            break;
        case 0b011:
            //reserved...
            break;
        case 0b100:
            this->sampleSize = 16;
            break;
        case 0b101:
            this->sampleSize = 20;
            break;
        case 0b110:
            this->sampleSize = 24;
            break;
        case 0b111:
            //reserved;
            break;
            
    }
    
    /* Read one reserved bit, should be zero ... */
    read_bits_uint8(fr, &this->reserved2, 1);
    
    /* Read sample or frame number.... */
    if (blockingStrategy){
        uint64_t xx = 0;
        read_utf8_uint64(fr, &xx);
        this->sampleNumber = xx;
    } else {
        uint32_t x = 0;
        read_utf8_uint32(fr, &x);
        this->frameNumber = x;
    }
    
    /* Read in the block size ... */
    switch (blockSizeHint){
        case 0b0110:
            read_bits_uint16(fr, &this->blockSize, 8);
            break;
        case 0b0111:
            read_bits_uint16(fr, &this->blockSize, 16);
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
    switch (this->sampleRateHint){
        case 0b0000:
            // get from STREAMINFO 
            break;
        case 0b0001:
            this->sampleRate = 88200;
            break;
        case 0b0010:
            this->sampleRate = 176400;
            break;
        case 0b0011: 
            this->sampleRate = 192000;
            break;
        case 0b0100:
            this->sampleRate = 8000;
            break;
        case 0b0101:
            this->sampleRate = 16000;
            break;
        case 0b0110:
            this->sampleRate = 22050;
            break;
        case 0b0111:
            this->sampleRate = 24000;
            break;
        case 0b1000:
            this->sampleRate = 32000;
            break;
        case 0b1001:
            this->sampleRate = 44100;
            break;
        case 0b1010:
            this->sampleRate = 48000;
            break;
        case 0b1011:
            this->sampleRate = 96000;
            break;
        case 0b1100:
            read_bits_uint32(fr, &this->sampleRate, 8) * 1000;
            break;
        case 0b1101:
            read_bits_uint32(fr, &this->sampleRate, 16);
            break;
        case 0b1110:
            read_bits_uint32(fr, &this->sampleRate, 16) * 10;
            break;
        case 0b1111:
            //ERROR!!!
            break;
    }
    
    read_bits_uint8(fr, &this->CRC8Poly, 4);
    return 1; // Add error handling
}

int FLACFrameHeader::read_footer(struct FileReader *fr){
    read_bits_uint16(fr, &this->frameFooter, 16);
}