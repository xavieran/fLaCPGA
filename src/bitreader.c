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
    uint8_t buffer[16];
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

uint64_t read_bits_uint64(struct FileReader *fr, uint8_t bits){
    /* Convert this to big endian */
    int bits_left_in_byte;
    uint64_t x = 0;
    
    //printf("\n\nBits wanted %d\n", bits);
    while (bits > 0){
        bits_left_in_byte = 8 - (fr->bit % 8);
        if (bits_left_in_byte == 8)
            fread(fr->buffer, 1, 1, fr->fin);
        //    printf("\nReaded\n");}
            
        //printf("Bits Left: %d frbit: %ld bits: %d\n", bits_left_in_byte, fr->bit, bits);
        //printf("current buffer-> %x\n", fr->buffer[0]);
        
        if (bits > bits_left_in_byte){
            //printf("More bits wanted than left %x\n", get_mask(bits_left_in_byte));
            x <<= bits_left_in_byte;
            x |= ((fr->buffer[0] & get_mask(bits_left_in_byte)) >> (8-bits_left_in_byte));
            //x = (x << bits_left_in_byte) | ((fr->buffer[0] & get_mask(bits_left_in_byte)) >> (8-bits_left_in_byte));
            bits -= bits_left_in_byte;
            fr->bit += bits_left_in_byte;
        } else {
            //printf("Less bits wanted than left %x and %d\n", (fr->buffer[0] & get_mask(bits)), 8-bits);
            x <<= bits;
            x |= ((fr->buffer[0] & get_mask(bits)) >> (8 - bits));
            //x = (x << bits) | ((fr->buffer[0] & get_mask(bits)) >> (8 - bits));
            fr->buffer[0] <<= bits;
            fr->bit += bits;
            bits = 0;
        }
        //printf("X: %ld\n", x);
    }
    //printf("Returning %ld\n\n", x);
    return x;
}

uint32_t read_bits_uint32(struct FileReader *fr, uint8_t bits){
    return (uint32_t)read_bits_uint64(fr, bits);
}


uint16_t read_bits_uint16(struct FileReader *fr, uint8_t bits){
    return (uint16_t)read_bits_uint64(fr, bits);
}


uint8_t read_bits_uint8(struct FileReader *fr, uint8_t bits){
    return (uint8_t)read_bits_uint64(fr, bits);
}


/* on return, if *val == 0xffffffff then the utf-8 sequence was invalid, but the return value will be true */
// int FLAC__bitreader_read_utf8_uint32(struct FileReader *fr, uint32_t *val, uint8_t *raw, unsigned *rawlen)
// {
//     FLAC__uint32 v = 0;
//     FLAC__uint32 x;
//     unsigned i;
// 
//     if(!FLAC__bitreader_read_raw_uint32(br, &x, 8))
//         return false;
//     if(raw)
//         raw[(*rawlen)++] = (FLAC__byte)x;
//     if(!(x & 0x80)) { /* 0xxxxxxx */
//         v = x;
//         i = 0;
//     }
//     else if(x & 0xC0 && !(x & 0x20)) { /* 110xxxxx */
//         v = x & 0x1F;
//         i = 1;
//     }
//     else if(x & 0xE0 && !(x & 0x10)) { /* 1110xxxx */
//         v = x & 0x0F;
//         i = 2;
//     }
//     else if(x & 0xF0 && !(x & 0x08)) { /* 11110xxx */
//         v = x & 0x07;
//         i = 3;
//     }
//     else if(x & 0xF8 && !(x & 0x04)) { /* 111110xx */
//         v = x & 0x03;
//         i = 4;
//     }
//     else if(x & 0xFC && !(x & 0x02)) { /* 1111110x */
//         v = x & 0x01;
//         i = 5;
//     }
//     else {
//         *val = 0xffffffff;
//         return true;
//     }
//     for( ; i; i--) {
//         if(!FLAC__bitreader_read_raw_uint32(br, &x, 8))
//             return false;
//         if(raw)
//             raw[(*rawlen)++] = (FLAC__byte)x;
//         if(!(x & 0x80) || (x & 0x40)) { /* 10xxxxxx */
//             *val = 0xffffffff;
//             return true;
//         }
//         v <<= 6;
//         v |= (x & 0x3F);
//     }
//     *val = v;
//     return true;
// }
// 
// /* on return, if *val == 0xffffffffffffffff then the utf-8 sequence was invalid, but the return value will be true */
// FLAC__bool FLAC__bitreader_read_utf8_uint64(FLAC__BitReader *br, FLAC__uint64 *val, FLAC__byte *raw, unsigned *rawlen)
// {
//     FLAC__uint64 v = 0;
//     FLAC__uint32 x;
//     unsigned i;
// 
//     if(!FLAC__bitreader_read_raw_uint32(br, &x, 8))
//         return false;
//     if(raw)
//         raw[(*rawlen)++] = (FLAC__byte)x;
//     if(!(x & 0x80)) { /* 0xxxxxxx */
//         v = x;
//         i = 0;
//     }
//     else if(x & 0xC0 && !(x & 0x20)) { /* 110xxxxx */
//         v = x & 0x1F;
//         i = 1;
//     }
//     else if(x & 0xE0 && !(x & 0x10)) { /* 1110xxxx */
//         v = x & 0x0F;
//         i = 2;
//     }
//     else if(x & 0xF0 && !(x & 0x08)) { /* 11110xxx */
//         v = x & 0x07;
//         i = 3;
//     }
//     else if(x & 0xF8 && !(x & 0x04)) { /* 111110xx */
//         v = x & 0x03;
//         i = 4;
//     }
//     else if(x & 0xFC && !(x & 0x02)) { /* 1111110x */
//         v = x & 0x01;
//         i = 5;
//     }
//     else if(x & 0xFE && !(x & 0x01)) { /* 11111110 */
//         v = 0;
//         i = 6;
//     }
//     else {
//         *val = FLAC__U64L(0xffffffffffffffff);
//         return true;
//     }
//     for( ; i; i--) {
//         if(!FLAC__bitreader_read_raw_uint32(br, &x, 8))
//             return false;
//         if(raw)
//             raw[(*rawlen)++] = (FLAC__byte)x;
//         if(!(x & 0x80) || (x & 0x40)) { /* 10xxxxxx */
//             *val = FLAC__U64L(0xffffffffffffffff);
//             return true;
//         }
//         v <<= 6;
//         v |= (x & 0x3F);
//     }
//     *val = v;
//     return true;
// }


