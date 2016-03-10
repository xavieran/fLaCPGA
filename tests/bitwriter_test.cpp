#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include <iostream>
#include <fstream>
#include <memory>


#include "bitwriter.hpp"
#include "bitreader.hpp"

int main(int argc, char **argv){
    
    
    /* Test 1 - bit reading */
    printf("Test 1 - Bit writing\n");
    /* 96 8C B0 0A */
    std::shared_ptr<std::ofstream> f = std::make_shared<std::ofstream>("wtest1.bin", std::ios::out | std::ios::binary);
    std::unique_ptr<BitWriter> bw = std::make_unique<BitWriter>(f);
    
    int test_failed = 0;
    int assertion = 0;
    uint32_t x = 0b1001;
    printf("Writing 4: %x\n", x);
    bw->write_bits(x, 4);
    
    x = 0b01101000;
    bw->write_bits(x, 8);
    printf("Writing 8: %x\n", x);
    
    x = 0b110;
    bw->write_bits(x, 3);
    printf("Writing 3: %x\n", x);
    
    x = 0b01011000000001010;
    bw->write_bits(x, 17);
    printf("Writing 17: %x\n", x);
    
    int32_t rices[9] = {0, -3,1,1042, 1021, -24, -205, 103, 10023};
    
    for (int i = 0; i < 8; i++){
        printf("Writing rice: %d\n", rices[i]);
        bw->write_rice(rices[i], 4);
    }
    
    bw->flush();
    
    f->close();
    
    std::shared_ptr<std::ifstream> fin = std::make_shared<std::ifstream>("wtest1.bin", std::ios::in | std::ios::binary);
    std::unique_ptr<BitReader> fr = std::make_unique<FileReader>(fin);
    
    fr->read_bits(&x, 4);
    printf("Read 4: %x\n", x);
    fr->read_bits(&x, 8);
    printf("Read 8: %x\n", x);
    fr->read_bits(&x, 3);
    printf("Read 3: %x\n", x);
    fr->read_bits(&x, 17);
    printf("Read 17: %x\n", x);
    
    int32_t r;
    for (int i = 0; i < 8; i++){
        fr->read_rice_signed(&r, 4);
        printf("Read rice: %d\n", r);
    }
    
    return 1;
}


