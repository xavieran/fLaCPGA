/* Return the number of bits that will be used encoding a particular value with rice_param */

#include "bitwriter.hpp"
#include "riceencoder.hpp"

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include <vector>
#include <algorithm>



std::vector<int> RiceEncoder::calc_best_rice_params(int32_t data[], int samples){
    // Test all 8 rice params
    auto prefixsums = std::vector<std::vector<int>>(8, std::vector<int>(samples));

    for (unsigned r = 0; r < prefixsums.size(); r++)
        prefixsums[r][0] = calc_rice_bits(data[0], r);
    
    for (int i = 1; i < samples; i++)
        for (unsigned r = 0; r < prefixsums.size(); r++)
            prefixsums[r][i] = prefixsums[r][i - 1] + calc_rice_bits(data[i], r);
    
    /* Now that we have calculated the prefix sums, find the best set of params to 
       minimize the final partition size*/
    
    int npartitions = 11; // samples/(1 << npartitions) = 1
    auto rice_params = std::vector<std::vector<int>>(npartitions, std::vector<int>(1 << npartitions - 1));
    auto bit_sums = std::vector<int>(8);
    auto part_size_sums = std::vector<int>(npartitions);
    
    for (int p = 0; p < npartitions; p++){ // For each partition size
        int samples_per_partition = samples / (1 << p);
        part_size_sums[p] = 4*(1 << p); // This is the overhead of parameter spec
        
        for (int i = 0; i < (1 << p); i++){
            for (int r = 0; r < 8; r++){
                bit_sums[r] = prefixsums[r][(i + 1) * samples_per_partition - 1] - 
                              prefixsums[r][i * samples_per_partition];
            }
            auto min_bits = std::distance(bit_sums.begin(), std::min_element(bit_sums.begin(), bit_sums.end()));
            rice_params[p][i] =  min_bits;
            part_size_sums[p] += bit_sums[min_bits];
        }
    }
    
    auto min_part_size = std::distance(part_size_sums.begin(), 
                                       std::min_element(part_size_sums.begin(), 
                                                        part_size_sums.end()));
    
    auto nv = std::vector<int>(1 << min_part_size);
    for (int i = 0; i < (1<<min_part_size); i++) nv[i] = rice_params[min_part_size][i];
   
    return nv;
    
}

unsigned RiceEncoder::calc_rice_bits(int32_t data, unsigned rice_param){
    uint32_t uval = data;
    uval <<= 1;
    uval ^= (data >> 31);

    return 1 + rice_param + (uval >> rice_param);
}