/**********************************
 * FLACEncoder class               *
 **********************************/

#include "Constants.hpp"
#include "Frames.hpp"
#include "Metadata.hpp"
#include "SubFrames.hpp"

#include "BitWriter.hpp"
#include "FixedEncoder.hpp"
#include "FLACEncoder.hpp"
#include "RiceEncoder.hpp"

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <memory>
#include <vector>
#include <sstream>
#include <iterator>

#define LOGURU_WITH_STREAMS 1
#include <loguru.hpp>

FLACEncoder::FLACEncoder(std::shared_ptr<std::fstream> f)
    : _bw{BitWriter{f}} {
}

bool FLACEncoder::write_header() {
    auto msi = FLACMetaStreamInfo();
    msi.setTotalSamples(_samples);
    msi.write(_bw);

    return true;
}

bool FLACEncoder::write_frame(int32_t *pcm_buf, int samples, uint32_t frame) {
    LOG_SCOPE_FUNCTION(1);
    /* Step 1. Write the frame header */
    auto frame_header = FLACFrameHeader();
    frame_header.setFrameNumber(frame);
    frame_header.write(_bw);
    /* Step 2. Find the best order for this frame */
    int order = FixedEncoder::calc_best_order(pcm_buf, samples);
    LOG_F(1, "Frame: %d, Best order: %d", frame, order);

    /* Step 5. Now we calculate the residuals */
    int32_t scratch_space[samples];
    memset(scratch_space, 0, samples);
    FixedEncoder::calc_residuals(pcm_buf, scratch_space, samples, order);

    /* Step 7. Calculate the best residual parameters */

    uint32_t total_bits;
    auto rice_params = RiceEncoder::calc_best_rice_params(scratch_space + order, samples - order, total_bits);

    std::stringstream ss;
    for (auto r : rice_params) ss << static_cast<int>(r) << " ";
    LOG_F(2, "Rice Parameters: %s", ss.str().c_str());

    /* Step 3. Now we write the Subframe header */

    if (total_bits < 4096 * 16) {
        /* Subframe header*/
        _bw.write_bits(0b0001 << 4 | static_cast<uint8_t>(order) << 1, 8);

        /* Step 4. Write the warmup samples */
        for (int i = 0; i < order; i++) {
            _bw.write_bits(static_cast<int16_t>(pcm_buf[i]), 16);
        }

        /* Step 8. Write the residuals to file */
        int samples_in_res = _bw.write_residual(scratch_space + order, samples, order, 0, rice_params);
        /*
        std::cerr << "Samples wrote in residual: " << samples_in_res << "\n";

        std::cerr << "SAMPLES:::\n";
        for (int i = 0; i < samples; i++){
            std::cerr << pcm_buf[i] <<" " ;
        } std::cerr << "\n";

        std::cerr << "RESIDUALS:::\n";
        for (int i = 0; i < samples; i++){
            std::cerr << scratch_space[i] << " ";
        }
        std::cerr << "\n";*/
    } else {
        // Write Verbatim frame
        _bw.write_bits(0b00000010, 8);

        for (int i = 0; i < samples; i++)
            _bw.write_bits(pcm_buf[i], 16);
    }

    /* Step 9. Write the padding */
    _bw.write_padding();

    /* Step 10. Finally, write the frame footer and we are done */
    uint16_t crc16 = _bw.calc_crc16();
    _bw.write_bits(crc16, 16);
    // fprintf(stderr, "CRC16:: %x\n", crc16);

    if (frame % 64 == 0 && frame != 0)
        int bytes_written = _bw.flush();

    /* Should keep the buffer from overfilling... */
    // std::cerr << "Wrote " << bytes_written << "\n";
    // std::cerr << "Compared to " << 4096*2 << "\n\n";

    return true;
}

bool FLACEncoder::write_frame_verbatim(int32_t *pcm_buf, int samples, uint32_t frame) {
    /* Step 1. Write the frame header */
    auto frame_header = FLACFrameHeader();
    frame_header.setFrameNumber(frame);
    frame_header.write(_bw);

    std::cout << "Encoding Subframe Verbatim\n";
    // Write Verbatim frame
    _bw.write_bits(0b00000010, 8);

    for (int i = 0; i < samples; i++)
        _bw.write_bits(pcm_buf[i], 16);

    /* Step 9. Write the padding */
    _bw.write_padding();

    /* Step 10. Finally, write the frame footer and we are done */
    /*uint16_t crc16 = _bw.calc_crc16();
    _bw.write_bits(crc16, 16);*/

    _bw.flush();

    return true;
}

bool FLACEncoder::write_frame_fixed(int32_t *pcm_buf, int samples, int order, uint32_t frame) {
    /* Step 1. Write the frame header */
    auto frame_header = FLACFrameHeader();
    frame_header.setFrameNumber(frame);
    frame_header.write(_bw);

    std::cout << "Encoding Subframe Fixed of order: " << order << "\n";
    /* Step 5. Now we calculate the residuals from the fixed model */
    int32_t scratch_space[samples];
    memset(scratch_space, 0, samples);
    FixedEncoder::calc_residuals(pcm_buf, scratch_space, samples, order);

    /* Step 7. Calculate the best residual parameters */
    uint32_t total_bits;
    auto rice_params = RiceEncoder::calc_best_rice_params(scratch_space + order, samples - order, total_bits);
    
    std::cerr << "Rice Params:\n";
    for (auto r : rice_params)
        std::cerr << (int)r << " ";
    std::cerr << "\n";

    /* Subframe header*/
    _bw.write_bits(0b0001 << 4 | (uint8_t)order << 1, 8);

    /* Step 4. Write the warmup samples */
    for (int i = 0; i < order; i++)
        _bw.write_bits(((int16_t)pcm_buf[i]), 16);

    /* Step 8. Write the residuals to file */
    int samples_in_res = _bw.write_residual(scratch_space + order, samples, order, 0, rice_params);

    /* Step 9. Write the padding */
    _bw.write_padding();

    /* Step 10. Finally, write the frame footer and we are done */
    /*uint16_t crc16 = _bw.calc_crc16();
    _bw.write_bits(crc16, 16);
    */
    _bw.flush();

    return true;
}

void FLACEncoder::setSamples(uint64_t samples) {
    _samples = samples;
}
