#include "gtest/gtest.h"

#include "bitwriter.hpp"
#include "bitreader.hpp"
#include "flacencoder.hpp"
#include "frames.hpp"
#include "metadata.hpp"

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include <iostream>
#include <fstream>
#include <memory>




class BitReaderTestSeek: public ::testing::TestWithParam<std::vector<int> *> {
public: 
    std::shared_ptr<std::fstream> f;
    std::shared_ptr<BitReader> br;
    std::shared_ptr<BitWriter> bw;
    
    BitReaderTestSeek() { 
        f = std::make_shared<std::fstream>("encoding_test.bin", std::ios::in | std::ios::binary | std::ios::out | std::ios::trunc);
        br = std::make_shared<BitReader>(f);
        bw = std::make_shared<BitWriter>(f);
    } 

    ~BitReaderTestSeek(){
        f->close();
    }
};

class WriteSTREAMINFO : public BitReaderTestSeek {};

TEST_F(WriteSTREAMINFO, StreamInfoTest){
    auto msi = FLACMetaStreamInfo();
    msi.setTotalSamples(20101101011);
    msi.write(bw);
    
    bw->flush();
    
    f->seekg(0);
    f->sync();
    br->refill_buffer();
    int x;
    br->read_bits(&x, 32); // Read the fLaC bit
    auto msi_reader = FLACMetaStreamInfo();
    msi_reader.read(br);
    
    msi_reader.print(stdout);
}


class WriteFrameHeader : public BitReaderTestSeek {};

TEST_F(WriteFrameHeader, FrameHeaderTest){
    auto frame_h = FLACFrameHeader();
    
    frame_h.setFrameNumber((uint64_t) 1122334459);
    frame_h.write(bw);
    
    bw->flush();
    
    f->seekg(0);
    f->sync();
    br->refill_buffer();
    
    int x;
    auto frame_hv = FLACFrameHeader();
    frame_hv.read(br);
    
    frame_hv.print(stdout);
}




int main(int argc, char **argv){
    ::testing::InitGoogleTest( &argc, argv );
    return RUN_ALL_TESTS();
}


