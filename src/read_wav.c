/**********************************
 * Simple prog to read a wav file *
 **********************************/


#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "bitreader.h"
#include "bitwriter.h"

struct WaveMeta {
   char ChunkID[5]; /* RIFF */
   uint32_t ChunkSize; /* 4 + (8 + Subchunk1Size) + (8 + Subchunk2Size) */
   char Format[5]; /* WAVE */
   
   char Subchunk1ID[5]; /* fmt */
   uint32_t Subchunk1Size; /* Size of this Subchunk, should 16 */
   uint16_t AudioFormat; /* PCM = 1 (Linear quantization) */
   uint16_t NumChannels; /* Mono = 1, Stereo = 2, etc. */
   uint32_t SampleRate; /* 8000, 44100, etc. */
   uint32_t ByteRate; /* SampleRate * NumChannels * BitsPerSample/8 */
   uint16_t BlockAlign; /* NumChannels * BitsPerSample/8 */
   uint16_t BitsPerSample; /* 8 bits = 8, 16 bits = 16, etc. */
   
   char Subchunk2ID[5]; /* data */
   uint32_t Subchunk2Size; /* NumSamples * NumChannels * BitsPerSample/8 */
   
   uint8_t *metadata;
   int metadata_size;
}; 

#define READSIZE 1024

void printWaveMeta(struct WaveMeta *meta, FILE* f){
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
    meta->ChunkID, meta->ChunkSize, meta->Format, meta->Subchunk1ID, meta->Subchunk1Size,\
    meta->AudioFormat, meta->NumChannels, meta->SampleRate, meta->ByteRate,meta->BlockAlign,\
    meta->BitsPerSample, meta->Subchunk2ID, meta->Subchunk2Size, meta->metadata_size);
}

struct WaveMeta read_wav(FILE *fin, int16_t **pcm){
    uint8_t buffer[READSIZE * 2 * 2];
    
    struct WaveMeta meta;
    
    if (fread(buffer, 1, 4, fin) != 4) read_error(fin);
    strncat(meta.ChunkID, buffer, 4);
    if (fread(buffer, 1, 4, fin) != 4) read_error(fin);
    meta.ChunkSize = ((((((int32_t)buffer[3] << 8) | buffer[2]) << 8) | buffer[1]) << 8) | buffer[0];
    if (fread(buffer, 1, 4, fin) != 4) read_error(fin);
    strncat(meta.Format, buffer, 4);
    
    if (fread(buffer, 1, 4, fin) != 4) read_error(fin);
    strncat(meta.Subchunk1ID, buffer, 4);
    if (fread(buffer, 1, 4, fin) != 4) read_error(fin);
    meta.Subchunk1Size = ((((((int32_t)buffer[3] << 8) | buffer[2]) << 8) | buffer[1]) << 8) | buffer[0];
    if (fread(buffer, 1, 2, fin) != 2) read_error(fin);
    meta.AudioFormat = ((int16_t)buffer[1] << 8) | buffer[0];
    if (fread(buffer, 1, 2, fin) != 2) read_error(fin);
    meta.NumChannels = ((int16_t)buffer[1] << 8) | buffer[0];
    if (fread(buffer, 1, 4, fin) != 4) read_error(fin);
    meta.SampleRate = ((((((int32_t)buffer[3] << 8) | buffer[2]) << 8) | buffer[1]) << 8) | buffer[0];
    if (fread(buffer, 1, 4, fin) != 4) read_error(fin);
    meta.ByteRate = ((((((int32_t)buffer[3] << 8) | buffer[2]) << 8) | buffer[1]) << 8) | buffer[0];
    if (fread(buffer, 1, 2, fin) != 2) read_error(fin);
    meta.BlockAlign = ((int16_t)buffer[1] << 8) | buffer[0];
    if (fread(buffer, 1, 2, fin) != 2) read_error(fin);
    meta.BitsPerSample = ((int16_t)buffer[1] << 8) | buffer[0];
    
    if (fread(buffer, 1, 4, fin) != 4) read_error(fin);
    strncat(meta.Subchunk2ID, buffer, 4);
    if (fread(buffer, 1, 4, fin) != 4) read_error(fin);
    meta.Subchunk2Size = ((((((int32_t)buffer[3] << 8) | buffer[2]) << 8) | buffer[1]) << 8) | buffer[0];
   
    /* Add validation of above meta data here */
    
    int sample_rate = meta.SampleRate;
    int channels = meta.NumChannels;
    int bps = meta.BitsPerSample;
    int total_samples = meta.Subchunk2Size / (meta.BitsPerSample / 8);
    
    *pcm = malloc(sizeof(int16_t)*total_samples);
    
    /* read blocks of samples from WAVE file and feed to encoder */
    size_t left = (size_t) total_samples;
    
    while(left) {
        // need will be either the full buffer, or the rest of what's left in the file
        size_t need = (left>READSIZE? (size_t)READSIZE : (size_t)left);
        if(fread(buffer, meta.BitsPerSample / 8, need, fin) != need) {
            fprintf(stderr, "ERROR: reading from WAVE file %d\n",(int)need);
        } else {
            size_t i;
            for(i = 0; i < need; i++) {
                (*pcm)[total_samples - left + i] = (int16_t)(((int16_t)(int8_t)buffer[2*i+1] << 8) | (int16_t)buffer[2*i]);
            }
        }
        left -= need;
    }
    
    if (fread(buffer, 1, 1, fin)){
        int cnt = 1;
        while (fread(buffer + cnt++, 1, 1, fin)){;}
        
        meta.metadata = malloc(sizeof(uint8_t)*cnt);
        memcpy(meta.metadata, buffer, cnt);
        meta.metadata_size = cnt;
    } else {
        meta.metadata = NULL;
        meta.metadata_size = 0;
    }
    
    return meta;
}

int write_wav(FILE *fout, struct WaveMeta meta, int16_t *pcm){
    if (fwrite(meta.ChunkID, 1, 4, fout) != 4) write_error(fout);
    if (!write_little_endian_uint32(fout, meta.Subchunk2Size + 36 + meta.metadata_size - 1)) write_error(fout);
    if (fwrite(meta.Format, 1, 4, fout) != 4) write_error(fout);
    if (fwrite(meta.Subchunk1ID, 1, 4, fout) != 4) write_error(fout);
    if (!write_little_endian_uint32(fout, meta.Subchunk1Size)) write_error(fout);
    if (!write_little_endian_uint16(fout, meta.AudioFormat)) write_error(fout);
    if (!write_little_endian_uint16(fout, meta.NumChannels)) write_error(fout);
    if (!write_little_endian_uint32(fout, meta.SampleRate)) write_error(fout);
    if (!write_little_endian_uint32(fout, meta.ByteRate)) write_error(fout);
    if (!write_little_endian_uint16(fout, meta.BlockAlign)) write_error(fout);
    if (!write_little_endian_uint16(fout, meta.BitsPerSample)) write_error(fout);
    if (fwrite(meta.Subchunk2ID, 1, 4, fout) != 4) write_error(fout);
    if (!write_little_endian_uint32(fout, meta.Subchunk2Size)) write_error(fout);

    int i;
    for (i = 0; i < meta.NumChannels * meta.Subchunk2Size/4; i++){
        write_little_endian_uint16(fout, pcm[i]);
    }

    if (meta.metadata_size != 0){
        if (fwrite(meta.metadata, 1, meta.metadata_size - 1, fout) != meta.metadata_size - 1) write_error(fout);
    }
}

int recalc_wave_meta(struct WaveMeta *meta, int pcm_samples){
    /* Recalculate the chunk sizes for a WAVE file, given a total of pcm_samples */
    uint32_t new_subchunk2_size = pcm_samples * (meta->BitsPerSample / 8) ;
    uint32_t new_chunk_size = new_subchunk2_size + 36 + meta->metadata_size - 1;
    meta->Subchunk2Size = new_subchunk2_size;
    meta->ChunkSize = new_chunk_size;
}

int delay_and_add(int delay, int16_t *pcm, int size, int16_t **out){
    *out = malloc(sizeof(int16_t)*size);
    int i;
    for (i = delay; i < size; i += 2){
        (*out)[i + 1] = pcm[i + 1];
        (*out)[i] = (*out)[i + 1 - delay];
    }
}

int main(int argc, char *argv[])
{
    if(argc < 2) {
        fprintf(stderr, "usage: %s infile.wav [outfile.wav]\n", argv[0]);
        return 1;
    }

    FILE *fin;
    FILE *fout;
    
    int16_t * pcm;
    int32_t samples;
    
    if((fin = fopen(argv[1], "rb")) == NULL) {
        fprintf(stderr, "ERROR: opening %s for output\n", argv[1]);
        return 1;
    }

    struct WaveMeta meta = read_wav(fin, &pcm);
    printWaveMeta(&meta, stderr);
    fclose(fin);
    
    if (argc == 3){
        fprintf(stderr, "Writing to %s\n", argv[2]);
        fout = fopen(argv[2], "wb");
        write_wav(fout, meta, pcm);
        fclose(fout);
    }
    
    return 0;
}