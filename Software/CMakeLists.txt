cmake_minimum_required(VERSION 3.5)
project( fLaCPGA )

find_package(CUDA REQUIRED)

list(APPEND CUDA_NVCC_FLAGS "-std=c++11;-O2;-DVERBOSE")
SET(CUDA_PROPAGATE_HOST_FLAGS OFF)

add_subdirectory(gtest)
include_directories(gtest/include)

include_directories(includes)
include_directories(src)
set(LOGURU
    includes/loguru.hpp)

set(BIT_IO_SRC 
    src/BitReader.cpp 
    src/BitWriter.cpp 
    src/CRC.cpp )

set(BIT_IO_INC 
    includes/BitReader.hpp
    src/BitReader.tpp
    includes/BitWriter.hpp 
    src/BitWriter.tpp
    includes/CRC.hpp )

set(WAVE_SRC src/WaveReader.cpp)
set(WAVE_INC includes/WaveReader.hpp)

set(FLAC_DECODER_SOURCES  
    src/Frames.cpp 
    src/SubFrames.cpp
    src/Metadata.cpp
    src/FLACDecoder.cpp  
    src/WaveReader.cpp 
    ${BIT_IO_SRC})

set(FLAC_DECODER_INCLUDES  
    includes/Frames.hpp 
    includes/SubFrames.hpp
    includes/Metadata.hpp 
    includes/FLACDecoder.hpp 
    includes/WaveReader.hpp 
    ${BIT_IO_INC})

set(FLAC_ENCODER_SOURCES 
    ${FLAC_DECODER_SOURCES} 
    src/FLACEncoder.cpp 
    src/RiceEncoder.cpp 
    src/FixedEncoder.cpp)

set(FLAC_ENCODER_INCLUDES 
    ${FLAC_DECODER_INCLUDES} 
    ${LOGURU}
    includes/FLACEncoder.hpp 
    includes/RiceEncoder.hpp 
    includes/FixedEncoder.hpp)

set(CMAKE_CXX_FLAGS "-g -fstack-protector-all  -Og -std=c++14 -Wall -Wno-unused-variable -Wno-switch")

#-static

# Tests
#add_executable (bitreader_test tests/bitreader_test.cpp ${BIT_IO_SRC} ${BIT_IO_INC})
#target_link_libraries(bitreader_test gtest rt pthread)
# add_executable (../tests/bitwriter_test ../tests/bitwriter_test.cpp  ${BIT_IO_SRC} ${BIT_IO_INC})
# target_link_libraries(../tests/bitwriter_test gtest rt pthread)
# add_executable (../tests/riceencoder_test ../tests/riceencoder_test.cpp  ${BIT_IO_SRC} src/riceencoder.cpp ${BIT_IO_INC} includes/riceencoder.hpp)
# target_link_libraries(../tests/riceencoder_test gtest rt pthread)
# add_executable (../tests/fixedencoder_test ../tests/fixedencoder_test.cpp  ${BIT_IO_SRC} src/fixedencoder.cpp ${BIT_IO_INC} includes/fixedencoder.hpp)
# target_link_libraries(../tests/fixedencoder_test gtest rt pthread)
# add_executable (../tests/lpcencoder_test ../tests/lpcencoder_test.cpp  ${BIT_IO_SRC} src/lpcencoder.cpp ${BIT_IO_INC} includes/lpcencoder.hpp)
# target_link_libraries(../tests/lpcencoder_test gtest rt pthread)
# add_executable (../tests/encoder_test ../tests/encoder_test.cpp  ${BIT_IO_SRC} ${BIT_IO_INC} ${FLAC_ENCODER_SOURCES} ${FLAC_ENCODER_INCLUDES})
# target_link_libraries(../tests/encoder_test gtest rt pthread)
# 
# #add_executable (../tests/crc_test ../tests/crc_test.cpp  ${BIT_IO_SRC} src/crc.cpp ${BIT_IO_INC} includes/crc.hpp)
# #target_link_libraries(../tests/crc gtest rt pthread)
# 
# add_executable (../tests/read_residual ../tests/read_residual.cpp  ${BIT_IO_SRC} ${BIT_IO_INC})
# target_link_libraries(../tests/read_residual)
# 
# add_executable (../tests/generate_residual ../tests/generate_residual.cpp  ${BIT_IO_SRC} src/riceencoder.cpp ${BIT_IO_INC} includes/riceencoder.hpp)
# target_link_libraries(../tests/generate_residual)


 
 add_executable (read_wav src/read_wav.cpp ${BIT_IO_SRC} ${BIT_IO_INC} ${WAVE_SRC} ${WAVE_INC})
 target_link_libraries(read_wav dl pthread)

 add_executable (flacd src/flacd.cpp ${FLAC_DECODER_SOURCES} ${FLAC_DECODER_INCLUDES})
 target_link_libraries(flacd dl pthread)

 add_executable (flace src/flace.cpp src/loguru.cpp ${FLAC_ENCODER_SOURCES} ${FLAC_ENCODER_INCLUDES})
 target_link_libraries(flace dl pthread)

 #CUDA_ADD_EXECUTABLE(cuda_flac src/cuda_flac.cu src/kernels.cu ${FLAC_DECODER_SOURCES} ${FLAC_DECODER_INCLUDES})
