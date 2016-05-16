/**********************************
 * FLACEncoder class               *
 **********************************/

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <vector>
#include <memory>

#include "frames.hpp"
#include "subframes.hpp"
#include "metadata.hpp"
#include "constants.hpp"

#include "bitreader.hpp"
#include "bitwriter.hpp"

class FLACEncoder {
public:
    FLACEncoder(std::shared_ptr<std::fstream> f);
    
    bool write_header(); // No args for now.
    bool write_frame(int32_t *pcm_buf, int samples, uint32_t frame);
    
    bool write_frame_verbatim(int32_t *pcm_buf, int samples, uint32_t frame);
    bool write_frame_fixed(int32_t *pcm_buf, int samples, int order, uint32_t frame);
    
    void setSamples(uint64_t samples);
    /*int read(int32_t ***pcm_buf);
    int read_meta();
    int read_frame(int32_t **data, uint64_t offset);
    */
    
private:
    std::shared_ptr<BitWriter> _bw;
    uint64_t _samples;
    
};