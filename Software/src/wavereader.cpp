/**************************************/
/* wavereader.cpp - Read WAVE files  */
/************************************/

#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <memory>

#include "bitreader.hpp"
#include "bitwriter.hpp"
#include "wavereader.hpp"

WaveMetaData::WaveMetaData() {
    memset(_ChunkID, 0, 5);
    _ChunkSize = 0;
    memset(_Format, 0, 5);
    memset(_Subchunk1ID, 0, 5);
    _Subchunk1Size = 0;
    _AudioFormat = 0;
    _NumChannels = 0;
    _ByteRate = 0;
    _BlockAlign = 0;
    _BitsPerSample = 0;
    memset(_Subchunk2ID, 0, 5);
    _metadata_size = 0;
    _metadata = NULL;
}

WaveMetaData::WaveMetaData(uint16_t NumChannels, uint32_t SampleRate, uint16_t BitsPerSample, uint32_t NumSamples) {
    _NumChannels = NumChannels;
    _SampleRate = SampleRate;
    _BitsPerSample = BitsPerSample;

    strncpy(_ChunkID, "RIFF", 5);
    strncpy(_Format, "WAVE", 5);
    strncpy(_Subchunk1ID, "fmt ", 5);
    strncpy(_Subchunk2ID, "data", 5);
    _Subchunk1Size = 16;
    _AudioFormat = 1;
    _ByteRate = _SampleRate * _NumChannels * _BitsPerSample / 8;
    _BlockAlign = _NumChannels * _BitsPerSample / 8;
    _metadata = NULL;
    _metadata_size = 0;

    this->setNumSamples(NumSamples);
}

void WaveMetaData::print(FILE *f) {
    fprintf(f, "ChunkID: %s\n\
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
Metadata: %d\n",
            _ChunkID, _ChunkSize, _Format, _Subchunk1ID, _Subchunk1Size, _AudioFormat, _NumChannels, _SampleRate,
            _ByteRate, _BlockAlign, _BitsPerSample, _Subchunk2ID, _Subchunk2Size, _metadata_size);
}

int WaveMetaData::read(BitReader &fr) {
    fr.read_chunk(_ChunkID, 4); // Might need to add terminating null...
    fr.read_word_LE(&_ChunkSize);
    fr.read_chunk(_Format, 4);
    fr.read_chunk(_Subchunk1ID, 4);
    fr.read_word_LE(&_Subchunk1Size);
    fr.read_word_LE(&_AudioFormat);
    fr.read_word_LE(&_NumChannels);
    fr.read_word_LE(&_SampleRate);
    fr.read_word_LE(&_ByteRate);
    fr.read_word_LE(&_BlockAlign);
    fr.read_word_LE(&_BitsPerSample);
    fr.read_chunk(_Subchunk2ID, 4);
    fr.read_word_LE(&_Subchunk2Size);

    /* FIXME: Add validation of above meta data here */
    return true;
}

int WaveMetaData::write(BitWriter &bw) {
    bw.write_chunk(_ChunkID, 4);
    bw.write_word_LE(_ChunkSize);
    bw.write_chunk(_Format, 4);
    bw.write_chunk(_Subchunk1ID, 4);
    bw.write_word_LE(_Subchunk1Size);
    bw.write_word_LE(_AudioFormat);
    bw.write_word_LE(_NumChannels);
    bw.write_word_LE(_SampleRate);
    bw.write_word_LE(_ByteRate);
    bw.write_word_LE(_BlockAlign);
    bw.write_word_LE(_BitsPerSample);
    bw.write_chunk(_Subchunk2ID, 4);
    bw.write_word_LE(_Subchunk2Size);
    bw.flush();

    return true; /* FIXME: Error checking */
}

void WaveMetaData::setNumSamples(uint64_t numSamples) {
    /* Recalculate the chunk sizes for a WAVE file, given a total of pcm_samples
     */
    uint32_t new_subchunk2_size = numSamples * (_BitsPerSample / 8);
    uint32_t new_chunk_size = new_subchunk2_size + 36 + _metadata_size - 1;
    _Subchunk2Size = new_subchunk2_size;
    _ChunkSize = new_chunk_size;
}

uint64_t WaveMetaData::getNumSamples() {
    return _Subchunk2Size / (_NumChannels * (_BitsPerSample / 8));
}

uint16_t WaveMetaData::getNumChannels() {
    return _NumChannels;
}

WaveReader::WaveReader() : _meta{}, _samplesRead{0} {
}

WaveMetaData &WaveReader::getMetaData() {
    return _meta;
}

uint64_t WaveReader::getSamplesLeft() {
    return _meta.getNumSamples() - _samplesRead;
}

int WaveReader::read_metadata(BitReader &fr) {
    return _meta.read(fr);
}

int WaveReader::read_data(BitReader &fr, int16_t *pcm, uint64_t samples) {
    /* Fill pcm with samples of data... */
    if (samples > getSamplesLeft()) {
        _samplesRead = _meta.getNumSamples();
        return fr.read_words_LE_aligned(pcm, getSamplesLeft());
    } else {
        samples += _samplesRead;
        return fr.read_words_LE_aligned(pcm, samples);
    }
}

WaveWriter::WaveWriter(WaveMetaData &meta) : _meta{meta} {
}

int WaveWriter::write(BitWriter &bw, int32_t **pcm) {
    this->write_metadata(bw);
    /* We assume that the num samples in pcm is same as in meta... */
    return write_data(bw, pcm, _meta.getNumSamples());
}
int WaveWriter::write_metadata(BitWriter &bw) {
    return _meta.write(bw);
}

/* Samples is the number of samples per channel...*/
int WaveWriter::write_data(BitWriter &bw, int32_t **pcm, uint64_t samples) {
    /* Expect multiple channels and we will interleave them. */
    unsigned i, ch;
    for (i = 0; i < samples; i++)
        for (ch = 0; ch < _meta.getNumChannels(); ch++)
            // printf("ch: %d i: %d v: %d\n", ch, i, (int16_t)pcm[ch][i]);
            bw.write_word_LE((int16_t)pcm[ch][i]);
    return true; /* FIXME: Erro rching */
}

WaveMetaData &WaveWriter::getMetaData() {
    return _meta;
}
