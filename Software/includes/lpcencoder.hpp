/**********************************
 * RiceEncoder class               *
 **********************************/

#ifndef LPC_ENCODER_H
#define LPC_ENCODER_H

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <memory>
#include <vector>

#include "constants.hpp"

class LPCEncoder {
public:
  static void calc_autocorrelation(int32_t samples[], int nsamples, int order,
                                   double autoc[]);
  static void calculate_lpc_coeffs(double autoc[], int order,
                                   double lpc_coeff[]);
  static void quantize_coefficients(double lpc_coeff[], int16_t qlp_coeff[],
                                    int16_t shift);
};

#endif
