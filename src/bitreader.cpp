/* Implementation of a bitreader */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "bitreader.hpp"

uint64_t FileReader::get_current_bit(){
    return _bitp;
}

FileReader::FileReader(FILE *f){
    _fin = f;
    _bitp = 0;    
    _curr_byte = _buffer + BUFFER_SIZE;
    _eof = 0;
}

int FileReader::read_error(){
    fprintf(stderr, "Error reading file\n");
    fclose(_fin);
    exit(1);
}

int FileReader::reset_file(){
    rewind(_fin);
    _curr_byte = _buffer + BUFFER_SIZE;
    _bitp = 0;
    _eof = 0;
    return 1;
}

int FileReader::bytes_left(){
    return BUFFER_SIZE - (_curr_byte - _buffer);
}

int FileReader::refill_buffer(){
    _curr_byte = _buffer;
    return fread(_buffer, sizeof(uint8_t), BUFFER_SIZE, _fin);
}

int FileReader::reset_bit_count(){
    _bitp = 0;
    return true;
}

int FileReader::is_byte_aligned(){
    return _bitp % 8 == 0;
}

template<typename T> int FileReader::read_word_LE(T *x){
    assert(this->is_byte_aligned()); // Only execute this when byte aligned...
    T result = 0;
    int bytes = sizeof(T);
    uint8_t byte;
    for (int i = 0; i < bytes; i++){
        read_bits_uint8(&byte, 8);
        result |= (byte << i*8);
    }
    *x = result;
    return true;
}

template<typename T> int FileReader::read_words_LE(T *x, uint64_t words){
    for (int i = 0; i < words; i++){
        read_word_LE<T>(x);
    }
    return true;
}

int FileReader::read_word_u32LE(uint32_t *x){
    return read_word_LE<uint32_t>(x);
}

int FileReader::read_word_u16LE(uint16_t *x){
    return read_word_LE<uint16_t>(x);
}

int FileReader::read_word_i16LE(int16_t *x){
    return read_word_LE<int16_t>(x);
}

int FileReader::read_words_u32LE(uint32_t *dst, uint64_t words){
    return read_words_LE<uint32_t>(dst, words);
}

int FileReader::read_words_u16LE(uint16_t *dst, uint64_t words){
    return read_words_LE<uint16_t>(dst, words);
}

int FileReader::read_words_i16LE(int16_t *dst, uint64_t words){
    return read_words_LE<int16_t>(dst, words);
}

template<typename T> int FileReader::read_bits(T *x, uint8_t nbits){
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

int FileReader::read_bits_uint64(uint64_t *x, uint8_t nbits){
    return read_bits<uint64_t>(x, nbits);
}

int FileReader::read_bits_uint32(uint32_t *x, uint8_t nbits){
    return read_bits<uint32_t>(x, nbits);
}

int FileReader::read_bits_uint16(uint16_t *x, uint8_t nbits){
    return read_bits<uint16_t>(x, nbits);
}

int FileReader::read_bits_uint8(uint8_t *x, uint8_t nbits){
   return read_bits<uint8_t>(x, nbits);
}

int FileReader::read_bits_int32(int32_t *x, uint8_t nbits){
    uint32_t ux, mask;
    read_bits<uint32_t>(&ux, nbits);
    /* sign-extend *x assuming it is currently bits wide. */
    /* From: https://graphics.stanford.edu/~seander/bithacks.html#FixedSignExtend */
    mask = 1u << (nbits - 1);
    *x = (ux ^ mask) - mask;
    return true;
   
}

int FileReader::read_bits_int8(int8_t *x, uint8_t nbits){
    uint8_t ux, mask;
    if (!read_bits<uint8_t>(&ux, nbits)){
        fprintf(stderr, "Error reading INT8\n");
        return false;
    }
    
    mask = 1u << (nbits - 1);
    *x = (ux ^ mask) - mask;
    return true;
}

template<typename T> int FileReader::read_bits_unary(T *x){
    int c = 0;
    uint8_t b = 0;
    
    while(1) {
        if(!read_bits_uint8(&b, 1))
            return false;
        
        if(b)
            break;
        else
            c++;
    }
    
    *x = c;
    return true;
    
}

int FileReader::read_bits_unary_uint32(uint32_t *x){
    return read_bits_unary<uint32_t>(x);
}

int FileReader::read_bits_unary_uint16(uint16_t *x){
    return read_bits_unary<uint16_t>(x);
}

int FileReader::read_rice_signed(int32_t *x, uint8_t M){
    uint32_t msbs = 0, lsbs = 0;
    if (!read_bits_unary_uint32(&msbs) ||
        !read_bits_uint32(&lsbs, M)){
        fprintf(stderr, "Error reading RICE SIGNED\n");
        return false;
    }
    
    unsigned uval = (msbs << M) | lsbs;
    if (uval & 1)
        *x = -((int)(uval >> 1)) - 1;
    else
        *x = (int)(uval >> 1);
    return true;
}

int FileReader::read_rice_partition(int32_t *dst, uint64_t nsamples, int extended){
    uint8_t rice_param = 0;
    uint8_t bps = 0;
    uint8_t param_bits = (extended == 0) ? 4 : 5;
    unsigned i;
    read_bits_uint8(&rice_param, param_bits);
    
    if (rice_param == 0xF || rice_param == 0x1F)
        read_bits_uint8(&bps, 5);
    
    if (rice_param == 0xF || rice_param == 0x1F)
        for (i = 0; i < nsamples; i++) /* Read a chunk */
            read_bits_int32(dst + i, bps);
    else
        for (i = 0; i < nsamples; i++)
            read_rice_signed(dst + i, rice_param);
    
    return i;
}


int FileReader::read_residual(int32_t *dst, int blk_size, int pred_order){
    uint8_t coding_method = 0; 
    uint8_t partition_order = 0;
    uint64_t nsamples = 0;
    read_bits_uint8(&coding_method, 2);
    read_bits_uint8(&partition_order, 4);
    
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
int FileReader::read_utf8_uint32(uint32_t *val){
    uint32_t v = 0;
    uint32_t x;
    unsigned i;

    if (!read_bits_uint32(&x, 8))
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
        if (!read_bits_uint32(&x, 8))
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
int FileReader::read_utf8_uint64(uint64_t *val){
    uint64_t v = 0;
    uint32_t x;
    unsigned i;

    if (!read_bits_uint32(&x, 8))
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
        if (!read_bits_uint32(&x, 8))
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


