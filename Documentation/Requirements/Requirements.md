Abstract
========

Introduction
============

The goal of my final year project is to investigate hardware optimization techniques through the implementation of a Free Lossless Audio Codec (henceforth, fLaC) decoder and encoder in Verilog. fLaC is a lossless audio compression codec that is very popular as a method of distributing high quality audio recordings and for compressing large audio archives. Whilst there are a number of software implementations of the fLaC encoder and decoder, there are no freely available hardware implementations. An efficient hardware implementation would be of great use for a number of reasons. Many nations are now in the process of digitising large national audio archives. Audio archives require data to be compressed losslessly in order to preserve content in a form faithful to the original, however, uncompressed lossless data consumes large amounts of space. Currently, uncompressed formats such as WAVE and BWF\_WAVE are quite popular for audio archiving. Compressed audio has the major benefit of reducing space usage by up to half, doubling an archive’s potential storage space. In order to convert large (terabytes) amounts of audio data to a compressed format, a lot of computing power is required. If a hardware decoder were available, it would both reduce encoding time and reduce power consumed by the encoding process. fLaC is also gaining popularity as a medium for portable audio players. The players are very sensitive to power consumption, a hardware implementation would be of great use in reducing the power load of the decoding process. Another potential use case of a hardware encoder would be in a recording studio. Instead of recording audio to an uncompressed format, high quality audio could be encoded in real time as it comes in.

Audio Compression Overview
==========================

Just as with general data compression, there are two main methodologies for compressing audio data, lossy and lossless. Lossy audio encoding most often includes techniques such as psychoacoustic compression, where sounds that humans cannot perceive or differentiate are removed from the audio. These techniques will not be the focus of this project. Lossless compression, by comparison, encodes audio perfectly, that is, the decoded audio is identical to the original input samples. Audio is still affected by problems such as quantisation noise and recording device noise.
The main goal of any lossless compression algorithm is to remove redundancy from data, thereby reducing the amount of information needed to reproduce the data. Audio data is often highly redundant, samples of data that are close to each other will usually have very similar patterns, for example, samples of a clarinet playing the same note for a number of seconds will clearly have a similar spectral pattern over the period of time the note is held, thus offering redundancy to be exploited. The most popular method for lossless compression of audio data is to find an accurate model of the audio (a *predictor*), find the error (often called *residuals*) between the predictor and the true audio, then to encode the residuals using a variable bit length encoding in order to reduce the redundancy of the signal. The fLaC lossless audio compression algorithm borrows heavily from prior work in lossless encoding including the Shorten algorithm, and the AudioPAK algorithm. These algorithms use a technique called *linear prediction* to produce their audio model, and use Rice encoding to perform the entropy encoding phase of the compression. The advantage of these algorithms is the ease with which they can be translated into hardware, as the linear prediction step consists of a number of multiplies and adds.

Requirements
============

Documentation
-------------

A number of documents will be produced during this project.

-   Create a literature review

-   Document the efficiency limitations of the fLaC decoding and encoding algorithms

-   Create final report

-   Create a project description poster

-   Encoder and Decoder documentation, including in code documentation (comments) and a user guide

Research
--------

-   Identify areas of the fLaC algorithm that can be made more efficient

-   Investigate the applicability of hardware design principles such as pipelining and parallelism to the fLaC algorithm

-   Investigate the theoretical efficiency limitations of the fLaC algorithm

fLaC Decoder
------------

-   Implement software fLaC decoder in C++

-   Implement fLaC decoder in Verilog

-   Develop Verilog testbenches for each module

-   Test decoder on FPGA

-   Produce audio output using Development Board DAC

### Metadata and Frame Decoding

[fig:system<sub>o</sub>verview]

-   Decode fLaC Metadata stream

    -   Read and store variable bit length fields

    -   Read STREAMINFO metadata block

    -   Read and ignore all other metadata blocks

-   Decode fLaC Frame

    -   Read and store variable bit length fields

    -   Execute a CRC-8 check on the frame header

    -   Execute a CRC-16 check on the entire frame

    -   Decode each subframe

### Subframe Decoding

[fig:subframe<sub>o</sub>verview]

-   Decode fLaC Subframe

    -   Decode Constant encoded subframe

    -   Decode Verbatim encoded subframe

    -   Decode Fixed encoded subframe

    -   Decode LPC Encoded subframe

    -   Correct stereo decorrelation

### LPC and Fixed Decoding

[fig:LPC<sub>o</sub>verview]

-   Decode LPC and Fixed Subframes

    -   Read and store variable bit length fields

    -   Decode fLaC Specification residual

        -   Decode rice encoded variable length bit stream

    -   Perform LPC decoding using residuals and predictor coefficients

fLaC Encoder
------------

-   Implement software fLaC encoder in C++

-   Implement fLaC encoder in Verilog

-   Develop Verilog testbenches for each module

-   Test encoder on FPGA

### Metadata Encoder

-   Implement STREAMINFO writer

    -   Write variable bit length fields

### Frame Encoder

-   Write variable bit length fields

-   Write variable sized UTF codes

-   Perform input stream blocking

-   Perform input channel decorrelation

### Subframe Encoder

-   Encode Constant Subframes

    -   Find blocks of constant value in stream and run length encode them

    -   Ensure that these blocks are framed correctly

-   Encode Verbatim Subframes

    -   Detect when LPC and Fixed predictors show no gain when encoding a block

    -   Correctly frame verbatim subframes

-   Encode Fixed Subframes

    -   Find the optimal fixed parameters for encoding

    -   Encode Residuals

-   Encode LPC Subframes

    -   Find the optimal LPC coefficients for encoding a block

    -   Encode Residuals

-   Encode Residuals

    -   Find the optimal rice parameter for a block of residuals

    -   Correctly encode values using rice encoding


