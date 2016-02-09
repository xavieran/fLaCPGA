/* bitreader.h - Header file */

#ifndef FLAC_BITREADER_H
#define FLAC_BITREADER_H

int read_error(FILE *f);

struct FileReader {
    FILE *fin;
    uint8_t bit;
    uint8_t buffer[16];
};

struct FileReader new_file_reader(FILE * f);

int read_bits_uint64(struct FileReader *fr, uint64_t *x, uint8_t bits);
int read_bits_uint32(struct FileReader *fr, uint32_t *x, uint8_t bits);
int read_bits_uint16(struct FileReader *fr, uint16_t *x, uint8_t bits);
int read_bits_uint8(struct FileReader *fr, uint8_t *x, uint8_t bits);

int read_bits_unary(struct FileReader *fr, uint32_t *x);

int read_utf8_uint32(struct FileReader *fr, uint32_t *val);
int read_utf8_uint64(struct FileReader *fr, uint64_t *val);

#endif