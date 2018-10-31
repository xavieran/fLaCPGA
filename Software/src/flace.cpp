/* flace*/
#include <ctype.h>
#include <getopt.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <vector>

#define LOGURU_WITH_STREAMS 1
#include <loguru.hpp>

#include "BitWriter.hpp"
#include "FLACEncoder.hpp"
#include "Metadata.hpp"
#include "WaveReader.hpp"

void exit_with_help(char *argv[]) {
    fprintf(stderr, "usage: %s [ OPTIONS ] infile.wav [outfile.flac]\n", argv[0]);
    fprintf(stderr, "  -f : Use fixed frames\n");
    fprintf(stderr, "  -v : Encode verbatim (no compression)\n");
    fprintf(stderr, "  -s=order : Encode single frame with order given\n");
    exit(1);
}

int main(int argc, char *argv[]) {
    loguru::init(argc, argv);

    int opt = 0, fixed = 0, verbatim = 0, single = 0, encode = 0;
    int order = 0;
    int print_residuals = 0;

    while ((opt = getopt(argc, argv, "fvs:")) != EOF)
        switch (opt) {
        case 'f':
            fixed = 1;
            encode = 1;
            break;
        case 'v':
            verbatim = 1;
            encode = 1;
            break;
        case 's':
            single = 1;
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

    if (optind == 1)
        exit_with_help(argv);

    if (optind < argc) {
        fin = std::make_shared<std::fstream>(argv[optind], std::ios::in | std::ios::binary);
        if (fin->fail()) {
            LOG_F(FATAL, "Could not open %s for input", argv[optind]);
        }
    }

    if (encode) {
        fout = std::make_shared<std::fstream>(argv[optind + 1], std::ios::out | std::ios::binary);
        if (fout->fail()) {
            LOG_F(FATAL, "Could not open %s for output", argv[optind + 1]);
        }
    }

    BitReader fr = BitReader(fin);
    WaveReader wr = WaveReader();
    wr.read_metadata(fr);
    auto &meta = wr.getMetaData();
    meta.print(stdout);

    unsigned spb = 4096;

    int16_t pcm[spb];
    int32_t pcm32[spb];
    unsigned i;

    if (fixed) {
        LOG_F(INFO, "%ld samples to encode", meta.getNumSamples());
        auto fe = FLACEncoder(fout);
        fe.setSamples(meta.getNumSamples());
        fe.write_header();

        double total_samples = meta.getNumSamples();

        for (i = 0; i + spb < meta.getNumSamples(); i += spb) {
            wr.read_data(fr, pcm, spb);
            for (unsigned j = 0; j < spb; j++) {
                pcm32[j] = (int32_t)pcm[j];
            }
            fe.write_frame(pcm32, spb, i / spb);

            LOG_F(INFO,"%.6f%% Encoded\n", ((double)i) / total_samples * 100);
        }

        /*if (i != meta.getNumSamples()){
            int remainder = meta.getNumSamples() - i;
            wr.read_data(fr, pcm, remainder);
            for (unsigned j = 0; j < remainder; j++){ pcm32[j] = (int32_t)
        pcm[j];}

        }*/
    } else if (verbatim) {
        auto fe = FLACEncoder(fout);
        fe.setSamples(meta.getNumSamples());
        fe.write_header();

        double total_samples = meta.getNumSamples();

        for (i = 0; i + spb < meta.getNumSamples(); i += spb) {
            wr.read_data(fr, pcm, spb);
            for (unsigned j = 0; j < spb; j++) {
                pcm32[j] = (int32_t)pcm[j];
            }
            fe.write_frame_verbatim(pcm32, spb, i / spb);

            printf("%.2f%% Encoded\n", ((double)i) / total_samples * 100);
        }
    } else if (single) {
        auto fe = FLACEncoder(fout);

        wr.read_data(fr, pcm, spb);
        for (unsigned j = 0; j < spb; j++) {
            pcm32[j] = (int32_t)pcm[j];
        }

        if (verbatim) {
            fe.write_frame_verbatim(pcm32, 4096, 0);
        } else {
            fe.write_frame_fixed(pcm32, 4096, order, 0);
        }
    }
    return 0;
}
