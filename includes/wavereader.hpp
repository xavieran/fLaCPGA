/**************************************/
/* wavereader.hpp - Read WAVE files  */
/************************************/

#ifndef WAVE_READER_H
#define WAVE_READER_H

#include "bitreader.hpp"
#include "bitwriter.hpp"

class WaveMetaData {
public:
    WaveMetaData();
    WaveMetaData(uint16_t NumChannels, uint32_t SampleRate, 
                 uint16_t BitsPerSample, uint32_t NumSamples);
    
    void print(FILE *f);
    
    int read(std::shared_ptr<BitReader> fr);
    int write(BitWriter *bw);
    void setNumSamples(uint64_t numSamples);
    uint64_t getNumSamples();
    uint16_t getNumChannels();
    
private:
   char _ChunkID[5]; /* RIFF */
   uint32_t _ChunkSize; /* 4 + (8 + Subchunk1Size)  (8 + Subchunk2Size) */
   char _Format[5]; /* WAVE */
   
   char _Subchunk1ID[5]; /* fmt  */
   uint32_t _Subchunk1Size; /* Size of this Subchunk, should 16 */
   uint16_t _AudioFormat; /* PCM = 1 (Linear quantization) */
   uint16_t _NumChannels; /* Mono = 1, Stereo = 2, etc. */
   uint32_t _SampleRate; /* 8000, 44100, etc. */
   uint32_t _ByteRate; /* SampleRate * NumChannels * BitsPerSample/8 */
   uint16_t _BlockAlign; /* NumChannels * BitsPerSample/8 */
   uint16_t _BitsPerSample; /* 8 bits = 8, 16 bits = 16, etc. */
   
   char _Subchunk2ID[5]; /* data */
   uint32_t _Subchunk2Size; /* NumSamples * NumChannels * BitsPerSample/8 */
   
   uint8_t *_metadata;
   int _metadata_size;
   
}; 


class WaveReader {
public:
    WaveReader();
    int read(std::shared_ptr<BitReader> fr, int16_t *pcm);
    int read_metadata(std::shared_ptr<BitReader> fr);
    int read_data(std::shared_ptr<BitReader> fr, int16_t *pcm, uint64_t samples);
    uint64_t getSamplesLeft();
    
    WaveMetaData *getMetaData();
private:
    WaveMetaData *_meta;
    uint64_t _samplesRead;
};


class WaveWriter {
public:
    WaveWriter(WaveMetaData *meta);
    int write(BitWriter *bw, int32_t **pcm);
    int write_metadata(BitWriter *bw);
    int write_data(BitWriter *bw, int32_t **pcm, uint64_t samples);
    WaveMetaData *getMetaData();
private:
    WaveMetaData *_meta;
    uint64_t _samplesWritten;
};

#endif