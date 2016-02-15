/* Implementation of a bitreader */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "bitreader.hpp"

#define READ_COUNT 16000


uint64_t FileReader::get_current_bit(){
    return _bitp;
}

FileReader::FileReader(FILE *f){
    _fin = f;
    _bitp = 0;    
    _bitbuf[0] = 0;
    _bytes_read = READ_COUNT;
    _bytes_consumed = READ_COUNT;
    _eof = 0;
}

int FileReader::read_error(){
    fprintf(stderr, "Error reading file\n");
    fclose(_fin);
    exit(1);
}

/* Copy from a uint8_t *src into a uintxx_t dest, 
   assuming big endian byte order..
   Note that dst should be zeroed for this to work. */
int FileReader::smemcpy(void *dst, int dst_off, uint8_t *src, int size, int nmemb){
    switch (size){
        case 1:
            memcpy( (uint8_t *)dst + dst_off, src, nmemb * size);
            break;
        case 2:
            memcpy((uint16_t *)dst + dst_off, src, nmemb * size);
            break;
        case 3: case 4:
            memcpy((uint32_t *)dst + dst_off, src, nmemb * size);
            break;
        case 5: case 6: case 7: case 8:
            memcpy((uint64_t *)dst + dst_off, src, nmemb * size);
            break;
    }
    return 1;
}

int FileReader::reset_file(){
    rewind(_fin);
    _bitbuf[0] = 0;
    _bytes_consumed = READ_COUNT;
    _bytes_read = READ_COUNT;
    _bitp = 0;
    _eof = 0;
    return 1;
}

int FileReader::read_file(void *dst, int size, int nmemb){
    fprintf(stderr, "FILEREADER -- Requested read %d of size %d\n", nmemb, size);
    int original_nmemb = nmemb;
    while (nmemb > 0){
        if (_bytes_consumed >= _bytes_read){
            _bytes_read = fread(_buffer, 1, READ_COUNT, _fin);
            /* Check whether we have reached EOF or some file reading error */
            if (_bytes_read != READ_COUNT){
                if (ferror(_fin)){
                    read_error();
                } else if (feof(_fin)){
                    //fprintf(stderr, "FILEREADER -- Reached EOF\n");
                    _eof = 1;
                }
            }
            _bytes_consumed = 0;
        }
        /* We are now guaranteed to have something in the buffer */
        
        int bytes_remaining = _bytes_read - _bytes_consumed;
        int dst_index = original_nmemb - nmemb;
        //fprintf(stderr, "FILEREADER -- Dest offset: %d\n", dst_index);
        
        if (bytes_remaining > nmemb*size){
            smemcpy(dst, dst_index, _buffer + _bytes_consumed, size, nmemb);
            _bytes_consumed += nmemb*size;
            return original_nmemb;
        } else {
            smemcpy(dst, dst_index, _buffer + _bytes_consumed, size, bytes_remaining);
            _bytes_consumed += bytes_remaining;
            nmemb -= (bytes_remaining / size);
        }
        nmemb = 0;
    }
    
    if (_eof){
        return -1;
    }
    
    return original_nmemb;
    //return fread(dst, size, nmemb, _fin);
    
}

uint8_t FileReader::get_mask(uint8_t nbits){
    switch (nbits){
        case 0: return 0xff;
        case 1: return 0x80;
        case 2: return 0xc0;
        case 3: return 0xe0;
        case 4: return 0xf0;
        case 5: return 0xf8;
        case 6: return 0xfc;
        case 7: return 0xfe;
        case 8: return 0xff;
    }
}


int FileReader::reset_bit_count(){
    _bitp = 0;
    _bitbuf[0] = 0;
    return 1;
}


template<typename T> T FileReader::read_bits(T *x, uint8_t nbits){
    /* Convert this to big endian */
    int bits_left_in_byte;
    T t = 0;
    
    while (nbits > 0){
        bits_left_in_byte = 8 - (_bitp % 8);
        if (bits_left_in_byte == 8)
            read_file(_bitbuf, 1, 1);
        
        if (nbits > bits_left_in_byte){
            t <<= bits_left_in_byte;
            t |= ((((T)_bitbuf[0]) & get_mask(bits_left_in_byte)) >> (8-bits_left_in_byte));
            nbits -= bits_left_in_byte;
            _bitp += bits_left_in_byte;
        } else {
            t <<= nbits;
            t |= ((((T)_bitbuf[0]) & get_mask(nbits)) >> (8 - nbits));
            _bitbuf[0] <<= nbits;
            _bitp += nbits;
            nbits = 0;
        }
    }
    
    *x = t;
    return 1;
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

int FileReader::read_bits_unary(uint16_t *x){
    int c = 0;
    uint8_t b = 0;
    while (!b){
        read_bits_uint8(&b, 1);
        c++;
    }
    
    *x = c - 1;
    return 1;
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


