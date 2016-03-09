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

#define BUFFER_SIZE 1000000

class BitWriter {
public:
    BitWriter(std::shared_ptr<std::ofstream> f);
  
    void write_error();

    /* Write the rightmost bits in data to file */
    int write_bits(uint64_t data, uint8_t bits);
    int write_unary(uint32_t data);
    int write_rice(int32_t data, unsigned rice_param);
    int flush(){ return write_buffer(); }
    void reset();
    
    template<typename T> int write_chunk(T *data, int nmemb);
    template<typename T> int write_word_LE(T data);
    template<typename T> int write_word_LEs(T *data, int nmemb);
    
private:
    std::shared_ptr<std::ofstream> _fout;
    
    uint8_t _buffer[BUFFER_SIZE];
    uint64_t _bitp;
    uint8_t *_curr_byte;
    
    int bytes_left();
    int write_buffer();
    int is_byte_aligned();
};

#include "bitwriter.tpp"

#endif