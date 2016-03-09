
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <assert.h>

#include <iostream>
#include <ios>
#include <fstream>
#include <memory>

#include "bitreader.hpp"

/* Test File Contents */
/* test1.bin
 * 9    6    8    C    B    0    0    A
 * 1001 0110 1000 1100 1011 0000 0000 1010 
 *         | ||    |        |*/

int main(int argc, char **argv){
    
    
    /* Test 1 - bit reading */
    printf("Test 1 - Bit reading\n");
    /* 96 8C B0 0A */
    
    std::shared_ptr<std::ifstream> f= std::make_shared<std::ifstream>("test1.bin", std::ios::in | std::ios::binary);
    std::unique_ptr<FileReader> fr = std::make_unique<FileReader>(f);
    
    int test_failed = 0;
    int assertion = 0;
    uint8_t t;
    
    (*fr).read_bits(&t, 8);
    printf("\tRead 8 bits: 0x%x =? 0x96\n", t);
    assertion = (t == 0x96);
    if (!assertion){
        printf("FAILED\n"); test_failed++;
    }
    
    (*fr).read_bits(&t, 1);
    printf("\tRead 1 bit: 0x%d =? 1\n", t);
    assertion = (t == 1);
    if (!assertion){
        printf("FAILED\n"); test_failed++;
    }
    
    (*fr).read_bits(&t, 1);
    printf("\tRead 1 bit: 0x%d =? 0\n", t);
    assertion = (t == 0);
    if (!assertion){
        printf("FAILED\n"); test_failed++;
    }
    
    (*fr).read_bits(&t, 4);
    printf("\tRead 4 bits (mid byte): 0x%x =? 0x3\n", t);
    assertion = (t == 0x3);
    if (!assertion){
        printf("FAILED\n"); test_failed++;
    }
    
    (*fr).read_bits(&t, 7);
    printf("\tRead 7 bits (byte boundary): 0x%x =? 0x16\n", t);
    assert(t==0x16);
    assertion = (t == 0x16);
    if (!assertion){
        printf("FAILED\n"); test_failed++;
    }
    
    
    uint32_t p;
    fr->read_bits(&p, 24);
    printf("\tRead 24 bits (byte aligned): 0x%x =? 0x15486\n", p);
    f->close();
    
    printf("******************************\n");
    if (test_failed){
        
        printf("\t\tTest 1 - %d tests FAILED\n", test_failed);
    } else {
        printf("\t\tTest 1 - All Passed\n\n");
    }
    
    /* Test 2 - "fread"ing */
    printf ("Test 2 - \"fread\"ing\n");
    
    f = std::make_shared<std::ifstream>("test2.bin", std::ios::in | std::ios::binary);
    FILE *f2 = fopen("test2copy.bin", "rb");
    
    fr = std::make_unique<FileReader>(f);
    
    uint8_t *buf8 = (uint8_t *)calloc(sizeof(uint8_t), 60);
    uint8_t *buf28 = (uint8_t *)calloc(sizeof(uint8_t), 60);
    
    printf("Reading 8 bytes\n");
    fr->read_chunk(buf8, 8);
    fread(buf28, 1, 8, f2);
    int i;
    for (i = 0; i < 8; i++){
        printf("%d =? <%d>\n", buf8[i], buf28[i]);
        assert(buf8[i] == buf28[i]);
    }
    
    
    uint16_t *buf16 = (uint16_t *)calloc(sizeof(uint16_t), 60);
    uint16_t *buf216 = (uint16_t *)calloc(sizeof(uint16_t), 60);
    
    printf("Reading 16 uint16_t's\n");
    fr->read_chunk(buf16, 16);
    fread(buf216, 2, 16, f2);
    for (i = 0; i < 16; i++){
        printf("%d =? <%d>\n", buf16[i], buf216[i]);fflush(stdout);
        assert(buf16[i] == buf216[i]);
    }
    
    uint32_t *buf32 = (uint32_t *)calloc(sizeof(uint32_t), 60);
    uint32_t *buf232 = (uint32_t *)calloc(sizeof(uint32_t), 60);
    
    printf("Reading 8 uint32_t's\n");
    fr->read_chunk(buf32, 8);
    fread(buf232, 4, 8, f2);
    for (i = 0; i < 8; i++){
        printf("%d =? <%d>\n", buf32[i], buf232[i]);fflush(stdout);
        assert(buf32[i] == buf232[i]);
    }
    
    
    return 1;
    
}


