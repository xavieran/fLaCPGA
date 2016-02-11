/* Implementation of a bitreader */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

int read_error(FILE *f){
    fprintf(stderr, "Failed to read file\n");
    fclose(f);
    exit(1);
}

uint8_t get_mask(uint8_t bits){
    switch (bits){
        case 0: return 0xff;
        case 1: return 0x80;
        case 2: return 0xc0;
        case 3: return 0xe0;
        case 4: return 0xf0;
        case 5: return 0xf8;
        case 6: return 0xfc;
        case 7: return 0xfe;
        case 8: return 0xff;
    }
}

/* Read a file bit-by-bit */
struct FileReader {
    FILE *fin;
    uint64_t bit;
    uint8_t buffer[1];
};

struct FileReader new_file_reader(FILE * f){
    struct FileReader fr;
    fr.fin = f;
    fr.bit = 0;
    return fr;
}

int reset_file_reader(struct FileReader * fr){
    fr->bit = 0;
    return 1;
}

int read_bits_uint64(struct FileReader *fr, uint64_t *x, uint8_t bits){
    /* Convert this to big endian */
    int bits_left_in_byte;
    uint64_t t = 0;
    
    while (bits > 0){
        bits_left_in_byte = 8 - (fr->bit % 8);
        if (bits_left_in_byte == 8)
            fread(fr->buffer, 1, 1, fr->fin);
        
        if (bits > bits_left_in_byte){
            t <<= bits_left_in_byte;
            t |= ((fr->buffer[0] & get_mask(bits_left_in_byte)) >> (8-bits_left_in_byte));
            bits -= bits_left_in_byte;
            fr->bit += bits_left_in_byte;
        } else {
            t <<= bits;
            t |= ((fr->buffer[0] & get_mask(bits)) >> (8 - bits));
            fr->buffer[0] <<= bits;
            fr->bit += bits;
            bits = 0;
        }
    }
    
    *x = t;
    return 1;
}

int read_bits_uint32(struct FileReader *fr, uint32_t *x, uint8_t bits){
    //return read_bits_uint64(fr, (uint64_t*)x, bits);
    int bits_left_in_byte;
    uint32_t t = 0;
    
    while (bits > 0){
        bits_left_in_byte = 8 - (fr->bit % 8);
        if (bits_left_in_byte == 8)
            fread(fr->buffer, 1, 1, fr->fin);
        
        if (bits > bits_left_in_byte){
            t <<= bits_left_in_byte;
            t |= ((fr->buffer[0] & get_mask(bits_left_in_byte)) >> (8-bits_left_in_byte));
            bits -= bits_left_in_byte;
            fr->bit += bits_left_in_byte;
        } else {
            t <<= bits;
            t |= ((fr->buffer[0] & get_mask(bits)) >> (8 - bits));
            fr->buffer[0] <<= bits;
            fr->bit += bits;
            bits = 0;
        }
    }
    
    *x = t;
    return 1;
}


int read_bits_uint16(struct FileReader *fr, uint16_t *x, uint8_t bits){
    //return read_bits_uint64(fr, (uint64_t*)x, bits);
    int bits_left_in_byte;
    uint16_t t = 0;
    
    while (bits > 0){
        bits_left_in_byte = 8 - (fr->bit % 8);
        if (bits_left_in_byte == 8)
            fread(fr->buffer, 1, 1, fr->fin);
        
        if (bits > bits_left_in_byte){
            t <<= bits_left_in_byte;
            t |= ((fr->buffer[0] & get_mask(bits_left_in_byte)) >> (8-bits_left_in_byte));
            bits -= bits_left_in_byte;
            fr->bit += bits_left_in_byte;
        } else {
            t <<= bits;
            t |= ((fr->buffer[0] & get_mask(bits)) >> (8 - bits));
            fr->buffer[0] <<= bits;
            fr->bit += bits;
            bits = 0;
        }
    }
    
    *x = t;
    return 1;
}


int read_bits_uint8(struct FileReader *fr, uint8_t *x, uint8_t bits){
    //return read_bits_uint64(fr, (uint64_t*)x, bits);
    int bits_left_in_byte;
    uint8_t t = 0;
    
    while (bits > 0){
        bits_left_in_byte = 8 - (fr->bit % 8);
        if (bits_left_in_byte == 8)
            fread(fr->buffer, 1, 1, fr->fin);
        
        if (bits > bits_left_in_byte){
            t <<= bits_left_in_byte;
            t |= ((fr->buffer[0] & get_mask(bits_left_in_byte)) >> (8-bits_left_in_byte));
            bits -= bits_left_in_byte;
            fr->bit += bits_left_in_byte;
        } else {
            t <<= bits;
            t |= ((fr->buffer[0] & get_mask(bits)) >> (8 - bits));
            fr->buffer[0] <<= bits;
            fr->bit += bits;
            bits = 0;
        }
    }
    
    *x = t;
    return 1;
}

int read_bits_unary(struct FileReader *fr, uint32_t *x){
    int c = 0;
    uint8_t b = 0;
    while (!b){
        read_bits_uint8(fr, &b, 1);
        c++;
    }
    
    *x = c;
    return 1;
}



/* This code borrowed from libFLAC */
/* on return, if *val == 0xffffffff then the utf-8 sequence was invalid, but the return value will be true */
int read_utf8_uint32(struct FileReader *fr, uint32_t *val){
    uint32_t v = 0;
    uint32_t x;
    unsigned i;

    if (!read_bits_uint32(fr, &x, 8))
        return 0;
    if(!(x & 0x80)) { /* 0xxxxxxx */
        v = x;
        i = 0;
    }
    else if(x & 0xC0 && !(x & 0x20)) { /* 110xxxxx */
        v = x & 0x1F;
        i = 1;
    }
    else if(x & 0xE0 && !(x & 0x10)) { /* 1110xxxx */
        v = x & 0x0F;
        i = 2;
    }
    else if(x & 0xF0 && !(x & 0x08)) { /* 11110xxx */
        v = x & 0x07;
        i = 3;
    }
    else if(x & 0xF8 && !(x & 0x04)) { /* 111110xx */
        v = x & 0x03;
        i = 4;
    }
    else if(x & 0xFC && !(x & 0x02)) { /* 1111110x */
        v = x & 0x01;
        i = 5;
    }
    else {
        *val = 0xffffffff;
        return 1;
    }
    for( ; i; i--) {
        if (!read_bits_uint32(fr, &x, 8))
            return 0;
        if (!(x & 0x80) || (x & 0x40)) { /* 10xxxxxx */
            *val = 0xffffffff;
            return 1;
        }
        v <<= 6;
        v |= (x & 0x3F);
    }
    *val = v;
    return 1;
}

/* on return, if *val == 0xffffffffffffffff then the utf-8 sequence was invalid, but the return value will be true */
int read_utf8_uint64(struct FileReader *fr, uint64_t *val){
    uint64_t v = 0;
    uint32_t x;
    unsigned i;

    if (!read_bits_uint32(fr, &x, 8))
        return 0;
    if(!(x & 0x80)) { /* 0xxxxxxx */
        v = x;
        i = 0;
    }
    else if(x & 0xC0 && !(x & 0x20)) { /* 110xxxxx */
        v = x & 0x1F;
        i = 1;
    }
    else if(x & 0xE0 && !(x & 0x10)) { /* 1110xxxx */
        v = x & 0x0F;
        i = 2;
    }
    else if(x & 0xF0 && !(x & 0x08)) { /* 11110xxx */
        v = x & 0x07;
        i = 3;
    }
    else if(x & 0xF8 && !(x & 0x04)) { /* 111110xx */
        v = x & 0x03;
        i = 4;
    }
    else if(x & 0xFC && !(x & 0x02)) { /* 1111110x */
        v = x & 0x01;
        i = 5;
    }
    else if(x & 0xFE && !(x & 0x01)) { /* 11111110 */
        v = 0;
        i = 6;
    }
    else {
        *val = (uint64_t) 0xffffffffffffffff;
        return 1;
    }
    for( ; i; i--) {
        if (!read_bits_uint32(fr, &x, 8))
            return 0;
        if(!(x & 0x80) || (x & 0x40)) { /* 10xxxxxx */
            *val = (uint64_t)0xffffffffffffffff;
            return 1;
        }
        v <<= 6;
        v |= (x & 0x3F);
    }
    *val = v;
    return 1;
}


