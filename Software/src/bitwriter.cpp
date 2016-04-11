/* Implementation of a bitwriter */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include <iostream>
#include <fstream>
#include <memory>
#include <vector>

#include "bitwriter.hpp"

BitWriter::BitWriter(std::shared_ptr<std::fstream> f){
    _fout = f;
    _curr_byte = _buffer;
    _bitp = 0;
    memset(_buffer, 0, BUFFER_SIZE);
}

void BitWriter::write_error(){
    fprintf(stderr, "Failed to write file\n");
    _fout->close();
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
     (*_curr_byte) <<= 8 - _bitp % 8; 
    //int bytes_written = fwrite(_buffer, sizeof(uint8_t), bytes_to_write, _fout);
    int bytes_written = 0;
    _fout->write((char *)_buffer, bytes_to_write); // Not a fan of this cast
    _fout->flush();
    _curr_byte = _buffer;
    memset(_buffer, 0, BUFFER_SIZE);
    return bytes_written;
}

void BitWriter::reset(){
    _curr_byte = _buffer;
    _fout->seekp(0);
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
    
    //printf("msbs: %d lsbs: 0x%x\n\n", msbs, lsbs);
    
    write_unary(msbs);
    write_bits(lsbs, rice_param);
    //printf("AF RI Current byte: %d current bit: %d\n", _curr_byte - _buffer, _bitp % 8);
    return 1;
}

int BitWriter::write_residual(int32_t *data, int blk_size, int pred_order, 
                              uint8_t coding_method, uint8_t part_order, 
                              std::vector<uint8_t> &part_rice_params){
    uint64_t nsamples = 0;
    write_bits(coding_method, 2);
    write_bits(part_order, 4);
    
    int s = 0;
    int i;
    for (i = 0; i < (1 << part_order); i++){
                /* Calculate the number of samples */
        if (part_order == 0)
            nsamples = blk_size - pred_order;
        else if (i != 0)
            nsamples = blk_size / (1 << part_order);
        else 
            nsamples = blk_size / (1 << part_order) - pred_order;
        s += write_rice_partition(data, nsamples, coding_method, part_rice_params[i]);
        data += nsamples; /* Move pointer forward... */
    }
    return s;
}

int BitWriter::write_rice_partition(int32_t *data, uint64_t nsamples, int extended, uint8_t rice_param){
    // It would be nice for this to vary, but I'll stick with supporting 16 bit FLAC for now
    uint8_t bps = 16; 
    uint8_t param_bits = (extended == 0) ? 4 : 5;
    unsigned i;
    write_bits(rice_param, param_bits);
    
    if (rice_param == 0xF || rice_param == 0x1F)
        write_bits(bps, 5);
    
    if (rice_param == 0xF || rice_param == 0x1F)
        for (i = 0; i < nsamples; i++) /* Read a chunk */
            write_bits(*(data + i), bps);
    else
        for (i = 0; i < nsamples; i++)
            write_rice(*(data + i), rice_param);
    return i;
}
