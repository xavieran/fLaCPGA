#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <assert.h>

#include <iostream>
#include <fstream>
#include <memory>
#include <algorithm>


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
        unsigned uval = value;
        uval <<= 1; // Shift signed value over by one
        uval ^= (value >> 31); // xor the unsigned value with the sign bit of data
    
        unsigned msbs = uval >> param;
        unsigned lsbs = uval & ((1 << param) - 1); // LSBs are the last rice_param number of bits
        std::cerr << value << " M: " << msbs << " L: " << lsbs << "\n";
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


class WriteRicePartition : public BitWriterTest {};

TEST_F(WriteRicePartition, SimplePartition){
    unsigned samples = 64;
    unsigned rice_param = 2;
    int32_t *data = (int32_t *)malloc(sizeof(int32_t)*samples);
    
    int i = 0;
    int d = 0;
    int dir = 0;
    int mag = 3;
    while (i < samples){
        if (d <= -mag) dir = 1;
        else if (d >= mag) dir = 0;
        
        if (dir) d++;
        else d--;
        
        data[i] = d;
        i++;
    }
    
    bw->write_rice_partition(data, samples, 0, 3);
    bw->flush();
    
    f->seekg(0);
    f->sync();
    br->refill_buffer();
    
    int32_t *read = (int32_t *)malloc(sizeof(int32_t)*samples);
    br->read_rice_partition(read, samples, 0);
    
    for (i = 0; i < samples; i++)
        EXPECT_EQ(data[i], read[i]);
    
}


class WriteResidual : public BitWriterTest {};

TEST_P(WriteResidual, Partitions){
    std::vector<int> * const& p = GetParam();
    int samples = 4096;
    unsigned part_order = p->at(0);
    int pred_order = 1;
    std::vector<uint8_t> rice_params;
    for (int i = 0; i < (1 << part_order); i++)
        rice_params.push_back(std::min(i, 7));
    
    int32_t *data = (int32_t *) malloc(sizeof(int32_t)*samples);
    
    int i = 0;
    int d = 0;
    int dir = 0;
    int mag = 3;
    while (i < samples){
        if (d <= -mag) dir = 1;
        else if (d >= mag) dir = 0;
        
        if (dir) d++;
        else d--;
        
        data[i] = d;
        if (i % 64 == 0) data[i] = 64; // Simulate the odd spike
        //std::cout << d << " ";
        i++;
    }
    //std::cout << "\n";
    
    bw->write_residual(data + pred_order, samples, pred_order, 0, part_order, rice_params);
    bw->flush();
    
    f->seekg(0);
    f->sync();
    br->refill_buffer();
    
    int32_t *read = (int32_t *)malloc(sizeof(int32_t)*samples);
    for (int i = 0; i < pred_order; i++)
        read[i] = data[i];
    
    br->read_residual(read + pred_order, samples, pred_order);
    
    for (i = 0; i < samples; i++)
    //    std::cout << i <<":"<< data[i] << "=?" << read[i] << "\n";
        EXPECT_EQ(data[i], read[i]);
    
}

INSTANTIATE_TEST_CASE_P(WritePartitionsData, WriteResidual, ::testing::Values(
    new std::vector<int>{0},
    new std::vector<int>{1},
    new std::vector<int>{2},
    new std::vector<int>{3},
    new std::vector<int>{4},
    new std::vector<int>{5}));

int main(int argc, char **argv){
    ::testing::InitGoogleTest( &argc, argv );
    return RUN_ALL_TESTS();
}
