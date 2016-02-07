/* General read and write functions - Header file */

int read_error(FILE *f);

int write_error(FILE *f);

int write_little_endian_uint16(FILE *fout, uint16_t data);

int write_little_endian_uint32(FILE *fout, uint32_t data);

int write_little_endian_int16(FILE *fout, int16_t data);

struct FileReader {
    FILE *fin;
    uint8_t bit;
    uint8_t buffer[16];
};

struct FileReader new_file_reader(FILE * f);

uint64_t read_bits_uint64(struct FileReader *fr, uint8_t bits);
uint32_t read_bits_uint32(struct FileReader *fr, uint8_t bits);
uint16_t read_bits_uint16(struct FileReader *fr, uint8_t bits);
uint8_t read_bits_uint8(struct FileReader *fr, uint8_t bits);
