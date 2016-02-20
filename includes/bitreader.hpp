
#ifndef BITREADER_H
#define BITREADER_H

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define READ_COUNT 512

class FileReader {
private:
    FILE *_fin;
    
    uint64_t _bitp;
    
    int _bytes_read;
    int _bytes_consumed;
    
    int _eof;
    
    uint8_t _bitbuf[1];
    uint8_t _buffer[READ_COUNT];
    
    uint8_t get_mask(uint8_t bits);
    
    template<typename T> int read_bits(T *x, uint8_t bits);
    int smemcpy(void *dst, int dst_off, uint8_t *src, int size, int nmemb);
    /* Use exceptions...*/
    
    int read_rice_partition(int32_t *dst, uint64_t nsamples, int extended);

    template<typename T> int read_bits_unary(T *x);
    
public:
    FileReader(FILE *f);
    int read_error();
    
    uint64_t get_current_bit();
    
    int set_input_file(FILE *f);
    int reset_bit_count();
    int read_bits_uint64(uint64_t *x, uint8_t nbits);
    int read_bits_uint32(uint32_t *x, uint8_t nbits);
    int read_bits_uint16(uint16_t *x, uint8_t nbits);
    int read_bits_uint8(uint8_t *x, uint8_t nbits);
    
    int read_bits_int32(int32_t *x, uint8_t nbits);
    int read_bits_int8(int8_t *x, uint8_t nbits);
    
    int read_bits_unary_uint32(uint32_t *x);
    int read_bits_unary_uint16(uint16_t *x);
    
    int read_rice_signed(int32_t *x, uint8_t M);
    
    int read_utf8_uint64(uint64_t *val);
    int read_utf8_uint32(uint32_t *val);
    
    int read_residual(int32_t *dst, int blk_size, int pred_order);
    
    int read_chunk(void *dst, int size, int nmemb);
    int read_file(void *buf, int size, int nmemb);
    int reset_file();
};

#endif