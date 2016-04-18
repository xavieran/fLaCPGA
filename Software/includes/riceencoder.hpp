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
    RiceEncoder();
    static std::vector<int> calc_best_rice_params(int32_t data[], int samples);
    static unsigned calc_rice_bits(int32_t data, unsigned rice_param);
    
private:
};

#endif