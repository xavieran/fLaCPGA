/* Implementation of a bitwriter */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>


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
