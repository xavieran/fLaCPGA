# fLaCPGA
fLaCPGA is an implementation of a fLaC encoder/decoder on FPGAs.

At the moment I am working on the finishing touches of the Verilog Encoder

- [x] Decode FLAC files C++
- [x] Encode FLAC files C++
- [x] Decode FLAC files Verilog
- [ ] Encode FLAC files Verilog

Current results are very promising, the design can encode 16 bit PCM audio at a rate of ~440MB/s on a ten year old FPGA chip (Cyclone II). 
