#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <assert.h>

#include <iostream>
#include <fstream>
#include <memory>


#include "bitwriter.hpp"
#include "bitreader.hpp"



#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <assert.h>

#include <iostream>
#include <ios>
#include <fstream>
#include <memory>

#include "gtest/gtest.h"

#include "bitreader.hpp"

/* Test File Contents */
/* test1.bin
 * 9    6    8    C    B    0    0    A
 * 1001 0110 1000 1100 1011 0000 0000 1010 
 *         | ||    |        |*/

class BitWriterTest: public ::testing::TestWithParam<std::vector<int> *> {
public: 
    std::shared_ptr<std::fstream> f;
    std::unique_ptr<BitReader> br;
    std::unique_ptr<BitWriter> bw;
    
    BitWriterTest() { 
        f = std::make_shared<std::fstream>("wtest.bin", std::ios::out | std::ios::in | std::ios::binary | std::ios::trunc);
        if (!f->is_open()){
            std::cerr << "Failed to open wtest.bin for writing\n";
            std::cerr << "Fail: " << f->fail() << " Bad: " << f->bad() << " EOF: " << f->eof() << "\n";
            std::cerr << strerror(errno) << "\n";
            exit(1);
        }
        br = std::make_unique<BitReader>(f);
        bw = std::make_unique<BitWriter>(f);
    } 

    ~BitWriterTest(){
        f->close();
    }
};

/***************************************************
 * Test Bit Writing ********************************
 ***************************************************/

class WriteBits: public BitWriterTest {};

TEST_P(WriteBits, WriteBitsFunction){
    std::vector<int> * const& p = GetParam();
    uint8_t nbits = p->at(1);
    int32_t data = p->at(0);
    bw->write_bits(data, nbits);
    bw->flush();
    std::cerr << "Wrote " << (int) nbits << " bits. Data: [" << data << "] =? [";
    f->seekg(0);
    f->sync();
    br->refill_buffer();
    br->read_bits(&data, nbits);
    std::cerr << data << "]\n";
    EXPECT_EQ(p->at(0), data);
}

INSTANTIATE_TEST_CASE_P(WriteBitsData, WriteBits, ::testing::Values(
    new std::vector<int>{0b11011, 5},
    new std::vector<int>{0b101000001110101, 15},
    new std::vector<int>{102543, 32},
    new std::vector<int>{5002212, 25}));


/***************************************************
 * Test Unary Writing ******************************
 ***************************************************/

class WriteUnary: public BitWriterTest {};

TEST_P(WriteUnary, WriteUnaryFunction){
    std::vector<int> * const& p = GetParam();
    int32_t param = p->at(0);
    std::cerr << "Rice coding, param="<<param << " : ";
    for(auto const& value: (*p)){
        std::cerr << value << " ";
        bw->write_rice(value, param);
    }
    std::cerr << "\n";
    
    bw->flush();
    f->seekg(0);
    f->sync();
    br->refill_buffer();
    
    int32_t rice;
    std::cerr << "Rice decoding: ";
    for (auto const& value: (*p)){
        br->read_rice_signed(&rice, param);
        std::cerr << rice <<" ";
        EXPECT_EQ(value, rice);
    }
    std::cerr << "\n";
}

INSTANTIATE_TEST_CASE_P(WriteUnaryData, WriteUnary, ::testing::Values(
    new std::vector<int>{0, 1,3,-2,4,7,21,-2,-1,-8,30,50,-102},
    new std::vector<int>{1, 1,3,-2,4,7,21,-2,-1,-8,30,50,-102},
    new std::vector<int>{2, 1,3,-2,4,7,21,-2,-1,-8,30,50,-102},
    new std::vector<int>{3, 1,3,-2,4,7,21,-2,-1,-8,30,50,-102},
    new std::vector<int>{4, 1,3,-2,4,7,21,-2,-1,-8,30,50,-102},
    new std::vector<int>{5, 1,3,-2,4,7,21,-2,-1,-8,30,50,-102}));


int main(int argc, char **argv){
    ::testing::InitGoogleTest( &argc, argv );
    return RUN_ALL_TESTS();
}


/*

int main(int argc, char **argv){
    
    
    printf("Test 1 - Bit writing\n");
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
    std::unique_ptr<BitReader> fr = std::make_unique<BitReader>(fin);
    
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

*/
