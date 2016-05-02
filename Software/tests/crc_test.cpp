
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

class BitReaderTestSeek: public ::testing::TestWithParam<std::vector<int> *> {
public: 
    std::shared_ptr<std::fstream> f;
    std::unique_ptr<BitReader> fr;
    
    BitReaderTestSeek() { 
        f = std::make_shared<std::fstream>("crc_test.bin", std::ios::in | std::ios::binary);
        fr = std::make_unique<BitReader>(f);
    } 

    ~BitReaderTestSeek(){
        f->close();
    }
};



int main(int argc, char **argv){
    ::testing::InitGoogleTest( &argc, argv );
    return RUN_ALL_TESTS();
}


