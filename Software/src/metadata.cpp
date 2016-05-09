/***************************************************/
/******** Classes for storing FLAC metadata *******/
/*************************************************/

#ifndef FLAC_METADATA_C
#define FLAC_METADATA_C

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <vector>

#include "bitreader.hpp"
#include "bitwriter.hpp"
#include "metadata.hpp"

/********************************************/
/******* Holds all Metadata ****************/
/******************************************/

FLACMetaData::FLACMetaData(){
    _metadata = new std::vector<FLACMetaDataBlock *>();
}

void FLACMetaData::print(FILE *f){
    std::vector<FLACMetaDataBlock *>::iterator it;
    for(it = _metadata->begin(); it < _metadata->end(); it++){
        (*it)->print(f);
    }
}

int FLACMetaData::read(std::shared_ptr<BitReader> fr){
    uint8_t buffer[READSIZE * 2 * 2];
    
    FLACMetaStreamInfo *s = new FLACMetaStreamInfo();
    FLACMetaDataBlock *temp = (FLACMetaDataBlock *) s;
    
    fr->read_chunk(buffer, 4);
    if (memcmp(buffer, "fLaC", 4)) fr->read_error();
    
    s->read(fr);
    
    _streaminfo = s;
    
    if (!temp->getHeader()->isLast()){
        do {
            temp = new FLACMetaBlockOther();
            temp->read(fr);
            this->addBlock(temp);
        } while  (!temp->getHeader()->isLast());
    }
    
    return true; /* FIXME: Error checking... */
}

int FLACMetaData::addBlock(FLACMetaDataBlock *b){
    _metadata->push_back(b);
    return 1;
}

/************ Metablock header **************/

FLACMetaBlockHeader::FLACMetaBlockHeader(){
    _lastBlock = 0;
    _blockType = 0;
    _blockLength = 0;
}

int FLACMetaBlockHeader::read(std::shared_ptr<BitReader> fr){
    fr->read_bits(&_lastBlock, 1);
    fr->read_bits(&_blockType, 7);
    fr->read_bits(&_blockLength, 24);
    
    return 1; // Add error handling
}

void FLACMetaBlockHeader::print(FILE *f){
    fprintf(f,\
"Type: %d\n\
Length: %d\n\
Last Block? %d\n\n", _blockType, _blockLength, _lastBlock);
}

int FLACMetaBlockHeader::write(FILE *f){
    return 1;
}

int FLACMetaBlockHeader::isLast(){
    return _lastBlock;
}

int FLACMetaBlockHeader::getBlockType(){
    return _blockType;
}

int FLACMetaBlockHeader::getBlockLength(){
    return _blockLength;
}


/********************************************/
/************** STREAMINFO *******************/
/********************************************/

FLACMetaStreamInfo::FLACMetaStreamInfo(){
    uint16_t minBlockSize = 0;
    uint16_t maxBlockSize = 0;
    uint32_t minFrameSize = 0;
    uint32_t maxFrameSize = 0;
    uint32_t sampleRate = 0;
    uint8_t numChannels = 0;
    uint8_t bitsPerSample = 0;
    uint64_t totalSamples = 0;
    uint64_t MD5u = 0;
    uint64_t MD5l = 0;
}

void FLACMetaStreamInfo::print(FILE* f){
    this->getHeader()->print(f);
    fprintf(f, "\
    minBlockSize: %d\n\
    maxBlockSize: %d\n\
    minFrameSize: %d\n\
    maxFrameSize: %d\n\
    sampleRate: %d\n\
    numChannels: %d\n\
    bitsPerSample: %d\n\
    totalSamples: %ld\n\n",
    _minBlockSize, _maxBlockSize, _minFrameSize, _maxFrameSize,\
    _sampleRate, _numChannels, _bitsPerSample, _totalSamples);
}


int FLACMetaStreamInfo::read(std::shared_ptr<BitReader> fr){
    /* Read a streaminfo block */
    this->setHeader(new FLACMetaBlockHeader());
    this->getHeader()->read(fr);
    fr->read_bits(&_minBlockSize, 16);
    fr->read_bits(&_maxBlockSize, 16);
    fr->read_bits(&_minFrameSize, 24);
    fr->read_bits(&_maxFrameSize, 24);
    fr->read_bits(&_sampleRate, 20);
    fr->read_bits(&_numChannels, 3);
    _numChannels++;
    fr->read_bits(&_bitsPerSample, 5);
    _bitsPerSample++;
    fr->read_bits(&_totalSamples, 36);
    fr->read_bits(&_MD5u, 64);
    fr->read_bits(&_MD5l, 64);
    
    //_bitsPerSample += 1;
    // Add error handling
    return 1;
}

uint64_t FLACMetaStreamInfo::getTotalSamples(){
    return _totalSamples;
}

uint8_t FLACMetaStreamInfo::getNumChannels(){
    return _numChannels;
}

uint16_t FLACMetaStreamInfo::getMaxBlockSize(){
    return _maxBlockSize;
}

void FLACMetaStreamInfo::setTotalSamples(uint64_t samples){
    _totalSamples = samples;
}

bool FLACMetaStreamInfo::write(std::shared_ptr<BitWriter> bw){
    bw->write_bits(0x66, 8); // f
    bw->write_bits(0x4c, 8); // L
    bw->write_bits(0x61, 8); // a
    bw->write_bits(0x43, 8); // C
    
    /* Metadata header */
    bw->write_bits(1, 1); // Last block before audio starts
    bw->write_bits(0, 7); // STREAMINFO block
    bw->write_bits(34, 24); // 34 bytes to follow
    
    /* STREAMINFO Block */
    bw->write_bits(4096, 16);
    bw->write_bits(4096, 16);
    bw->write_bits(0, 24); // Unknown
    bw->write_bits(0, 24); // Unknown
    bw->write_bits(44100, 20); // 44.1kHz
    bw->write_bits(0, 3); // Stick with 1 channel for now
    bw->write_bits(15, 5); // 16 - 1 = 15
    //bw->write_bits(_totalSamples, 36); // Unknown for now
    
    /* should not have to split up these writes... oh well */
    bw->write_bits((_totalSamples & 0xf00000000) >> 32, 4);
    bw->write_bits((_totalSamples & 0xffff0000) >> 16, 16);
    bw->write_bits(_totalSamples & 0xffff, 16);
    
    bw->write_bits(0, 64); // Ignore MD5
    bw->write_bits(0, 64); 
    
    return true;
}



/****************************************************/
/************** OTHER METABLOCKS *******************/
/**************************************************/


FLACMetaBlockOther::FLACMetaBlockOther(){
    ;
}

int FLACMetaBlockOther::read(std::shared_ptr<BitReader> fr){
    FLACMetaBlockHeader * h = new FLACMetaBlockHeader();
    this->setHeader(h);
    this->getHeader()->read(fr);
    _data = (uint8_t *)malloc(sizeof(uint8_t) * h->getBlockLength());
    fr->read_chunk(_data, h->getBlockLength());
    // Add error handling
    return 1;
}

void FLACMetaBlockOther::print(FILE *f){
    this->getHeader()->print(f);
}

FLACMetaStreamInfo * FLACMetaData::getStreamInfo(){
    return _streaminfo;
}

#endif
