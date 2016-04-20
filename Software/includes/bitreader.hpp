
#ifndef BITREADER_H
#define BITREADER_H

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <iostream>
#include <fstream>
#include <memory>

// 1MB default buffer size, should conduct experiments to see effect on performance
#define BUFFER_SIZE 1000000 

class BitReader {
public:
    BitReader(std::shared_ptr<std::fstream> f);
    int read_error();
    
    uint64_t get_current_bit();
    uint64_t get_current_byte();
    
    int seek_bits(uint64_t nbit);
    int seek_bytes(uint64_t nbytes);
    int set_input_file(std::shared_ptr<std::fstream> f);
    int reset_bit_count();
    
    void mark_frame_start();
    uint8_t frame_crc8();

    int read_rice_signed(int32_t *x, uint8_t M);
    
    int read_rice_partition(int32_t *dst, uint64_t nsamples, int extended);
    int read_residual(int32_t *dst, int blk_size, int pred_order);
    int read_utf8_uint64(uint64_t *val);
    int read_utf8_uint32(uint32_t *val);
    
    template<typename T> int read_bits(T *x, uint8_t bits);
    template<typename T> int read_bits_signed(T *x, uint8_t nbits);
    template<typename T> int read_bits_unary(T *x);
    template<typename T> int read_word_LE(T *x);
    template<typename T> int read_words_LE(T *x, uint64_t words);
    template<typename T> int read_chunk(T *dst, int nmemb);
    
    int read_file(void *buf, int size, int nmemb);
    int reset_file();
    int refill_buffer();
    
private:
    std::shared_ptr<std::fstream> _fin;
    
    uint64_t _bitp;
    uint8_t *_curr_byte;
    uint8_t _frame_header[15];
    uint8_t *_frame_start;
    uint8_t _buffer[BUFFER_SIZE];
    int _eof;
    
    int bytes_left();
    int is_byte_aligned();
    
    uint8_t get_mask(uint8_t bits);
    int smemcpy(void *dst, int dst_off, uint8_t *src, int size, int nmemb);
    /* Use exceptions...*/
    

};

#include "bitreader.tpp"

#endif