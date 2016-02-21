# fLaCPGA
fLaCPGA will be an implementation of a fLaC encoder/decoder on FPGAs.

At the moment I am working on implementing the encoder and decoder in C++.

- [x] Decode FLAC files C++
- [ ] Encode FLAC files C++
- [ ] Decode FLAC files Verilog
- [ ] Encode FLAC files Verilog


1. Decode Flac Files C++
   1. Make the bitreader code nicer and buffered [x]
   2. Implement audio data -> WAV [x]
   3. Implement multichannel interleaving, etc. [x]
