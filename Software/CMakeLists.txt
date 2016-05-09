cmake_minimum_required(VERSION 2.8)
project( fLaCPGA )

add_subdirectory(gtest)
include_directories(gtest/include)

include_directories(includes)
include_directories(src)


set(BIT_IO_SRC src/bitreader.cpp src/bitwriter.cpp src/crc.cpp )
set(BIT_IO_INC includes/bitreader.hpp src/bitreader.tpp includes/bitwriter.hpp src/bitwriter.tpp
               includes/crc.hpp )


set(WAVE_SRC src/wavereader.cpp)
set(WAVE_INC includes/wavereader.hpp)

set(FLAC_DECODER_SOURCES  src/frames.cpp src/subframes.cpp
    src/metadata.cpp src/flacdecoder.cpp  src/wavereader.cpp 
    ${BIT_IO_SRC})
set(FLAC_DECODER_INCLUDES  includes/frames.hpp includes/subframes.hpp
    includes/metadata.hpp includes/flacdecoder.hpp includes/wavereader.hpp 
    ${BIT_IO_INC})

set(FLAC_ENCODER_SOURCES ${FLAC_DECODER_SOURCES} src/flacencoder.cpp src/riceencoder.cpp 
                         src/fixedencoder.cpp)
set(FLAC_ENCODER_INCLUDES ${FLAC_DECODER_INCLUDES} includes/flacencoder.hpp includes/riceencoder.hpp 
                         includes/fixedencoder.hpp)

set(CMAKE_CXX_FLAGS "-g -static -Og -std=c++14 -Wall -Wno-unused-variable -Wno-switch")


# Tests
add_executable (../tests/bitreader_test ../tests/bitreader_test.cpp ${BIT_IO_SRC} ${BIT_IO_INC})
target_link_libraries(../tests/bitreader_test gtest rt pthread)
add_executable (../tests/bitwriter_test ../tests/bitwriter_test.cpp  ${BIT_IO_SRC} ${BIT_IO_INC})
target_link_libraries(../tests/bitwriter_test gtest rt pthread)
add_executable (../tests/riceencoder_test ../tests/riceencoder_test.cpp  ${BIT_IO_SRC} src/riceencoder.cpp ${BIT_IO_INC} includes/riceencoder.hpp)
target_link_libraries(../tests/riceencoder_test gtest rt pthread)
add_executable (../tests/fixedencoder_test ../tests/fixedencoder_test.cpp  ${BIT_IO_SRC} src/fixedencoder.cpp ${BIT_IO_INC} includes/fixedencoder.hpp)
target_link_libraries(../tests/fixedencoder_test gtest rt pthread)
add_executable (../tests/encoder_test ../tests/encoder_test.cpp  ${BIT_IO_SRC} ${BIT_IO_INC} ${FLAC_ENCODER_SOURCES} ${FLAC_ENCODER_INCLUDES})
target_link_libraries(../tests/encoder_test gtest rt pthread)
#add_executable (../tests/crc_test ../tests/crc_test.cpp  ${BIT_IO_SRC} src/crc.cpp ${BIT_IO_INC} includes/crc.hpp)
#target_link_libraries(../tests/crc gtest rt pthread)


add_executable (../tests/generate_residual ../tests/generate_residual.cpp  ${BIT_IO_SRC} src/riceencoder.cpp ${BIT_IO_INC} includes/riceencoder.hpp)
target_link_libraries(../tests/generate_residual)



add_executable (read_wav src/read_wav.cpp ${BIT_IO_SRC} ${BIT_IO_INC} ${WAVE_SRC} ${WAVE_INC})
add_executable (flacd src/flacd.cpp ${FLAC_DECODER_SOURCES} ${FLAC_DECODER_INCLUDES})

add_executable (flace src/flace.cpp ${FLAC_ENCODER_SOURCES} ${FLAC_ENCODER_INCLUDES})

