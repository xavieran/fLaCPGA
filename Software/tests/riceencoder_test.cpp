#include "bitwriter.hpp"
#include "bitreader.hpp"

#include "riceencoder.hpp"

#include "gtest/gtest.h"

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <assert.h>

#include <iostream>
#include <ios>
#include <fstream>
#include <memory>

TEST(BestParameterLowResiduals, RiceEncTest){
    std::shared_ptr<std::ifstream> f = std::make_shared<std::ifstream>("test_residual", std::ios::in);
    int32_t data[4096];
    int16_t p;
    int i = 0;
    while (*f >> p){
        data[i++] = p;
    }
    auto best_param = RiceEncoder::calc_best_rice_params(data, 4096);
        for (auto r: best_param){
        std::cerr << " " << r;
    }
    std::cerr << "\n";
}

int main(int argc, char **argv){
    ::testing::InitGoogleTest( &argc, argv );
    return RUN_ALL_TESTS();
}