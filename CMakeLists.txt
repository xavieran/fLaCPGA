cmake_minimum_required(VERSION 2.8)
project( MyFlacDecoder )

include_directories(includes)

set(HEADER_FILES src/bitreader.cpp src/frames.cpp src/subframes.cpp src/metadata.cpp 
    src/flacreader.cpp includes/bitreader.hpp includes/frames.hpp includes/subframes.hpp 
    includes/metadata.hpp includes/constants.hpp includes/flacreader.hpp src/wavereader.cpp
    includes/wavereader.hpp includes/bitwriter.h src/bitwriter.c)

set(XFILES src/bitreader.cpp includes/bitreader.hpp)

set(CMAKECXX_FLAGS -g -static -std=c++11 -pedantic -Wall -Wextra -Wcast-align -Wcast-qual -Wctor-dtor-privacy 
    -Wdisabled-optimization -Wformat=2 -Winit-self -Wlogical-op -Wmissing-declarations 
    -Wmissing-include-dirs -Wnoexcept -Wold-style-cast -Woverloaded-virtual 
    -Wredundant-decls -Wshadow -Wsign-conversion -Wsign-promo -Wstrict-null-sentinel 
    -Wstrict-overflow=5 -Wswitch-default -Wundef -Werror -Wno-unused)



add_executable (../tests/test_bitreader ../tests/bitreader_test.cpp ${XFILES})
add_executable (read_wav src/read_wav.cpp ${HEADER_FILES})
add_executable (read_wavo src/read_wav.c ${HEADER_FILES})
add_executable (read_flac src/read_flac.cpp ${HEADER_FILES})


