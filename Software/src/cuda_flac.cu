/* flac in cuda */
#include <getopt.h>
#include<ctype.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <vector>

#include "wavereader.hpp"
#include "bitwriter.hpp"

#include <cuda.h>
#include <cuda_runtime.h>

#include <cuda_runtime_api.h>
#include <cuda_profiler_api.h>

#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort=true)
{
   if (code != cudaSuccess) 
   {
      fprintf(stderr,"GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
      if (abort) exit(code);
   }
}

// Should probably window data also...
__global__ void calculate_lags(
    const float *const dpcm_buf, float * dlags, 
    const int spb, const int64_t samples){
/* Calculates lags and leaves them in memory like so:
 * |b0i0l0,b0i1l0...b0i4095l0|b0i0l1,b0i1l1...b0i4095l1|
 * ...
 * |b1i0l0,b1i1l0...
 *
 * Launch this kernel like so:
 * <<<(1 << 12, 4, 12),1024>>>
 * <<<dim3(blocks, breakup of block within grid, lags), 
 * maximum threads/block>>> */    

    int t = threadIdx.x;
    int bx = blockIdx.x;
    int by = blockIdx.y;
    int j = blockIdx.z;
    int N = blockDim.x; 
    int n = blockDim.y;
    int l = blockDim.z;
    int i = t + by*n + bx*N;
    
    float a = dpcm_buf[i];
    float b = dpcm_buf[i + j];
    
    dlags[i + j*4096] = a*b;
}

// Reduce the autocorrelation lags...
__global__ void sum_lags(const float * const dlags, float * dslags, const int spb, const int64_t samples){
    
    
}

__global__ void levinson_durbinson(const float * const dautoc, float * dmodelc, const int spb, const int64_t samples){
    
    
}

/*
 * Stage 1:
 * data[i]*modelc[i] 
 */
__global__ void fir_stage1(const float * const dpcm_buf, const float * const dmodelc, 
                           float *dfir_s1, const int spb, const int64_t samples){
    int j; // Which model coefficient
    int i; // Which data part
    dfir_s1[i+j] = dpcm_buf[i+j]*modelc[i+j];
    
}

/* Stage 2:
 * Sum the data from stage 1 to get result
 */
__global__ void fir_stage2(const float * const dfir_s1, float *dfir_s2, const int spb,
                           const int64_t samples){
}

/* Find best model
 * Check error in each model, select best one
 */
__global__ void fbm_stage1(const float * const dpcm_buf, const float * const dfir_s2, 
                           float *error, const int spb, const int64_t samples){
    
    /* Calculate error */
    int i;
    error[i] = dpcm_buf[i] - dfir_s2[i];
    
    /* Sum error in each block and model */
    
    /* Choose lowest error in each model */
    
    
    
}

/* 
 * Do rice encoding of error
 */

__global__ void fbr_stage1(const float * const error, float * tbpb, const int spb, const int64_t samples){
    /* encode each error using param */
    int param;
    int lmask;
    int i;
    
    tbpb[i] = error[i] >> param + (error[i] & lmask);
    
    /* do prefix sums of the errors for each param */
    
    /* Pick the lowest summed error */
}

/* 
 * Using the prefix sum errors, each thread can place
 * its rice encoded error in the correct place in the final output
 * Need to also be doing crc checks and then storing framing data........ :(
 */


void exit_with_help(char *argv[]){
    fprintf(stderr, "usage: %s [ OPTIONS ] infile.wav [outfile.flac]\n", argv[0]);
    exit(1);
}


int main(int argc, char *argv[]){
    int opt = 0, fixed = 0, verbatim = 0, single = 0, encode = 0;
    int order = 0;
    while ((opt = getopt(argc,argv,"fvs:")) != EOF)
        switch(opt)
        {
            case 'f': fixed = 1; encode = 1; break;
            case 'v': verbatim = 1; encode = 1; break;
            case 's': single = 1; 
                      encode = 1; 
                      std::cerr << "OPTARG::: " << optarg << "\n";
                      if (strcmp(optarg, "v") == 0)
                          verbatim = 1;
                      else
                        order = atoi(optarg);
                      break;
            case 'h':
            case '?': 
            default:
                exit_with_help(argv);
        }
        
    std::shared_ptr<std::fstream> fin;
    std::shared_ptr<std::fstream> fout;
    
    
    if (optind < argc){
        fin = std::make_shared<std::fstream>(argv[optind], std::ios::in | std::ios::binary);
        if(fin->fail()) {
            fprintf(stderr, "ERROR: opening %s for input\n", argv[optind]);
            return 1;
        }
    }
    
    auto fr = std::make_shared<BitReader>(fin);
    auto wr = std::make_shared<WaveReader>();
    wr->read_metadata(fr);
    auto meta = wr->getMetaData();
    meta->print(stdout);
    
    const int samples = 1 << 22; // ~1MB of samples
    
    int16_t * hpcm_buf = (int16_t *) malloc(sizeof(int16_t) * samples);
    
    float * hpcmf_buf = (float *) malloc(sizeof(float) * samples);
    
    float * dpcm_buf;
    cudaMalloc(&dpcm_buf, sizeof(float) * samples);
    
    gpuErrchk(cudaPeekAtLastError());
    auto tsamples = meta->getNumSamples();
    
    /*if (tsamples < samples){
        wr->read_data(fr, hpcm_buf, tsamples);
    } else {
        */
    tsamples -= wr->read_data(fr, hpcm_buf, samples);
    for (int i = 0; i < samples; i++) {
        hpcmf_buf[i] = (float) hpcm_buf[i];
    }
    

    
    float *dlags;
    cudaMalloc(&dlags, sizeof(float)*samples*12);
    gpuErrchk(cudaPeekAtLastError());
    
    float *hlags = (float *) malloc(sizeof(float)*4096);
    
    
    cudaMemcpyAsync(dpcm_buf, hpcmf_buf, samples, cudaMemcpyHostToDevice, 0);
    gpuErrchk(cudaPeekAtLastError());
    
    calculate_lags<<<dim3(1 << 12, 4, 12),1024>>>(dpcm_buf, dlags, 4096, samples);
    gpuErrchk(cudaPeekAtLastError());
    
    cudaDeviceSynchronize();
    cudaMemcpy(hlags, dlags, 4096, cudaMemcpyDeviceToHost);
    
    for (int i = 0; i < 60; i++){
        printf("i: %d :: %d %f %f\n", i, hpcm_buf[i], hpcmf_buf[i], hlags[i]);
    }
    
    cudaDeviceSynchronize();
    
    return 0;
}
