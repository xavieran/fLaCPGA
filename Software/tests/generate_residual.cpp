#include "bitwriter.hpp"
#include "bitreader.hpp"

#include "riceencoder.hpp"

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <assert.h>

#include <iostream>
#include <ios>
#include <fstream>
#include <memory>


int log2(int x){
    int l;
    for (l = 0; x > 0; l++)
        x >>= 1;
    return l;
}

int main(int argc, char **argv){
    auto fin = std::make_shared<std::ifstream>("test_residual", std::ios::in);
    auto fout = std::make_shared<std::fstream>("residual.bin", std::ios::out | std::ios::binary | std::ios::trunc);
    auto bw = std::make_unique<BitWriter>(fout);
    
    int samples = 4096;
    
    int32_t data[samples];
    int16_t p;
    int i = 0;
    while (*fin >> p)  data[i++] = p;
    fin->close();
    
    
    auto rice_params = RiceEncoder::calc_best_rice_params(data, 4096);
        for (auto r: rice_params){
        std::cerr << " " << (int) r;
    }
    std::cerr << "\n";
    std::cerr << "Part Order: " << log2(rice_params.size()) <<std::endl;
    int pred_order = 0;
    
    
    bw->write_residual(data + pred_order, samples, pred_order, 0, rice_params);
    bw->flush();
    fout->close();
    
    return 1;
    
    /*
    auto fin = std::make_shared<std::fstream>("residual.bin", std::ios::in);
    int samples = 4096;
    int32_t read[samples];
    int pred_order = 0;
    auto br = std::make_shared<BitReader>(fin);
    
    br->read_residual(read + pred_order, samples, pred_order);
    
    for (int i = 0; i < samples; i++){
        std::cerr << read[i] << "\n";
    }
    std::cerr << std::endl;*/
}