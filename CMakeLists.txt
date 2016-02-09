cmake_minimum_required(VERSION 2.8)
project( MyFlacDecoder )

include_directories(includes)

set(HEADER_FILES src/bitreader.c src/bitwriter.c includes/bitreader.h includes/bitwriter.h)

add_executable (read_wav src/read_wav.c ${HEADER_FILES})
add_executable (read_flac src/read_flac.cpp ${HEADER_FILES})
