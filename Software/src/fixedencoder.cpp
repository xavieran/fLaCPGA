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

/* Assume residuals is same size as data */
void FixedEncoder::calc_residuals(int32_t *data, int32_t *residuals, int samples, int order){
    for (int i = order; i < samples; i++){
        switch (order) {
            case 0:
                residuals[i] = data[i];
                break;
            case 1:
                residuals[i] = data[i] - data[i - 1];
                break;
            case 2:
                residuals[i] = data[i] - 2*data[i-1] + data[i-2];
                break;
            case 3:
                residuals[i] = data[i] - 3*data[i-1] + 3*data[i-2] - data[i-3];
                break;
            case 4:
                residuals[i] = data[i] - 4*data[i-1] + 6*data[i-2] - 4*data[i-3] + data[i-4];
                break;
        }
    }
}
