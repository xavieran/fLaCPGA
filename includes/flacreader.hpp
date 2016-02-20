/**********************************
 * FlacReader class               *
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

class FLACReader {
public:
    FLACReader(FILE *f);
    int read(int32_t **pcm_buf);
    
    
private:
    FileReader *_fr;
    FLACMetaData *_meta;
    FLACFrameHeader *_frame;
    FLACSubFrameHeader *_subframe;
    
    FLACSubFrameConstant *_c;
    FLACSubFrameVerbatim *_v;
    FLACSubFrameFixed *_f;
    FLACSubFrameLPC *_l;
    
    int read_frame(int32_t *data);
    int read_meta();
    
    
};