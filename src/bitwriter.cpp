/* Implementation of a bitwriter */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "bitwriter.hpp"

BitWriter::BitWriter(FILE *f){
    _fout = f;
    _curr_byte = _buffer;
    _bitp = 0;
    memset(_buffer, 0, BUFFER_SIZE);
}

void BitWriter::write_error(){
    fprintf(stderr, "Failed to write file\n");
    fclose(_fout);
    exit(1);
}

int BitWriter::bytes_left(){
    return BUFFER_SIZE - (_curr_byte - _buffer);
}

int BitWriter::is_byte_aligned(){
    return _bitp % 8 == 0;
}

int BitWriter::write_buffer(){
    int bytes_written = fwrite(_buffer, sizeof(uint8_t), _curr_byte - _buffer, _fout);
    fflush(_fout);
    _curr_byte = _buffer;
    return bytes_written;
}

void BitWriter::reset(){
    _curr_byte = _buffer;
    rewind(_fout);
    _bitp = 0;
    memset(_buffer, 0, BUFFER_SIZE);
}

template<typename T> int BitWriter::write_word_LE(T data){
    //printf("%d\n",this->bytes_left());
    assert(is_byte_aligned());
    for (int i = 0; i < sizeof(T); i++){
        if (bytes_left() == 0)
            write_buffer();
        
        (*_curr_byte++) = (uint8_t) (data >> i*8);
    }
    return 1;
}

template<typename T> int BitWriter::write_word_LEs(T *data, int nmemb){
    for (int i = 0; i < nmemb; i++){
        write_word_LE<T>(data[i]);
    }
    return true; /* FIXME: Error checking... */
}

int BitWriter::write_word_u32LE(uint32_t data){
    return write_word_LE<uint32_t>(data);
}

int BitWriter::write_word_u16LE(uint16_t data){
    return write_word_LE<uint16_t>(data);
}

int BitWriter::write_word_i16LE(int16_t data){
    return write_word_u16LE((uint16_t) data);
}