/**********************************
 * FLACDecoder class               *
 **********************************/

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <memory>
#include <vector>

#include "Constants.hpp"
#include "Frames.hpp"
#include "Metadata.hpp"
#include "SubFrames.hpp"

#include "BitReader.hpp"
#include "FLACDecoder.hpp"

FLACDecoder::FLACDecoder(std::shared_ptr<std::fstream> f)
    : _fr{BitReader{f}}
    , _meta{FLACMetaData{}}
    , _frame{FLACFrameHeader{}}
    , _subframe{FLACSubFrameHeader{}}
    , _c{FLACSubFrameConstant{}}
    , _v{FLACSubFrameVerbatim{}}
    , _f{FLACSubFrameFixed{}}
    , _l{FLACSubFrameLPC{}} {
}

FLACMetaData &FLACDecoder::getMetaData() {
    return _meta;
}

int FLACDecoder::read(int32_t ***pcm_buf) {
    read_meta();

    int numChannels = _meta.getStreamInfo()->getNumChannels();
    int intraSamples = _meta.getStreamInfo()->getTotalSamples();
    int totalInterSamples = intraSamples * numChannels;
    int samplesRead = 0;
    int samplesFrame = 0;

    (*pcm_buf) = (int32_t **)malloc(sizeof(int32_t *) * numChannels);

    for (int ch = 0; ch < numChannels; ch++)
        (*pcm_buf)[ch] = (int32_t *)malloc(sizeof(int32_t) * intraSamples);

    while (samplesRead < intraSamples) {
        samplesFrame = read_frame(*pcm_buf, samplesRead) / numChannels;
        samplesRead += samplesFrame;
    }

    fprintf(stderr, "Wanted: %d  -- diff : %d\n", totalInterSamples, totalInterSamples - samplesRead);

    return samplesRead; /* This will be the intrasample count */
}

int FLACDecoder::read_meta() {
    _meta.read(_fr);
    return 1;
}

int FLACDecoder::read_frame(int32_t **data, uint64_t offset) {
    /* Read frame into data. Data holds channels */
    _frame.reconstruct();
    _frame.read(_fr);
    // fprintf(stdout, "--FRAME HEADER\n");
    //_frame.print(stdout);

    int ch;
    int samplesRead = 0;

    FLAC_const chanType = _frame.getChannelType();
    uint16_t blockSize = _frame.getBlockSize();

    for (ch = 0; ch < _frame.getNumChannels(); ch++) {
        _subframe.reconstruct();
        _subframe.read(_fr);
        // fprintf(stderr, "----SUBFRAME HEADER\n");
        //_subframe.print(stderr);
        uint8_t bps = _frame.getSampleSize();

        switch (chanType) {
        case CH_MID:  // Mid side
        case CH_LEFT: // Left Side
            if (ch == 1)
                bps++;
            break;
        case CH_RIGHT: // Right side
            if (ch == 0)
                bps++;
            break;
        }

        switch (_subframe.getSubFrameType()) {
        case SUB_CONSTANT:
            _c.reconstruct(bps, blockSize);
            samplesRead += _c.read(_fr, data[ch] + offset);
            break;
        case SUB_VERBATIM:
            _v.reconstruct(bps, blockSize);
            samplesRead += _v.read(_fr, data[ch] + offset);
            break;
        case SUB_FIXED:
            _f.reconstruct(bps, blockSize, _subframe.getFixedOrder());
            samplesRead += _f.read(_fr, data[ch] + offset);
            break;
        case SUB_LPC:
            _l.reconstruct(bps, blockSize, _subframe.getLPCOrder());
            samplesRead += _l.read(_fr, data[ch] + offset);
            break;
        case SUB_INVALID:
            fprintf(stderr, "Invalid subframe type\n");
            _fr.read_error();
        }
        /*for (int i = 0; i <  blockSize; i++){
            printf("%d\n",data[i]);
        }*/
    }

    process_channels(data, offset, blockSize, chanType);

    _frame.read_padding(_fr);
    _frame.read_footer(_fr);

    return samplesRead;
}

void FLACDecoder::process_channels(int32_t **channels, uint64_t offset, uint32_t samples, FLAC_const chanType) {
    int32_t mid, side;
    switch (chanType) {
    case CH_MID:
        for (unsigned i = offset; i < samples + offset; i++) {
            mid = channels[0][i];
            side = channels[1][i];
            mid *= 2;
            mid |= (side & 1);
            channels[0][i] = (mid + side) / 2;
            channels[1][i] = (mid + side) / 2;
        }
        break;
    case CH_LEFT:
        for (unsigned i = offset; i < samples + offset; i++)
            channels[1][i] = channels[0][i] - channels[1][i];
        break;
    case CH_RIGHT:
        for (unsigned i = offset; i < samples + offset; i++)
            channels[0][i] += channels[1][i];
        break;
    }
}

void FLACDecoder::print_all_metadata() {
    print_meta();

    int numChannels = _meta.getStreamInfo()->getNumChannels();
    uint64_t intraSamples = _meta.getStreamInfo()->getTotalSamples();
    uint64_t totalInterSamples = intraSamples * numChannels;
    int samplesRead = 0;
    int samplesFrame = 0;

    while (samplesRead < intraSamples) {
        samplesFrame = print_frame() / numChannels;
        samplesRead += samplesFrame;
    }
}

void FLACDecoder::print_meta() {
    read_meta();
    _meta.getStreamInfo()->print(stdout);
    _meta.print(stdout);
}

int FLACDecoder::print_frame() {
    /* Read frame into data. Data holds channels */
    _frame.reconstruct();
    _frame.read(_fr);
    fprintf(stdout, "\t== FRAME HEADER ==\n");
    _frame.print(stdout);

    int ch;
    int samplesRead = 0;

    FLAC_const chanType = _frame.getChannelType();
    uint16_t blockSize = _frame.getBlockSize();

    for (ch = 0; ch < _frame.getNumChannels(); ch++) {
        _subframe.reconstruct();
        _subframe.read(_fr);
        fprintf(stdout, "\t-- SUBFRAME HEADER --\n");
        _subframe.print(stdout);
        uint8_t bps = _frame.getSampleSize();

        switch (chanType) {
        case CH_MID:  // Mid side
        case CH_LEFT: // Left Side
            if (ch == 1)
                bps++;
            break;
        case CH_RIGHT: // Right side
            if (ch == 0)
                bps++;
            break;
        }

        switch (_subframe.getSubFrameType()) {
        case SUB_CONSTANT:
            _c.reconstruct(bps, blockSize);
            samplesRead += _c.read(_fr);
            fprintf(stdout, "\t :: CONSTANT ::\n");
            _c.print(stdout);
            break;
        case SUB_VERBATIM:
            _v.reconstruct(bps, blockSize);
            samplesRead += _v.read(_fr);
            fprintf(stdout, "\t :: VERBATIM ::\n");
            _v.print(stdout);
            break;
        case SUB_FIXED:
            _f.reconstruct(bps, blockSize, _subframe.getFixedOrder());
            samplesRead += _f.read(_fr);
            fprintf(stdout, "\t :: FIXED ::\n");
            _f.print(stdout);
            break;
        case SUB_LPC:
            _l.reconstruct(bps, blockSize, _subframe.getLPCOrder());
            samplesRead += _l.read(_fr);
            fprintf(stdout, "\t :: LPC ::\n");
            _l.print(stdout);
            break;
        case SUB_INVALID:
            fprintf(stderr, "Invalid subframe type\n");
            _fr.read_error();
        }
    }

    _frame.read_padding(_fr);
    _frame.read_footer(_fr);

    return samplesRead;
}
