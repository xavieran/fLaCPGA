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

#define BUFFER_SIZE 100000

class BitWriter {
public:
    BitWriter(FILE *f);
  
    void write_error();

    int write_word_u16LE(uint16_t data);
    int write_word_u32LE(uint32_t data);
    int write_word_i16LE(int16_t data);
    
    int flush(){ return write_buffer(); }
    void reset();
    
    template<typename T> int write_chunk(T *data, int nmemb){
        if (this->bytes_left() == 0){
            write_buffer();
        }
        
        while (nmemb > this->bytes_left()){
            memcpy(_curr_byte, data, this->bytes_left());
            nmemb -= this->bytes_left();
            write_buffer();
        }
        
        memcpy(_curr_byte, data, nmemb*sizeof(T));
        _curr_byte += nmemb*sizeof(T);
        _bitp += nmemb*sizeof(T)*8;
        
        return nmemb; /* FIXME: Add error handling */
    }
    
private:
    FILE *_fout;
    
    uint8_t _buffer[BUFFER_SIZE];
    uint64_t _bitp;
    uint8_t *_curr_byte;
    
    int bytes_left();
    int write_buffer();
    int is_byte_aligned();
    
    template<typename T> int write_word_LE(T data);
    template<typename T> int write_word_LEs(T *data, int nmemb);
};

#endif