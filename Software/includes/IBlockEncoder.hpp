/****************************
 * IBlockEncoder interface  *
 ****************************/

#pragma once

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <memory>
#include <vector>

class IBlockEncoder {
  public:
    static int calc_best_order(int32_t data[], int samples);
    static void calc_residuals(int32_t *data, int32_t *residuals, int samples, int order);
};

