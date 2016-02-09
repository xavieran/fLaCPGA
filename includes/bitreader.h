/* bitreader.h - Header file */

int read_error(FILE *f);

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
