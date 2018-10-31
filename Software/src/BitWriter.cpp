/* Implementation of a bitwriter */

#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <fstream>
#include <iostream>
#include <memory>
#include <vector>

#include "BitWriter.hpp"

BitWriter::BitWriter(std::shared_ptr<std::fstream> f) {
    _fout = f;
    _curr_byte = _buffer;
    _bitp = 0;
    memset(_buffer, 0, BUFFER_SIZE);
}

void BitWriter::write_error() {
    fprintf(stderr, "Failed to write file\n");
    _fout->close();
    exit(1);
}

int BitWriter::bytes_left() {
    return BUFFER_SIZE - (_curr_byte - _buffer);
}

int BitWriter::is_byte_aligned() {
    return _bitp % 8 == 0;
}

int BitWriter::write_buffer() {
    assert(is_byte_aligned() == 1);
    // fprintf(stderr, "BUFFER: %x %x %x %x\n", _curr_byte[-3], _curr_byte[-2],
    // _curr_byte[-1], _curr_byte[0]);
    // fprintf(stderr, "Bitp: %d Bytes: %d\n", _bitp, _curr_byte - _buffer);
    int bytes_to_write = _curr_byte - _buffer;
    _fout->write((char *)_buffer, bytes_to_write); // Not a fan of this cast
    _fout->flush();
    _curr_byte = _buffer;
    _bitp = 0;
    memset(_buffer, 0, BUFFER_SIZE);

    return bytes_to_write;
}

void BitWriter::reset() {
    _curr_byte = _buffer;
    _fout->seekp(0);
    _bitp = 0;
    memset(_buffer, 0, BUFFER_SIZE);
}

int BitWriter::write_bits(uint64_t data, uint8_t bits) {
    // blib = bits left in byte
    int blib = 0;
    // fprintf(stderr, "Writing: %d\n", data);
    while (bits != 0) {
        blib = 8 - (_bitp % 8);
        if (blib == 8 && this->bytes_left() == 0)
            this->write_buffer(); // Check for EOF

        // fprintf(stderr, "Bytes Left: %d Current Byte: %d \n", bytes_left(),
        // (_curr_byte - _buffer));
        if (bits < blib) {
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
            if (this->bytes_left() == 0) {
                write_buffer();
            }
        }
    }
    return 1;
}

int BitWriter::write_unary(uint32_t data) {
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

int BitWriter::write_rice(int32_t data, unsigned rice_param) {
    // Convert the signed data into an unsigned value. We can't perform right
    // shifting on a neg number...
    unsigned msbs, lsbs, uval;

    // printf("data: 0x%x ", data);
    uval = data;
    uval <<= 1;           // Shift signed value over by one
    uval ^= (data >> 31); // xor the unsigned value with the sign bit of data
    // printf("uval: 0x%x ", uval);

    msbs = uval >> rice_param;
    lsbs = uval & ((1 << rice_param) - 1); // LSBs are the last rice_param number of bits

    /// fprintf(stderr, "val: %d rp: %d msbs: %d lsbs: 0x%x\n", data,
    /// rice_param, msbs, lsbs);

    write_unary(msbs);
    write_bits(lsbs, rice_param);
    /*for (int i = 0; i < (_curr_byte - _buffer); i++){
        fprintf(stderr, "%x", _buffer[i]);
    }
    fprintf(stderr, "\n");*/
    return 1;
}

int BitWriter::write_residual(int32_t *data, int block_size, int pred_order, uint8_t coding_method,
                              std::vector<uint8_t> &part_rice_params) {
    uint64_t nsamples = 0;
    uint8_t part_order = 0;

    int x = part_rice_params.size();
    for (; x > 0; part_order++)
        x >>= 1;
    part_order--;

    write_bits(coding_method, 2);
    write_bits(part_order, 4);

    int s = 0;
    int i;
    for (i = 0; i < (1 << part_order); i++) {
        /* Calculate the number of samples */
        if (part_order == 0)
            nsamples = block_size - pred_order;
        else if (i != 0)
            nsamples = block_size / (1 << part_order);
        else
            nsamples = block_size / (1 << part_order) - pred_order;
        s += write_rice_partition(data, nsamples, coding_method, part_rice_params.at(i));

        data += nsamples; /* Move pointer forward... */
    }
    return s;
}

int BitWriter::write_rice_partition(int32_t *data, uint64_t nsamples, int extended, uint8_t rice_param) {
    // It would be nice for this to vary, but I'll stick with supporting 16 bit
    // FLAC for now
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

void BitWriter::mark_frame_start() {
    _frame_start = _curr_byte;
}

uint8_t BitWriter::calc_crc8() {
    return FLAC_CRC::crc8(_frame_start, (unsigned)(_curr_byte - _frame_start));
}

uint16_t BitWriter::calc_crc16() {
    return FLAC_CRC::crc16(_frame_start, (unsigned)(_curr_byte - _frame_start));
}

void BitWriter::write_padding() {
    // fprintf(stderr, "Writing padding: bitp: %d curr: %d\n", _bitp, _curr_byte
    // - _buffer);
    if (!is_byte_aligned()) { // Not byte aligned
        _bitp += (8 - _bitp % 8);
        _curr_byte++; /* FIXME: Should do bounds checking here... */
    }
    // fprintf(stderr, "Finished padding: bitp: %d curr: %d\n", _bitp,
    // _curr_byte - _buffer);
}

/* This code borrowed from libFLAC */

bool BitWriter::write_utf8(uint32_t val) {
    assert(!(val & 0x80000000)); /* this version only handles 31 bits */

    if (val < 0x80) {
        write_bits(val, 8);
        return true;
    } else if (val < 0x800) {
        write_bits(0xC0 | (val >> 6), 8);
        write_bits(0x80 | (val & 0x3F), 8);
        return true;
    } else if (val < 0x10000) {
        write_bits(0xE0 | (val >> 12), 8);
        write_bits(0x80 | ((val >> 6) & 0x3F), 8);
        write_bits(0x80 | (val & 0x3F), 8);
        return true;
    } else if (val < 0x200000) {
        write_bits(0xF0 | (val >> 18), 8);
        write_bits(0x80 | ((val >> 12) & 0x3F), 8);
        write_bits(0x80 | ((val >> 6) & 0x3F), 8);
        write_bits(0x80 | (val & 0x3F), 8);
        return true;
    } else if (val < 0x4000000) {
        write_bits((uint8_t)(0xF8 | (val >> 24)), 8);
        write_bits((uint8_t)(0x80 | ((val >> 18) & 0x3F)), 8);
        write_bits((uint8_t)(0x80 | ((val >> 12) & 0x3F)), 8);
        write_bits((uint8_t)(0x80 | ((val >> 6) & 0x3F)), 8);
        write_bits((uint8_t)(0x80 | (val & 0x3F)), 8);
        return true;
    } else {
        write_bits(0xFC | (val >> 30), 8);
        write_bits(0x80 | ((val >> 24) & 0x3F), 8);
        write_bits(0x80 | ((val >> 18) & 0x3F), 8);
        write_bits(0x80 | ((val >> 12) & 0x3F), 8);
        write_bits(0x80 | ((val >> 6) & 0x3F), 8);
        write_bits(0x80 | (val & 0x3F), 8);
        return true;
    }
}
