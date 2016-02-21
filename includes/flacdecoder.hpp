/**********************************
 * FLACDecoder class               *
 **********************************/

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <vector>

#include "frames.hpp"
#include "subframes.hpp"
#include "metadata.hpp"
#include "constants.hpp"

#include "bitreader.hpp"

class FLACDecoder {
public:
    FLACDecoder(FILE *f);
    int read(int32_t ***pcm_buf);
    FLACMetaData *getMetaData();
    
private:
    FileReader *_fr;
    FLACMetaData *_meta;
    FLACFrameHeader *_frame;
    FLACSubFrameHeader *_subframe;
    
    FLACSubFrameConstant *_c;
    FLACSubFrameVerbatim *_v;
    FLACSubFrameFixed *_f;
    FLACSubFrameLPC *_l;
    
    int read_frame(int32_t **data, uint64_t offset);
    int read_meta();
    
    void process_channels(int32_t **channels, uint64_t offset, \
                         uint32_t samples, FLAC_const chanType);
};