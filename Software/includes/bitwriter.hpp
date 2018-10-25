/**************************************/
/* bitwriter.pp - Read and write bits  */
/************************************/

#ifndef BIT_WRITER_H
#define BIT_WRITER_H

#include "crc.hpp"

#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <fstream>
#include <iostream>
#include <memory>
#include <vector>


class BitWriter {
public:
  BitWriter(std::shared_ptr<std::fstream> f);

  void write_error();

  /* Write the rightmost bits in data to file */
  int write_bits(uint64_t data, uint8_t bits);
  int write_unary(uint32_t data);
  int write_rice(int32_t data, unsigned rice_param);

  int write_residual(int32_t *data, int blk_size, int pred_order,
                     uint8_t coding_method,
                     std::vector<uint8_t> &part_rice_params);
  int write_rice_partition(int32_t *data, uint64_t nsamples, int extended,
                           uint8_t rice_param);

  // int write_utf8_uint64(uint64_t *val);
  bool write_utf8(uint32_t val);

  void mark_frame_start();
  uint8_t calc_crc8();
  uint16_t calc_crc16();

  void write_padding();

  int flush() { return write_buffer(); }

  template <typename T> int write_chunk(T *data, int nmemb);
  template <typename T> int write_word_LE(T data);
  template <typename T> int write_words_LE(T *data, int nmemb);

  void reset();

private:
  std::shared_ptr<std::fstream> _fout;

  static const uint32_t BUFFER_SIZE{1000000};
  uint8_t _buffer[BUFFER_SIZE];
  uint64_t _bitp;
  uint8_t *_curr_byte;
  uint8_t *_frame_start;

  int bytes_left();
  int write_buffer();
  int is_byte_aligned();
};

#include "bitwriter.tpp"

#endif
