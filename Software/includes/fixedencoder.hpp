/**********************************
 * RiceEncoder class               *
 **********************************/

#ifndef FIXED_ENCODER_H
#define FIXED_ENCODER_H

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <vector>
#include <memory>

#include "constants.hpp"

#include "bitwriter.hpp"

class FixedEncoder {
public:
    FixedEncoder();
    static int calc_best_order(int32_t data[], int samples);
    static unsigned calc_residuals(int32_t *data, int samples);
    
private:
};

#endif