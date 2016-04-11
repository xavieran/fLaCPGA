/**********************************
 * RiceEncoder class               *
 **********************************/

#ifndef RICE_ENCODER_H
#define RICE_ENCODER_H

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <vector>
#include <memory>

#include "constants.hpp"

#include "bitwriter.hpp"

class RiceEncoder {
public:
    RiceEncoder(BitWriter *bw);
    int encode_residual(int32_t data[], int samples);
    int calc_best_rice_param(int32_t data[], int samples);
    int number_rice_bits(int32_t data, unsigned rice_param);
    
private:
    BitWriter *_bw;
};

#endif