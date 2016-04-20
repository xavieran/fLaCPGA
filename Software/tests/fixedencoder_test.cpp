#include "bitwriter.hpp"
#include "fixedencoder.hpp"



#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include <vector>
#include <algorithm>

#include "gtest/gtest.h"
/* fixedencoder_test.cpp */

TEST(FixedEncoder, TestAgainstFLAC){
    auto finp = std::make_shared<std::ifstream>("wu.pcm", std::ios::in);
    auto fino = std::make_shared<std::ifstream>("wu.orders", std::ios::in);
    
    int samples = 4096*44;
    
    int32_t data[samples];
    int16_t p;
    int i = 0;
    while (*finp >> p && i < samples) data[i++] = p;
    finp->close();
    
    int32_t flac_orders[44];
    i = 0;
    while (*fino >> p && i < 44) flac_orders[i++] = p;
    fino->close();
    
    for (int i = 0; i < 44; i++)
        EXPECT_EQ(flac_orders[i], FixedEncoder::calc_best_order(data + 4096*i, 4096));

}
int main(int argc, char **argv){
    ::testing::InitGoogleTest( &argc, argv );
    return RUN_ALL_TESTS();
}