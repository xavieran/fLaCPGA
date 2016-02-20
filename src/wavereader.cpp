/**************************************/
/* wavereader.cpp - Read WAVE files  */
/************************************/

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#include "bitreader.hpp"
#include "wavereader.hpp"

WaveMetaData::WaveMetaData(){
    ;
}

void WaveMetaData::print(FILE* f){
    fprintf(f, \
"ChunkID: %s\n\
    ChunkSize: %d\n\
    Format: %s\n\
Subchunk1ID: %s\n\
    Subchunk1Size: %d\n\
    AudioFormat: %d\n\
    NumChannels: %d\n\
    SampleRate: %d\n\
    ByteRate: %d\n\
    BlockAlign: %d\n\
    BitsPerSample: %d\n\
Subchunk2ID: %s\n\
    Subchunk2Size: %d\n\
Metadata: %d\n", \
    _ChunkID, _ChunkSize, _Format, _Subchunk1ID, _Subchunk1Size,\
    _AudioFormat, _NumChannels, _SampleRate, _ByteRate,_BlockAlign,\
    _BitsPerSample, _Subchunk2ID, _Subchunk2Size, _metadata_size);
}

int WaveMetaData::read(FileReader *fr){
    
    fr->read_chunk<char>(_ChunkID, 4); // Might need to add terminating null...
    fr->read_word_u32LE(&_ChunkSize);
    fr->read_chunk<char>(_Format, 4);
    fr->read_chunk<char>(_Subchunk1ID, 4);
    fr->read_word_u32LE(&_Subchunk1Size);
    fr->read_word_u16LE(&_AudioFormat);
    fr->read_word_u16LE(&_NumChannels);
    fr->read_word_u32LE(&_SampleRate);
    fr->read_word_u32LE(&_ByteRate);
    fr->read_word_u16LE(&_BlockAlign);
    fr->read_word_u16LE(&_BitsPerSample);
    fr->read_chunk<char>(_Subchunk2ID, 4);
    fr->read_word_u32LE(&_Subchunk2Size);
   
    /* Add validation of above meta data here */
}


int WaveMetaData::setNumSamples(uint64_t numSamples){
    /* Recalculate the chunk sizes for a WAVE file, given a total of pcm_samples */
    uint32_t new_subchunk2_size = numSamples * (_BitsPerSample / 8) ;
    uint32_t new_chunk_size = new_subchunk2_size + 36 + _metadata_size - 1;
    _Subchunk2Size = new_subchunk2_size;
    _ChunkSize = new_chunk_size;
}

uint64_t WaveMetaData::getNumSamples(){
    return _Subchunk2Size/(_NumChannels*(_BitsPerSample/8));
}

WaveReader::WaveReader(){
    _meta = new WaveMetaData();
    _samplesRead = 0;
}

WaveMetaData *WaveReader::getMetaData(){
    return _meta;
}

int WaveReader::read_metadata(FileReader *fr){
    return _meta->read(fr);
}

int WaveReader::read_data(FileReader *fr, int16_t *pcm, uint64_t samples){
    /* Fill pcm with samples of data... */
    if (samples > (this->_meta->getNumSamples() - _samplesRead)){
        fr->read_words_i16LE(pcm, this->_meta->getNumSamples() - _samplesRead);
    } else {
        fr->read_words_i16LE(pcm, samples);
        samples += _samplesRead;
    }
}