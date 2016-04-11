/* Return the number of bits that will be used encoding a particular value with rice_param */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include <vector>
#include <algorithms>

#include "bitwriter.hpp"
#include "riceencoder.hpp"

RiceEncoder(BitWriter *bw){
    _bw = bw;
}

int RiceEncoder:encode_residual(int32_t data[], int samples){
    //for each partition do this... choose the set of partitions that mins bits...
    int rice_param = calc_best_rice_param(data, samples);
    
    
}

int RiceEncoder::calc_best_rice_param(int32_t data[], int samples){
    // Test all 8 rice params
    std::vector<int> params = new std::vector<int>{0,0,0,0,0,0,0,0};
    for (int i = 0; i < samples; i++)
        for (r = 0; r < params.size(); r++)
            params[r] += number_rice_bits(data[i], r);
    
    return  std::min_element(params.begin(), params.end());
}

unsigned RiceEncoder::number_rice_bits(int32_t data, unsigned rice_param){
    uint32_t uval = data;
    uval <<= 1;
    uval ^= (data >> 31);

    return 1 + rice_param + (uval >> rice_param);
}