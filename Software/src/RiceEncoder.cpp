/* Return the number of bits that will be used encoding a particular value with
 * rice_param */

#include "RiceEncoder.hpp"
#include "BitWriter.hpp"

#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <algorithm>
#include <vector>

std::vector<uint8_t> RiceEncoder::calc_best_rice_params(int32_t data[], int samples, uint32_t &total_bits) {
    // Test all 8 rice params
    auto prefixsums = std::vector<std::vector<int>>(8, std::vector<int>(samples));

    for (unsigned r = 0; r < prefixsums.size(); r++)
        prefixsums[r][0] = calc_rice_bits(data[0], r);

    for (int i = 1; i < samples; i++)
        for (unsigned r = 0; r < prefixsums.size(); r++)
            prefixsums[r][i] = prefixsums[r][i - 1] + calc_rice_bits(data[i], r);

    /* Now that we have calculated the prefix sums, find the best set of params
       to
       minimize the final partition size*/

    int npartitions = 10; // npartitions should be log2(samples)... but since
                          // we deal with blocks of size 4096...

    auto rice_params = std::vector<std::vector<int>>(npartitions, std::vector<int>(1 << npartitions - 1));
    auto bit_sums = std::vector<int>(8);
    auto part_size_sums = std::vector<int>(npartitions);

    for (int p = 0; p < npartitions; p++) { // For each partition size
        // spp = samples_per_partition
        int spp = samples / (1 << p);
        part_size_sums[p] = 4 * (1 << p); // This is the overhead of parameter spec

        for (int i = 0; i < (1 << p); i++) {
            for (int r = 0; r < 8; r++)
                bit_sums[r] = prefixsums[r][(i + 1) * spp - 1] - prefixsums[r][i * spp];

            auto min_bits = std::distance(bit_sums.begin(), std::min_element(bit_sums.begin(), bit_sums.end()));
            rice_params[p][i] = min_bits;
            part_size_sums[p] += bit_sums[min_bits];
        }
    }

    auto min_part_size =
        std::distance(part_size_sums.begin(), std::min_element(part_size_sums.begin(), part_size_sums.end()));

    auto nv = std::vector<uint8_t>(1 << min_part_size);
    for (int i = 0; i < (1 << min_part_size); i++)
        nv[i] = rice_params[min_part_size][i];

    total_bits = *std::min(part_size_sums.begin(), part_size_sums.end());

    // fprintf(stderr, "Residual Total Bits: %d\n",
    // *std::min(part_size_sums.begin(), part_size_sums.end()));

    return nv;
}

// unsigned RiceEncoder::calc_total_bits(int32_t data[], std::vector<uint8_t>
// &rice_params){}

unsigned RiceEncoder::calc_rice_bits(int32_t data, unsigned rice_param) {
    uint32_t uval = data;
    uval <<= 1;
    uval ^= (data >> 31);

    return 1 + rice_param + (uval >> rice_param);
}
