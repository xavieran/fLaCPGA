
#ifndef BITREADER_H
#define BITREADER_H

#define READ_COUNT 1024

class FileReader {
private:
    FILE *fin;
    uint64_t bit;
    uint8_t buffer[READ_COUNT];
    uint8_t get_mask(uint8_t bits);
    int smemcpy(void *dst, int dst_off, uint8_t *src, int size, int nmemb);
    /* Use exceptions...*/
    int read_error(FILE *f);

    
public:
    FileReader(FILE *f);
    
    int reset_file();
    int read_file(void *buf, int size, int nmemb);
    
    int reset_bit_count();
    int read_bits_uint64(uint64_t *x, uint8_t bits);
    int read_bits_uint32(uint32_t *x, uint8_t bits);
    int read_bits_uint16(uint16_t *x, uint8_t bits);
    int read_bits_uint8(uint8_t *x, uint8_t bits);
    
    int read_bits_unary(uint8_t *x);
    int read_utf8_uint64(uint64_t *val);
    int read_utf8_uint32(uint32_t *val);
};

#endif