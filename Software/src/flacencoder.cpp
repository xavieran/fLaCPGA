/**********************************
 * FLACEncoder class               *
 **********************************/

#ifndef FLAC_ENC_H
#define FLAC_ENC_H

#include "frames.hpp"
#include "subframes.hpp"
#include "metadata.hpp"
#include "constants.hpp"

#include "bitwriter.hpp"
#include "fixedencoder.hpp"
#include "riceencoder.hpp"
#include "flacencoder.hpp"

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <vector>
#include <memory>

FLACEncoder::FLACEncoder(std::shared_ptr<std::fstream> f){
    _bw = std::make_shared<BitWriter>(f);    
}

bool FLACEncoder::write_header(){
    auto msi = FLACMetaStreamInfo();
    msi.setTotalSamples(_samples);
    msi.write(_bw);
    
    return true;
}

bool FLACEncoder::write_frame(int32_t *pcm_buf, int samples, uint32_t frame){
    /* Step 1. Write the frame header */
    auto frame_header = FLACFrameHeader();
    frame_header.setFrameNumber(frame);
    frame_header.write(_bw);
    
    
    /* Step 2. Find the best order for this frame */
     int order = FixedEncoder::calc_best_order(pcm_buf, samples);
     
     std::cerr << "Frame: " << frame << "\nBest order: " << order << "\n";
     
    /* Step 3. Now we write the Subframe header */
    // Yes, I will need to make this more general of course, but this 
    // writes a fixed header assuming no wasted bits
    _bw->write_bits(0b0001 << 4 | (uint8_t) order << 1, 8);
    
    /* Step 4. Write the warmup samples */
    for (int i = 0; i < order; i++){
        _bw->write_bits(((int16_t) pcm_buf[i]), 16);
    }
    
    /* Step 5. Now we calculate the residuals */
    int32_t scratch_space[samples];
    FixedEncoder::calc_residuals(pcm_buf, scratch_space, samples, order);
    
    /* Step 7. Calculate the best residual parameters */
    
    auto rice_params = RiceEncoder::calc_best_rice_params(scratch_space + order, samples - order);
    
    std::cerr << "Rice Params: \n";
    for (auto r : rice_params){
        std::cerr << (int) r << " ";
    } std::cerr << "\n";
    
    /* Step 8. Write the residuals to file */
    _bw->write_residual(scratch_space, samples, order, 0, rice_params);
    
    std::cerr << "SAMPLES:::\n";
    for (int i = 0; i < samples; i++){
        std::cerr << pcm_buf[i] <<" " ;
    } std::cerr << "\n";
    
    std::cerr << "RESIUDALS:::\n";
    for (int i = 0; i < samples; i++){
        std::cerr << scratch_space[i] << " ";
    }
    std::cerr << "\n";
    
    /* Step 9. Write the padding */
    _bw->write_padding();
    
    /* Step 10. Finally, write the frame footer and we are done */
    _bw->write_bits(_bw->calc_crc16(), 16);
    
    /* Should keep the buffer from overfilling... */
    std::cerr << "Wrote " << _bw->flush() << "\n\n";
    
    return true;
}

void FLACEncoder::setSamples(uint64_t samples){
    _samples = samples;
}
#endif