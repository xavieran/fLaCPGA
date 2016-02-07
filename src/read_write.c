/* General read and write functions */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

int read_error(FILE *f){
    fprintf(stderr, "Failed to read file\n");
    fclose(f);
    exit(1);
}

int write_error(FILE *f){
    fprintf(stderr, "Failed to write file\n");
    fclose(f);
    exit(1);
}

int write_little_endian_uint16(FILE *fout, uint16_t data){
    return fputc(data, fout) != EOF && fputc(data >> 8, fout) != EOF;
}

int write_little_endian_uint32(FILE *fout, uint32_t data){
    return
        fputc(data, fout) != EOF &&
        fputc(data >> 8, fout) != EOF &&
        fputc(data >> 16, fout) != EOF &&
        fputc(data >> 24, fout) != EOF;
}

int write_little_endian_int16(FILE *fout, int16_t data){
    return write_little_endian_uint16(fout, (uint16_t) data);
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