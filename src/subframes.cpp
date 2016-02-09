/* subframe.cpp - Read in FLAC subframes */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <vector>

extern "C" {
#include "bitreader.h"
}

#define READSIZE 1024

class FLACSubFrameHeader {
private:
    /* Zero bit padding, to prevent sync-fooling string of 1s */
    uint8_t zeroBit;
 /* Subframe type:

    000000 : SUBFRAME_CONSTANT
    000001 : SUBFRAME_VERBATIM
    00001x : reserved
    0001xx : reserved
    001xxx : if(xxx <= 4) SUBFRAME_FIXED, xxx=order ; else reserved
    01xxxx : reserved
    1xxxxx : SUBFRAME_LPC, xxxxx=order-1 */
    uint8_t subFrameType;
    
/* 'Wasted bits-per-sample' flag:

    0 : no wasted bits-per-sample in source subblock, k=0
    1 : k wasted bits-per-sample in source subblock, k-1 follows, unary coded;
    e.g. k=3 => 001 follows, k=7 => 0000001 follows. */
    uint32_t wastedBitsPerSample;

public:
    FLACSubFrameHeader();
    void print(FILE *f);
    int read(struct FileReader *fr);
    //int write(FileWriter *fw);
};

FLACSubFrameHeader::FLACSubFrameHeader(){
    this->zeroBit = 1;
    this->subFrameType = 0;
    this->wastedBitsPerSample = 0;
}

void FLACSubFrameHeader::print(FILE *f){
    fprintf(f, "\
Zero Bit: %d\n\
Sub-Frame type: %x\n\
Wasted Bits: %d\n", this->zeroBit, this->subFrameType, this->wastedBitsPerSample);
}

int FLACSubFrameHeader::read(struct FileReader *fr){
    read_bits_uint8(fr, &this->zeroBit, 1);
    read_bits_uint8(fr, &this->subFrameType, 1);
    uint8_t x;
    read_bits_uint8(fr, &x, 1);
    if (x){
        read_bits_unary(fr, &this->wastedBitsPerSample);
    }
}