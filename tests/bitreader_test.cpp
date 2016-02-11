
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <assert.h>

#include "bitreader.hpp"

/* Test File Contents */

#define FTEST2 "test2.bin"
#define FTEST3 "test3.bin"

int main(int argc, char **argv){
    
    
    /* Test 1 - bit reading */
    printf("Test 1 - Bit reading\n");
    /* 96 8C B0 0A */
    
    FILE *f = fopen("test1.bin", "rb");
    FileReader *fr = new FileReader(f);
    
    uint8_t t;
    
    (*fr).read_bits_uint8(&t, 8);
    printf("\tRead 8 bits: %x =? 0x96\n", t);
    assert(t == 0x96);
    
    (*fr).read_bits_uint8(&t, 1);
    printf("\tRead 1 bit: %d =? 1\n", t);
    assert(t == 1);
    
    fr->read_bits_uint8(&t, 1);
    printf("\tRead 1 bit: %d =? 0\n", t);
    assert(t == 0);
    
    fr->read_bits_uint8(&t, 4);
    printf("\tRead 4 bits (mid byte): %x =? 0x3\n", t);
    assert(t==0x3);
    
    fr->read_bits_uint8(&t, 7);
    printf("\tRead 7 bits (byte boundary): %x =? 0x16\n", t);
    assert(t==0x16);
    
    fclose(f);
    delete fr;
    
    
    /* Test 2 - "fread"ing */
    printf ("Test 2 - \"fread\"ing\n");
    
    f = fopen("test2.bin", "rb");
    FILE *f2 = fopen("test2copy.bin", "rb");
    
    fr = new FileReader(f);
    
    uint8_t *buf8 = (uint8_t *)calloc(sizeof(uint8_t), 60);
    uint8_t *buf28 = (uint8_t *)calloc(sizeof(uint8_t), 60);
    
    printf("Reading 8 bytes\n");
    fr->read_file(buf8, 1, 8);
    fread(buf28, 1, 8, f2);
    int i;
    for (i = 0; i < 8; i++){
        printf("%d =? <%d>\n", buf8[i], buf28[i]);
        assert(buf8[i] == buf28[i]);
    }
    
    
    uint16_t *buf16 = (uint16_t *)calloc(sizeof(uint16_t), 60);
    uint16_t *buf216 = (uint16_t *)calloc(sizeof(uint16_t), 60);
    
    printf("Reading 16 uint16_t's\n");
    fr->read_file(buf16, 2, 16);
    fread(buf216, 2, 16, f2);
    for (i = 0; i < 16; i++){
        printf("%d =? <%d>\n", buf16[i], buf216[i]);fflush(stdout);
        assert(buf16[i] == buf216[i]);
    }
    
    uint32_t *buf32 = (uint32_t *)calloc(sizeof(uint32_t), 60);
    uint32_t *buf232 = (uint32_t *)calloc(sizeof(uint32_t), 60);
    
    printf("Reading 8 uint32_t's\n");
    fr->read_file(buf32, 4, 8);
    fread(buf232, 4, 8, f2);
    for (i = 0; i < 8; i++){
        printf("%d =? <%d>\n", buf32[i], buf232[i]);fflush(stdout);
        assert(buf32[i] == buf232[i]);
    }
    
    
    
    
    return 1;
    
}


