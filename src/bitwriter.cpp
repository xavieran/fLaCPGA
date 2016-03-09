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
    /******** THIS IS REALLY REALLY BAD !!!!!!!!!! 
     * What happens if we are writing a rice partition and the buffer needs to
     * be written? Fix by not writing the last byte until a flush is called and
     * copy that last byte to the first part of the buffer */
    
    // Make sure we also catch the last byte if it has been halfwritten
    int bytes_to_write = _curr_byte - _buffer + (_bitp % 8 != 0);
    // Shift the last piece of the buffer over if it is not full
    // (*_curr_byte) <<= 8 - _bitp % 8; 
    int bytes_written = fwrite(_buffer, sizeof(uint8_t), bytes_to_write, _fout);
    fflush(_fout);
    _curr_byte = _buffer;
    memset(_buffer, 0, BUFFER_SIZE);
    return bytes_written;
}

void BitWriter::reset(){
    _curr_byte = _buffer;
    rewind(_fout);
    _bitp = 0;
    memset(_buffer, 0, BUFFER_SIZE);
}

int BitWriter::write_bits(uint64_t data, uint8_t bits){
    // blib = bits left in byte
    int blib = 0;
    
    while (bits != 0){
        blib = 8 - (_bitp % 8);
        if (blib == 8 && this->bytes_left() == 0)
            this->write_buffer(); //Check for EOF
            
        if (bits < blib){
            (*_curr_byte) <<= bits;
            (*_curr_byte) |= ((1 << bits) - 1) & data;
            _bitp += bits;
            // If we have thus filled the buffer, increase _curr_byte
            if (_bitp % 8 == 0)
                _curr_byte++;
            bits = 0;
        } else { // Bits do not fit in one byte
            (*_curr_byte) <<= blib;
            (*_curr_byte) |= ((1 << bits) - 1) & (data >> (bits - blib));
            bits -= blib;
            _curr_byte++;
            _bitp += blib;
            if (this->bytes_left() == 0){
                write_buffer();
            }
        }
    }
    return 1;
}

int BitWriter::write_unary(uint32_t data){
    // Since we memset the buffer to 0, in order to "write" n zeros, we just
    // skip n bits and write a 1
    
    unsigned blib = 8 - _bitp % 8;
    // Ensure that we appropriately shift the bits in the buffer
    if (data > blib)
        (*_curr_byte) <<= blib;
    else
        (*_curr_byte) <<= data;
    
    _bitp += data;
    _curr_byte += (_bitp / 8) - (_curr_byte - _buffer);
    
    
    write_bits(1, 1);
    return 1;
}

int BitWriter::write_rice(int32_t data, unsigned rice_param){
    // Convert the signed data into an unsigned value. We can't perform right shifting on a neg number...
    unsigned msbs, lsbs, uval;
    
    //printf("data: 0x%x ", data);
    uval = data;
    uval <<= 1; // Shift signed value over by one
    uval ^= (data >> 31); // xor the unsigned value with the sign bit of data
    //printf("uval: 0x%x ", uval);
    
    msbs = uval >> rice_param;
    lsbs = uval & ((1 << rice_param) - 1); // LSBs are the last rice_param number of bits
    
    printf("msbs: %d lsbs: 0x%x\n\n", msbs, lsbs);
    
    write_unary(msbs);
    write_bits(lsbs, rice_param);
    //printf("AF RI Current byte: %d current bit: %d\n", _curr_byte - _buffer, _bitp % 8);
    return 1;
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