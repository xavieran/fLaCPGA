/*********************************
 *****   lpcencoder.         *****
 *********************************/

#include "lpcencoder.hpp"

#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <algorithm>
#include <iostream>
#include <vector>

void LPCEncoder::calc_autocorrelation(int32_t samples[], int nsamples,
                                      int order, double autoc[]) {
    double d;
    unsigned i;

    /* Autocorrelation is defined as:
     *
     *
     * Since audio signals tend to have a mean of 0, we don't need to subtract
     * the mean from the data.
     */

    for (int i = 0; i < nsamples - order; i++) {
        for (int j = 0; j < order; j++) {
            autoc[j] += samples[i] * samples[i + j];
        }
    }

    double autoc0 = autoc[0];

    for (int i = 0; i < order; i++) {
        autoc[i] = autoc[i] / autoc0;
    }
}

void LPCEncoder::calculate_lpc_coeffs(double autoc[], int order,
                                      double lpc_coeff[]) {
    double error = autoc[0];
    double alpha = autoc[1];
    double k = 0;

    lpc_coeff[0] = 1.0;

    for (int i = 0; i < order; i++) {
        k = -alpha / error;
        /* Note that we can do "two at once" and thus do in place calculation */
        for (int j = 0; j <= (i + 1) / 2; j++) {
            double temp = lpc_coeff[j] + k * lpc_coeff[i + 1 - j];
            lpc_coeff[i + 1 - j] = lpc_coeff[i + 1 - j] + k * lpc_coeff[i];
            lpc_coeff[j] = temp;
        }

        error = error - k * k * error;

        alpha = 0;
        for (int j = 0; j < i; j++) {
            alpha = alpha + lpc_coeff[j] * autoc[i - j + 1];
        }
    }
}

// void LPCEncoder::quantize_coefficients(double lpc_coeff[], int16_t
// qlp_coeff[], int16_t shift);