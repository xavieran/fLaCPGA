/**********************************
 * FLACDecoder class               *
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

class FLACDecoder {
  public:
    FLACDecoder(std::shared_ptr<std::fstream> f);
    FLACMetaData &getMetaData();

    int read(int32_t ***pcm_buf);
    int read_meta();
    int read_frame(int32_t **data, uint64_t offset);

    void print_all_metadata();
    void print_meta();
    int print_frame();

  private:
    BitReader _fr;
    FLACMetaData _meta;
    FLACFrameHeader _frame;
    FLACSubFrameHeader _subframe;

    FLACSubFrameConstant _c;
    FLACSubFrameVerbatim _v;
    FLACSubFrameFixed _f;
    FLACSubFrameLPC _l;

    void process_channels(int32_t **channels, uint64_t offset, uint32_t samples, FLAC_const chanType);
};
