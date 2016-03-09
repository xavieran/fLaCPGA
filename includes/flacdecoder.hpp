/**********************************
 * FLACDecoder class               *
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

class FLACDecoder {
public:
    FLACDecoder(FILE *f);
    FLACMetaData *getMetaData();
    
    int read(int32_t ***pcm_buf);
    int read_meta();
    int read_frame(int32_t **data, uint64_t offset);
    
    void print_all_metadata();
    void print_meta();
    int print_frame();
    
private:
    FileReader *_fr;
    FLACMetaData *_meta;
    FLACFrameHeader *_frame;
    FLACSubFrameHeader *_subframe;
    
    FLACSubFrameConstant *_c;
    FLACSubFrameVerbatim *_v;
    FLACSubFrameFixed *_f;
    FLACSubFrameLPC *_l;
    
    
    void process_channels(int32_t **channels, uint64_t offset, \
                         uint32_t samples, FLAC_const chanType);
};