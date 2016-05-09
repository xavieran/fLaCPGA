/* Implementation of a bitreader */

#include "bitreader.hpp"
#include "crc.hpp"

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <assert.h>

#include <iostream>
#include <fstream>
#include <memory>

BitReader::BitReader(std::shared_ptr<std::fstream> f){
    _fin = f;
    _bitp = 0;
    _curr_byte = _buffer + BUFFER_SIZE;
    _eof = 0;
}

int BitReader::read_error(){
    fprintf(stderr, "Error reading file\n");
    _fin->close();
    exit(1);
}

int BitReader::reset_file(){
    _fin->seekg(0);
    _curr_byte = _buffer + BUFFER_SIZE;
    _bitp = 0;
    _eof = 0;
    return 1;
}

uint64_t BitReader::get_current_bit(){
    return _bitp;
}

uint64_t BitReader::get_current_byte(){
    return _curr_byte - _buffer;
}


int BitReader::bytes_left(){
    return BUFFER_SIZE - (_curr_byte - _buffer);
}

int BitReader::refill_buffer(){
    _curr_byte = _buffer;
    _fin->read((char *)_buffer, BUFFER_SIZE); // This cast irritates me...
    
    /*printf("BUFFER CONTENTS\n");
    for (int i = 0; i < 30; i++){
        printf("%x ", _buffer[i]);
    }
    printf("\n");*/
    return 1;
}

void BitReader::mark_frame_start(){
    /* FIXME: This doesn't take into account a frame that 
     * breaks over the edge of the buffer */
    _frame_start = _curr_byte;
    memcpy(_frame_header,_frame_start, 15);
}
    
    
uint8_t BitReader::frame_crc8(){
    return FLAC_CRC::crc8(_frame_header, (int) (_curr_byte - _frame_start));
}

int BitReader::seek_bits(uint64_t nbits){
    /* FIXME: Logic to check if we overrun the buffer ... */
    if (nbits && (bytes_left() == 0))
        refill_buffer();
    
    int bitpr = _bitp % 8;
    _bitp += nbits;
    _curr_byte += ((bitpr + nbits) / 8 - get_current_byte());
    (*_curr_byte) <<= (_bitp % 8);
    return 1;
}

int BitReader::seek_bytes(uint64_t nbytes){
    /* FIXME: Logic to check if we overrun the buffer ... */
    _curr_byte += nbytes;
    return 1;
}

int BitReader::reset_bit_count(){
    _bitp = 0;
    return true;
}

int BitReader::is_byte_aligned(){
    return _bitp % 8 == 0;
}

int BitReader::read_rice_signed(int32_t *x, uint8_t M){
    uint32_t msbs = 0, lsbs = 0;
    if (!read_bits_unary(&msbs) ||
        !read_bits(&lsbs, M)){
        fprintf(stderr, "Error reading RICE SIGNED\n");
        return false;
    }
    
    unsigned uval = (msbs << M) | lsbs;
    if (uval & 1)
        *x = -((int)(uval >> 1)) - 1;
    else
        *x = (int)(uval >> 1);    

    //std::cout << "MSBS: " << msbs <<" LSBS: " << lsbs << " == " << (int) *x << "\n";
    return true;
}

int BitReader::read_rice_partition(int32_t *dst, uint64_t nsamples, int extended){
    uint8_t rice_param = 0;
    uint8_t bps = 0;
    uint8_t param_bits = (extended == 0) ? 4 : 5;
    unsigned i;
    read_bits(&rice_param, param_bits);
    
    //std::cout << "Rice Param: " << (int) rice_param << "\n";
    
    if (rice_param == 0xF || rice_param == 0x1F)
        read_bits(&bps, 5);
    
    if (rice_param == 0xF || rice_param == 0x1F)
        for (i = 0; i < nsamples; i++) /* Read a chunk */
            read_bits_signed(dst + i, bps);
    else
        for (i = 0; i < nsamples; i++){
            read_rice_signed(dst + i, rice_param);
            //std::cout << *(dst + i) <<" ";
        } //std::cout <<"\n";
    
    return i;
}

int BitReader::read_residual(int32_t *dst, int blk_size, int pred_order){
    uint8_t coding_method = 0; 
    uint8_t partition_order = 0;
    uint64_t nsamples = 0;
    read_bits(&coding_method, 2);
    read_bits(&partition_order, 4);
    //std::cout << "blk_size: " << blk_size << " Code: " << (int)coding_method <<" order: "<<(int)partition_order<<"\n";
    int s = 0;
    int i;
    for (i = 0; i < (1 << partition_order); i++){
                /* Calculate the number of samples */
        if (partition_order == 0)
            nsamples = blk_size - pred_order;
        else if (i != 0)
            nsamples = blk_size / (1 << partition_order);
        else 
            nsamples = blk_size / (1 << partition_order) - pred_order;
        s += read_rice_partition(dst, nsamples, coding_method);
        dst += nsamples; /* Move pointer forward... */
    }
    return s;
}

/* This code borrowed from libFLAC */
/* on return, if *val == 0xffffffff then the utf-8 sequence was invalid, but the return value will be true */
int BitReader::read_utf8_uint32(uint32_t *val){
    uint32_t v = 0;
    uint32_t x;
    unsigned i;

    if (!read_bits(&x, 8))
        return 0;
    if(!(x & 0x80)) { /* 0xxxxxxx */
        v = x;
        i = 0;
    }
    else if(x & 0xC0 && !(x & 0x20)) { /* 110xxxxx */
        v = x & 0x1F;
        i = 1;
    }
    else if(x & 0xE0 && !(x & 0x10)) { /* 1110xxxx */
        v = x & 0x0F;
        i = 2;
    }
    else if(x & 0xF0 && !(x & 0x08)) { /* 11110xxx */
        v = x & 0x07;
        i = 3;
    }
    else if(x & 0xF8 && !(x & 0x04)) { /* 111110xx */
        v = x & 0x03;
        i = 4;
    }
    else if(x & 0xFC && !(x & 0x02)) { /* 1111110x */
        v = x & 0x01;
        i = 5;
    }
    else {
        *val = 0xffffffff;
        return 1;
    }
    for( ; i; i--) {
        if (!read_bits(&x, 8))
            return 0;
        if (!(x & 0x80) || (x & 0x40)) { /* 10xxxxxx */
            *val = 0xffffffff;
            return 1;
        }
        v <<= 6;
        v |= (x & 0x3F);
    }
    *val = v;
    return 1;
}

/* on return, if *val == 0xffffffffffffffff then the utf-8 sequence was invalid, but the return value will be true */
int BitReader::read_utf8_uint64(uint64_t *val){
    uint64_t v = 0;
    uint32_t x;
    unsigned i;

    if (!read_bits(&x, 8))
        return 0;
    if(!(x & 0x80)) { /* 0xxxxxxx */
        v = x;
        i = 0;
    }
    else if(x & 0xC0 && !(x & 0x20)) { /* 110xxxxx */
        v = x & 0x1F;
        i = 1;
    }
    else if(x & 0xE0 && !(x & 0x10)) { /* 1110xxxx */
        v = x & 0x0F;
        i = 2;
    }
    else if(x & 0xF0 && !(x & 0x08)) { /* 11110xxx */
        v = x & 0x07;
        i = 3;
    }
    else if(x & 0xF8 && !(x & 0x04)) { /* 111110xx */
        v = x & 0x03;
        i = 4;
    }
    else if(x & 0xFC && !(x & 0x02)) { /* 1111110x */
        v = x & 0x01;
        i = 5;
    }
    else if(x & 0xFE && !(x & 0x01)) { /* 11111110 */
        v = 0;
        i = 6;
    }
    else {
        *val = (uint64_t) 0xffffffffffffffff;
        return 1;
    }
    for( ; i; i--) {
        if (!read_bits(&x, 8))
            return 0;
        if(!(x & 0x80) || (x & 0x40)) { /* 10xxxxxx */
            *val = (uint64_t)0xffffffffffffffff;
            return 1;
        }
        v <<= 6;
        v |= (x & 0x3F);
    }
    *val = v;
    return 1;
}


