cmake_minimum_required(VERSION 2.8)
project( MyFlacDecoder )

include_directories(includes)

set(HEADER_FILES src/read_write.c includes/read_write.h)
add_executable (read_wav src/read_wav.c ${HEADER_FILES})
add_executable (read_flac src/read_flac.c ${HEADER_FILES})
