/* bitwriter.h - header file */

int write_error(FILE *f);

int write_little_endian_uint16(FILE *fout, uint16_t data);

int write_little_endian_uint32(FILE *fout, uint32_t data);

int write_little_endian_int16(FILE *fout, int16_t data);