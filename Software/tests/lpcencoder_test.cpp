#include "bitwriter.hpp"
#include "lpcencoder.hpp"

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include <vector>
#include <algorithm>

#include "gtest/gtest.h"

TEST(LPC_Encoder, TestAutocorrelation){
    auto finp = std::make_shared<std::ifstream>("Pavane16Blocks.pcm", std::ios::in);
    
    int samples = 4096;
    int order = 12;
    
    int32_t data[samples];
    int16_t p;
    int i = 0;
    while (*finp >> p && i < samples) data[i++] = (int32_t) p;
    finp->close();
    
    double autoc[order];
    for (int i = 0; i < order; i++) autoc[i] = 0;
    
    LPCEncoder::calc_autocorrelation(data, samples, order, autoc);
    
    for (int i = 0; i <= order; i++) std::cout << i << ": " << autoc[i] << "\n";

}


TEST(LPC_Encoder, TestLPC_Calc){
    auto finp = std::make_shared<std::ifstream>("Pavane16Blocks.pcm", std::ios::in);
    
    int samples = 4096;
    int order = 12;
    
    int32_t data[samples];
    int16_t p;
    int i = 0;
    while (*finp >> p && i < samples) data[i++] = (int32_t) p;
    finp->close();
    
    double autoc[order];
    double lpc_coeff[order];
    for (int i = 0; i < order; i++) {autoc[i] = 0;lpc_coeff[i] = 0;}
    
    LPCEncoder::calc_autocorrelation(data, samples, order, autoc);
    LPCEncoder::calculate_lpc_coeffs(autoc, 4, lpc_coeff);
    
    for (int i = 0; i <= order; i++) std::cout << i << ": " << lpc_coeff[i] << "\n";
    
    

}
int main(int argc, char **argv){
    ::testing::InitGoogleTest( &argc, argv );
    return RUN_ALL_TESTS();
}