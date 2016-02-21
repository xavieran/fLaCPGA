cmake_minimum_required(VERSION 2.8)
project( MyFlacDecoder )

include_directories(includes)

set(FLAC_DECODER_SOURCES src/bitreader.cpp src/frames.cpp src/subframes.cpp
    src/metadata.cpp src/flacdecoder.cpp src/bitwriter.cpp src/wavereader.cpp)
set(FLAC_DECODER_INCLUDES includes/bitreader.hpp includes/frames.hpp includes/subframes.hpp
    includes/metadata.hpp includes/flacdecoder.hpp includes/bitwriter.hpp includes/wavereader.hpp)

set( src/wavereader.cpp
    includes/wavereader.hpp includes/bitwriter.h src/bitwriter.c)

set(XFILES src/bitreader.cpp includes/bitreader.hpp)

set(CMAKE_CXX_FLAGS "-g -static -Og -std=c++11 -Wall -Wno-unused-variable -Wno-switch")


#add_executable (../tests/test_bitreader ../tests/bitreader_test.cpp ${XFILES})
#add_executable (read_wav src/read_wav.cpp ${HEADER_FILES})
#add_executable (read_wavo src/read_wav.c ${HEADER_FILES})
add_executable (flacd src/flacd.cpp ${FLAC_DECODER_SOURCES} ${FLAC_DECODER_INCLUDES})


