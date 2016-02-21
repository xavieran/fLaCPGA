
#ifndef BITREADER_H
#define BITREADER_H

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define BUFFER_SIZE 8192

class FileReader {
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
    
    int read_word_u32LE(uint32_t *x);
    int read_word_u16LE(uint16_t *x);
    int read_word_i16LE(int16_t *x);
    
    int read_words_u32LE(uint32_t *dst, uint64_t words);
    int read_words_u16LE(uint16_t *dst, uint64_t words);
    int read_words_i16LE(int16_t *dst, uint64_t words);
    
    int read_bits_unary_uint32(uint32_t *x);
    int read_bits_unary_uint16(uint16_t *x);
    
    int read_rice_signed(int32_t *x, uint8_t M);
    
    int read_utf8_uint64(uint64_t *val);
    int read_utf8_uint32(uint32_t *val);
    
    int read_residual(int32_t *dst, int blk_size, int pred_order);
    
    template<typename T> int read_chunk(T *dst, int nmemb){
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
    
    int read_file(void *buf, int size, int nmemb);
    int reset_file();
    
private:
    FILE *_fin;
    
    uint64_t _bitp;
    uint8_t *_curr_byte;
    uint8_t _buffer[BUFFER_SIZE];
    int _eof;
    
    int bytes_left();
    int refill_buffer();
    int is_byte_aligned();
    
    uint8_t get_mask(uint8_t bits);
    
    template<typename T> int read_bits(T *x, uint8_t bits);
    template<typename T> int read_word_LE(T *x);
    template<typename T> int read_words_LE(T *x, uint64_t words);
    int smemcpy(void *dst, int dst_off, uint8_t *src, int size, int nmemb);
    /* Use exceptions...*/
    
    int read_rice_partition(int32_t *dst, uint64_t nsamples, int extended);

    template<typename T> int read_bits_unary(T *x);
};

#endif