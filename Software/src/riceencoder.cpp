/* Return the number of bits that will be used encoding a particular value with rice_param */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "bitwriter.hpp"
#include "riceencoder.hpp"

RiceEncoder(BitWriter *bw){
    _bw = bw;
}

#define NUM_BINS 10
int RiceEncoder::calc_best_rice_param(int32_t data[], unsigned max, int samples){
    /* Create histogram from the data
     * Based on the distribution of the data, select
     * a rice parameter */
    
    unsigned bins[NUM_BINS] = {0,0,0,0,0,0,0,0,0,0};
    
    // Round each data point to one of the ten bins up to max
    
    unsigned bin_size = max/NUM_BINS;
    
    for (int i = 0; i < samples; i++)
        bins[ data[i] / bin_size - 1]++;
    
    // We now have histogram, find best rice parameter
    
    
}

unsigned RiceEncoder::number_rice_bits(int32_t data, unsigned rice_param){
    uint32_t uval = data;
    uval <<= 1;
    uval ^= (data >> 31);

    return 1 + rice_param + (uval >> rice_param);
}

int RiceEncoder::write_rice_partition(int32_t data[], int samples, unsigned rice_param){
    if (rice_param <= 15)
        _bw->write_bits(rice_param, 4);
    else
        _bw->write_bits(rice_param, 5);
    
    for (int i = 0; i < samples; i++)
        _bw->write_rice(data[i], rice_param);
    
    return 1;
}


int RiceEncoder::write_residual(int32_t data[], int blk_size, int pred_order){
    uint8_t partition_order = 0;
    uint64_t nsamples = 0;
    
    for (i = 0; i < (1 << partition_order); i++){
        if (partition_order == 0)
            nsamples = blk_size - pred_order;
        else if (i != 0)
            nsamples = blk_size / (1 < partition_order);
        else
            nsamples = blk_size / (1 << partition_order) - pred_order;
        
        _bw->write_rice_partition(data, nsamples, rice_param);
    }
    
    return 1;
}