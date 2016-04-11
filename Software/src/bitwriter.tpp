/* Implementation of a bitwriter */

#ifndef BIT_WRITER_T
#define BIT_WRITER_T

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include <iostream>
#include <fstream>
#include <memory>

#include "bitwriter.hpp"

template<typename T> int BitWriter::write_word_LE(T data){
    //printf("%d\n",this->bytes_left());
    assert(is_byte_aligned());
    for (unsigned i = 0; i < sizeof(T); i++){
        if (bytes_left() == 0)
            write_buffer();
        
        (*_curr_byte++) = (uint8_t) (data >> i*8);
    }
    return 1;
}

template<typename T> int BitWriter::write_words_LE(T *data, int nmemb){
    for (unsigned i = 0; i < nmemb; i++){
        write_word_LE<T>(data[i]);
    }
    return true; /* FIXME: Error checking... */
}

template<typename T> int BitWriter::write_chunk(T *data, int nmemb){
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

#endif