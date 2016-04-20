/* Return the number of bits that will be used encoding a particular value with rice_param */

#include "bitwriter.hpp"
#include "fixedencoder.hpp"

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include <vector>
#include <algorithm>


int FixedEncoder::calc_best_order(int32_t data[], int samples){
    auto sum_errors = std::vector<long long int>{0,0,0,0,0};
    
    for (int i = 0; i < samples; i++){
        sum_errors[0] += abs(data[i]);
        if (i > 0) sum_errors[1] += abs(data[i] - data[i - 1]);
        if (i > 1) sum_errors[2] += abs(data[i] - 2*data[i-1] + data[i-2]);
        if (i > 2) sum_errors[3] += abs(data[i] - 3*data[i-1] + 3*data[i-2] - data[i-3]);
        if (i > 3) sum_errors[4] += abs(data[i] - 4*data[i-1] + 6*data[i-2] - 4*data[i-3] + data[i-4]);
    }
    
    return std::distance(sum_errors.begin(), std::min_element(sum_errors.begin(), sum_errors.end()));
}

unsigned FixedEncoder::calc_residuals(int32_t *data, int samples){
    return 0;
}
/*
 * 
 * 1,2,3,4,5,4,3,2,1,2,3,4,5
 * 
 * order 1:
 * 1,1,1,1,1,-1,-1,-1,1,1,1
 * 
 */

/*
FLACSubFrameFixed::compute_best_order(int32_t *data, uint64_t samples){
    int max_orders = 4;
    auto total_errors = std::vector<int>(max_order + 1);
    auto predicted = std::vector<int>(max_order + 1);
    
    for (int i = 0; i < samples){
        for (int ord = 0; ord < 5; ord++){
            switch (ord){
                case 0:
                    predicted[ord] = data[i];
                    total_errors[ord] += predicted[ord] - data[i];
                    break;
                case 1:
                    predicted[ord] = data[i] - data[i - 1];
            }
        }
    }
}*/
/*
void FLAC__fixed_compute_residual(const FLAC__int32 data[], unsigned data_len, unsigned order, FLAC__int32 residual[])
{
    const int idata_len = (int)data_len;
    int i;

    switch(order) {
        case 0:
            FLAC__ASSERT(sizeof(residual[0]) == sizeof(data[0]));
            memcpy(residual, data, sizeof(residual[0])*data_len);
            break;
        case 1:
            for(i = 0; i < idata_len; i++)
                residual[i] = data[i] - data[i-1];
            break;
        case 2:
            for(i = 0; i < idata_len; i++)
                residual[i] = data[i] - 2*data[i-1] + data[i-2];
            break;
        case 3:
            for(i = 0; i < idata_len; i++)
                residual[i] = data[i] - 3*data[i-1] + 3*data[i-2] - data[i-3];
            break;
        case 4:
            for(i = 0; i < idata_len; i++)
                residual[i] = data[i] - 4*data[i-1] + 6*data[i-2] - 4*data[i-3] + data[i-4];
            break;
        default:
            FLAC__ASSERT(0);
    }
}*/