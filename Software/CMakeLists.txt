cmake_minimum_required(VERSION 2.8)
project( fLaCPGA )

add_subdirectory(gtest)
include_directories(gtest/include)

include_directories(includes)
include_directories(src)


set(BIT_IO_SRC src/bitreader.cpp src/bitwriter.cpp)
set(BIT_IO_INC includes/bitreader.hpp src/bitreader.tpp includes/bitwriter.hpp src/bitwriter.tpp)


set(WAVE_SRC src/wavereader.cpp)
set(WAVE_INC includes/wavereader.hpp)

set(FLAC_DECODER_SOURCES  src/frames.cpp src/subframes.cpp
    src/metadata.cpp src/flacdecoder.cpp  src/wavereader.cpp ${BIT_IO_SRC})
set(FLAC_DECODER_INCLUDES  includes/frames.hpp includes/subframes.hpp
    includes/metadata.hpp includes/flacdecoder.hpp includes/wavereader.hpp ${BIT_IO_INC})

set(CMAKE_CXX_FLAGS "-g -static -Og -std=c++14 -Wall -Wno-unused-variable -Wno-switch")


# Tests
add_executable (../tests/bitreader_test ../tests/bitreader_test.cpp ${BIT_IO_SRC} ${BIT_IO_INC})
target_link_libraries(../tests/bitreader_test gtest rt pthread)
add_executable (../tests/bitwriter_test ../tests/bitwriter_test.cpp  ${BIT_IO_SRC} ${BIT_IO_INC})
target_link_libraries(../tests/bitwriter_test gtest rt pthread)
add_executable (../tests/riceencoder_test ../tests/riceencoder_test.cpp  ${BIT_IO_SRC} src/riceencoder.cpp ${BIT_IO_INC} includes/riceencoder.hpp)
target_link_libraries(../tests/riceencoder_test gtest rt pthread)



add_executable (read_wav src/read_wav.cpp ${BIT_IO_SRC} ${BIT_IO_INC} ${WAVE_SRC} ${WAVE_INC})
add_executable (flacd src/flacd.cpp ${FLAC_DECODER_SOURCES} ${FLAC_DECODER_INCLUDES})

