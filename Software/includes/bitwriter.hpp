/**************************************/
/* bitwriter.pp - Read and write bits  */
/************************************/

#ifndef BIT_WRITER_H
#define BIT_WRITER_H

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include <iostream>
#include <fstream>
#include <memory>
#include <vector>

#define BUFFER_SIZE 1000000

class BitWriter {
public:
    BitWriter(std::shared_ptr<std::fstream> f);
  
    void write_error();

    /* Write the rightmost bits in data to file */
    int write_bits(uint64_t data, uint8_t bits);
    int write_unary(uint32_t data);
    int write_rice(int32_t data, unsigned rice_param);
    
    int write_residual(int32_t *data, int blk_size, int pred_order,
                       uint8_t coding_method, uint8_t part_order, 
                       std::vector<uint8_t> &part_rice_params);
    int write_rice_partition(int32_t *data, uint64_t nsamples, int extended, uint8_t rice_param);
    
    int write_utf8_uint64(uint64_t *val);
    int write_utf8_uint32(uint32_t *val);
    
    int flush(){ return write_buffer(); }
    
    template<typename T> int write_chunk(T *data, int nmemb);
    template<typename T> int write_word_LE(T data);
    template<typename T> int write_words_LE(T *data, int nmemb);
    
    void reset();
    
private:
    
    std::shared_ptr<std::fstream> _fout;
    
    uint8_t _buffer[BUFFER_SIZE];
    uint64_t _bitp;
    uint8_t *_curr_byte;
    
    int bytes_left();
    int write_buffer();
    int is_byte_aligned();
};

#include "bitwriter.tpp"

#endif