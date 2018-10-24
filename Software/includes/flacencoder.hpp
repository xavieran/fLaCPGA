/**********************************
 * FLACEncoder class               *
 **********************************/

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <memory>
#include <vector>

#include "constants.hpp"
#include "frames.hpp"
#include "metadata.hpp"
#include "subframes.hpp"

#include "bitreader.hpp"
#include "bitwriter.hpp"

class FLACEncoder {
   public:
    FLACEncoder(std::shared_ptr<std::fstream> f);

    bool write_header();  // No args for now.
    bool write_frame(int32_t *pcm_buf, int samples, uint32_t frame);

    bool write_frame_verbatim(int32_t *pcm_buf, int samples, uint32_t frame);
    bool write_frame_fixed(int32_t *pcm_buf, int samples, int order,
                           uint32_t frame);

    void setSamples(uint64_t samples);
    /*int read(int32_t ***pcm_buf);
    int read_meta();
    int read_frame(int32_t **data, uint64_t offset);
    */

   private:
    BitWriter _bw;
    uint64_t _samples;
};
