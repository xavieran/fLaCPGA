/**********************************
 * Simple prog to read a flac file *
 **********************************/

#include <ctype.h>
#include <getopt.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <vector>

#include "BitWriter.hpp"
#include "FLACDecoder.hpp"
#include "Metadata.hpp"
#include "WaveReader.hpp"

void exit_with_help(char *argv[]) {
    fprintf(stderr, "usage: %s [ OPTIONS ] infile.flac [outfile.wav]\n", argv[0]);
    fprintf(stderr, "  -m : Print fLaC metadata headers\n");
    fprintf(stderr, "  -M : Print ALL metadata. This includes frame and subframe "
                    "headers.\n");
    fprintf(stderr, "  -p : Print input file PCM values, interleaved\n");
    fprintf(stderr, "  -r : Print input file subframe residuals\n");
    fprintf(stderr, "  -d : Decode input file to WAV\n");
    exit(1);
}

int main(int argc, char *argv[]) {
    int opt = 0, metadata = 0, all_metadata = 0, print_pcm = 0, decode = 0;
    int print_residuals = 0;
    while ((opt = getopt(argc, argv, "mMpdhr:")) != EOF)
        switch (opt) {
        case 'm':
            metadata = 1;
            break;
        case 'M':
            all_metadata = 1;
            break;
        case 'p':
            print_pcm = 1;
            break;
        case 'd':
            decode = 1;
            break;
        case 'r':
            print_residuals = 1;
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
            fprintf(stderr, "ERROR: opening %s for input\n", argv[optind]);
            return 1;
        }
    }

    // if (optind + 1 < argc)
    if (print_pcm || decode) {
        fout = std::make_shared<std::fstream>(argv[optind + 1], std::ios::out | std::ios::binary);
        if (fout->fail()) {
            fprintf(stderr, "ERROR: opening %s for output\n", argv[optind + 1]);
            return 1;
        }
    }

    FLACDecoder flac_reader = FLACDecoder(fin);
    int32_t **buf = NULL;

    if (metadata) {
        /* Print file header and metadata*/
        flac_reader.print_meta();
    } else if (all_metadata) {
        flac_reader.print_all_metadata();
        /* Print each frame... */
    } else if (print_pcm) {
        /* Print the PCM values to stdout, interleaved */
        BitWriter bw = BitWriter(fout);
        /* First get flac stream info */
        flac_reader.read_meta();
        FLACMetaStreamInfo *info = flac_reader.getMetaData().getStreamInfo();

        int channels = info->getNumChannels();
        int intraSamples = info->getTotalSamples();

        buf = (int32_t **)malloc(sizeof(int32_t *) * channels);

        for (int ch = 0; ch < channels; ch++)
            buf[ch] = (int32_t *)malloc(sizeof(int32_t) * intraSamples);

        /* Now read and print a frame at a time */
        int64_t samples = 0;
        int current_sample_size = 0;
        while (samples < intraSamples) {
            current_sample_size = flac_reader.read_frame(buf, 0) / channels;
            samples += current_sample_size;
            for (int i = 0; i < current_sample_size; i++)
                for (int ch = 0; ch < channels; ch++)
                    fprintf(stdout, "%d\n", buf[ch][i]);
        }

        for (int ch = 0; ch < channels; ch++)
            free(buf[ch]);
        free(buf);
        fin->close();
    } else if (print_residuals) {
        // TODO
    } else if (fout == NULL) {
        /* Print file header and metadata*/
        flac_reader.read_meta();
        flac_reader.getMetaData().print(stdout);
    } else if (decode || !decode) { // Haha

        BitWriter bw = BitWriter(fout);
        /* First get flac stream info */
        flac_reader.read_meta();
        FLACMetaStreamInfo *info = flac_reader.getMetaData().getStreamInfo();

        int channels = info->getNumChannels();
        int intraSamples = info->getTotalSamples();

        buf = (int32_t **)malloc(sizeof(int32_t *) * channels);

        for (int ch = 0; ch < channels; ch++)
            buf[ch] = (int32_t *)malloc(sizeof(int32_t) * intraSamples);

        /* Now set the WAVE file info and write it's header. */
        WaveMetaData meta = WaveMetaData(channels, 44100, 16, 0);
        WaveWriter w = WaveWriter(meta);
        meta.write(bw);

        /* Now read and write a frame at a time */
        int64_t samples = 0;
        int current_sample_size = 0;
        while (samples < intraSamples) {
            current_sample_size = flac_reader.read_frame(buf, 0) / channels;
            w.write_data(bw, buf, current_sample_size);
            samples += current_sample_size;
            bw.flush();
        }

        /* Now that we have the correct number of samples, we rewrite the header
         */
        meta.setNumSamples(samples * channels);
        bw.reset();
        meta.write(bw);
        bw.flush();

        for (int ch = 0; ch < channels; ch++)
            free(buf[ch]);
        free(buf);
        fin->close();
        fout->close();
    }

    return 0;
}
