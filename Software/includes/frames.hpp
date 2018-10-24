/**********************************
 * Simple prog to read a flac file *
 **********************************/

#ifndef FLAC_FRAMES_H
#define FLAC_FRAMES_H

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <vector>
#include <memory>

#include "bitreader.hpp"
#include "bitwriter.hpp"
#include "constants.hpp"

/******** Classes for storing FLAC metadata *******/

class FLACFrameHeader {
public:
    FLACFrameHeader();
    FLACFrameHeader(uint8_t blk_strat, uint32_t samp_rate, uint8_t chan_assign, 
                    uint8_t samp_size, uint64_t number, uint16_t blk_size);
    void reconstruct();
    void reconstruct(uint8_t blk_strat, uint32_t samp_rate, uint8_t chan_assign, 
                    uint8_t samp_size, uint64_t number, uint16_t blk_size);
    int isLast();
    
    int getBlockType();
    int getBlockLength();
    int getSampleSize();
    int getChannelAssign();
    FLAC_const getChannelType();
    int getNumChannels();
    uint64_t getBlockSize();
    
    void setFrameNumber(uint32_t n);
    
    void print(FILE *f);
    int read(BitReader& fr);
    int read_padding(BitReader& fr);
    int read_footer(BitReader& fr);
    
    int write(BitWriter& bw);
    void write_padding(BitWriter& bw);
    int write_footer(BitWriter& bw);
    
private:
/* Sync code */
    uint16_t _syncCode; 
    
/* This bit must remain reserved for 0 in order for a FLAC frame's initial 
 * 15 bits to be distinguishable from the start of an MPEG audio frame (see also). */
    uint8_t _reserved1;
    
/* 0 : fixed-blocksize stream; frame header encodes the frame number
 * 1 : variable-blocksize stream; frame header encodes the sample number */
    uint8_t _blockingStrategy;  
    
/* Block size in inter-channel samples 
 *   0000 : reserved
 *   0001 : 192 samples
 *   0010-0101 : 576 * (2^(n-2)) samples, i.e. 576/1152/2304/4608
 *   0110 : get 8 bit (blocksize-1) from end of header
 *   0111 : get 16 bit (blocksize-1) from end of header
 *   1000-1111 : 256 * (2^(n-8)) samples, i.e. 256/512/1024/2048/4096/8192/16384/32768 */
    uint8_t _blockSizeHint; 
    
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
    static uint32_t _sampleRateLUT[12];
    uint8_t _sampleRateHint;
    
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
    uint8_t _channelAssign;
    
/* Sample size in bits:
 *  000 : get from STREAMINFO metadata block
 *  001 : 8 bits per sample
 *  010 : 12 bits per sample
 *  011 : reserved
 *  100 : 16 bits per sample
 *  101 : 20 bits per sample
 *  110 : 24 bits per sample
 *  111 : reserved */
    static uint8_t _sampleSizeLUT[8];
    uint8_t _sampleSizeHint;
    uint8_t _sampleSize;
    
/* Reserved:
  * 0 : mandatory value
  * 1 : reserved for future use */
    uint8_t _reserved2;

/* if(variable blocksize)
 *  <8-56>:"UTF-8" coded sample number (decoded number is 36 bits) [4]
 * else
 *   <8-48>:"UTF-8" coded frame number (decoded number is 31 bits) [4] */
    uint64_t _sampleNumber;
    uint32_t _frameNumber;
    
/* if(blocksize bits == 011x)
 * 8/16 bit (blocksize-1) */
    uint16_t _blockSize;
    
/* if(sample rate bits == 11xx)
 * 8/16 bit sample rate  */
    uint32_t _sampleRate;
    
/*CRC-8 (polynomial = x^8 + x^2 + x^1 + x^0, initialized with 0) of everything 
 * before the crc, including the sync code  */
    uint8_t _CRC8Poly;
    
/* CRC-16 (polynomial = x^16 + x^15 + x^2 + x^0, initialized with 0) of 
 * everything before the crc, back to and including the frame header sync code */
    uint16_t _frameFooter;
};

#endif
