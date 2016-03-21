/* Implementation of a bitreader */

#ifndef BITREADER_T
#define BITREADER_T

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include <iostream>
#include <fstream>
#include <memory>

#include "bitreader.hpp"

template<typename T> int BitReader::read_word_LE(T *x){
    assert(this->is_byte_aligned()); // Only execute this when byte aligned...
    T result = 0;
    unsigned bytes = sizeof(T);
    uint8_t byte;
    for (unsigned i = 0; i < bytes; i++){
        read_bits(&byte, 8);
        result |= (byte << i*8);
    }
    *x = result;
    return true;
}

template<typename T> int BitReader::read_words_LE(T *x, uint64_t words){
    for (unsigned i = 0; i < words; i++){
        read_word_LE(x);
    }
    return true;
}

template<typename T> int  BitReader::read_chunk(T *dst, int nmemb){
    if (this->bytes_left() == 0)
        this->refill_buffer();
    
    while (nmemb > this->bytes_left()){
        memcpy(dst, _curr_byte, this->bytes_left());
        nmemb -= this->bytes_left();
        this->refill_buffer();
    }
    
    memcpy(dst, _curr_byte, nmemb * sizeof(T));
    _curr_byte += nmemb*sizeof(T);
    _bitp += nmemb*sizeof(T)*8;
    
    return nmemb; /* FIXME: DO ERROR CHECKING */
}

template<typename T> int BitReader::read_bits(T *x, uint8_t nbits){
    /* Convert this to big endian */
    int BYTE_MASK[9] = {0xff, 0x80, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc, 0xfe, 0xff};
    int bits_left_in_byte;
    T t = 0;
    
    while (nbits > 0){
        bits_left_in_byte = 8 - (_bitp % 8);
        if (bits_left_in_byte == 8 && this->bytes_left() == 0)
            this->refill_buffer(); //Check for EOF
            
        if (nbits > bits_left_in_byte){
            t <<= bits_left_in_byte;
            t |= ((((T)(*_curr_byte)) & BYTE_MASK[bits_left_in_byte]) >> (8 - bits_left_in_byte));
            nbits -= bits_left_in_byte;
            _bitp += bits_left_in_byte;
            _curr_byte++;
        } else {
            t <<= nbits;
            t |= ((((T)(*_curr_byte)) & BYTE_MASK[nbits]) >> (8 - nbits));
            (*_curr_byte) <<= nbits;
            _bitp += nbits;
            nbits = 0;
            if (_bitp % 8 == 0) _curr_byte++; // Always leave the buffer on the next byte...
        }
    }
    *x = t;
    return true;
}

template<typename T> int BitReader::read_bits_signed(T *x, uint8_t nbits){
    T ux, mask;
    read_bits(&ux, nbits);
    /* sign-extend *x assuming it is currently bits wide. */
    /* From: https://graphics.stanford.edu/~seander/bithacks.html#FixedSignExtend */
    mask = 1u << (nbits - 1);
    *x = (ux ^ mask) - mask;
    return true;
}

template<typename T> int BitReader::read_bits_unary(T *x){
    int c = 0;
    uint8_t b = 0;
    
    while(1) {
        if(!read_bits(&b, 1))
            return false;
        
        if(b)
            break;
        else
            c++;
    }
    
    *x = c;
    return true;
    
}

#endif