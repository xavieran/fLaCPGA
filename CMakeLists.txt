cmake_minimum_required(VERSION 2.8)
project( MyFlacDecoder )

include_directories(includes)

set(HEADER_FILES src/bitreader.c src/bitwriter.c src/frames.cpp src/subframes.cpp src/metadata.cpp
 includes/bitreader.h includes/bitwriter.h includes/frames.hpp includes/subframes.hpp 
 includes/metadata.hpp)

set(XFILES src/bitreader.cpp includes/bitreader.hpp)


add_executable (test_bitreader tests/bitreader_test.cpp ${XFILES})
#add_executable (read_wav src/read_wav.c ${HEADER_FILES})
add_executable (read_flac src/read_flac.cpp ${HEADER_FILES})


