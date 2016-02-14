
#ifndef BITREADER_H
#define BITREADER_H

#define READ_COUNT 512

class FileReader {
private:
FILE *fin;
    uint64_t bit;
    
    int bytes_read;
    int bytes_consumed;
    
    int eof;
    
    uint8_t bitbuf[1];
    uint8_t buffer[READ_COUNT];
    
    uint8_t get_mask(uint8_t bits);
    int smemcpy(void *dst, int dst_off, uint8_t *src, int size, int nmemb);
   
public:
    FileReader(FILE *f);
    int read_error();
    
    int set_input_file(FILE *f);
    
    int reset_bit_count();
    int read_bits_uint64(uint64_t *x, uint8_t bits);
    int read_bits_uint32(uint32_t *x, uint8_t bits);
    int read_bits_uint16(uint16_t *x, uint8_t bits);
    int read_bits_uint8(uint8_t *x, uint8_t bits);
    
    int read_bits_unary(uint16_t *x);
    int read_utf8_uint64(uint64_t *val);
    int read_utf8_uint32(uint32_t *val);
    
    int read_file(void *buf, int size, int nmemb);
    int reset_file();
};

#endif