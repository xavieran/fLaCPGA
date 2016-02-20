/**************************************/
/* wavereader.hpp - Read WAVE files  */
/************************************/

#ifndef WAVE_READER_H
#define WAVE_READER_H

#include "bitreader.hpp"

class WaveMetaData {
public:
    WaveMetaData();
    void print(FILE *f);
    
    int read(FileReader *fr);
    int setNumSamples(uint64_t numSamples);
    uint64_t getNumSamples();
    
private:
   char _ChunkID[5]; /* RIFF */
   uint32_t _ChunkSize; /* 4 + (8 + Subchunk1Size) + (8 + Subchunk2Size) */
   char _Format[5]; /* WAVE */
   
   char _Subchunk1ID[5]; /* fmt */
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
    int read(FileReader *fr, int16_t *pcm);
    int read_metadata(FileReader*fr);
    int read_data(FileReader *fr, int16_t *pcm, uint64_t samples);
    WaveMetaData *getMetaData();
private:
    WaveMetaData *_meta;
    uint64_t _samplesRead;
};

#endif