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
#include "metadata.hpp"

/************ Metablock header **************/

FLACMetaBlockHeader::FLACMetaBlockHeader(){
    this->lastBlock = 0;
    this->blockType = 0;
    this->blockLength = 0;
}

int FLACMetaBlockHeader::read(FileReader *fr){
    fr->read_bits_uint8(&this->lastBlock, 1);
    fr->read_bits_uint8(&this->blockType, 7);
    fr->read_bits_uint32(&this->blockLength, 24);
    return 1; // Add error handling
}

void FLACMetaBlockHeader::print(FILE *f){
    fprintf(f,\
"Type: %d\n\
Length: %d\n\
Last Block? %d\n\n", this->blockType, this->blockLength, this->lastBlock);
}

int FLACMetaBlockHeader::write(FILE *f){
    return 1;
}

int FLACMetaBlockHeader::isLast(){
    return this->lastBlock;
}

int FLACMetaBlockHeader::getBlockType(){
    return this->blockType;
}

int FLACMetaBlockHeader::getBlockLength(){
    return this->blockLength;
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
    this->minBlockSize, this->maxBlockSize, this->minFrameSize, this->maxFrameSize,\
    this->sampleRate, this->numChannels, this->bitsPerSample, this->totalSamples);
}


int FLACMetaStreamInfo::read(struct FileReader *fr){
    /* Read a streaminfo block */
    this->setHeader(new FLACMetaBlockHeader());
    this->getHeader()->read(fr);
    fr->read_bits_uint16(&this->minBlockSize, 16);
    fr->read_bits_uint16(&this->maxBlockSize, 16);
    fr->read_bits_uint32(&this->minFrameSize, 24);
    fr->read_bits_uint32(&this->maxFrameSize, 24);
    fr->read_bits_uint32(&this->sampleRate, 20);
    fr->read_bits_uint8(&this->numChannels, 3);
    this->numChannels++;
    fr->read_bits_uint8(&this->bitsPerSample, 5);
    this->bitsPerSample++;
    fr->read_bits_uint64(&this->totalSamples, 36);
    fr->read_bits_uint64(&this->MD5u, 64);
    fr->read_bits_uint64(&this->MD5l, 64);
    
    //this->bitsPerSample += 1;
    // Add error handling
    return 1;
}

uint64_t FLACMetaStreamInfo::getTotalSamples(){
    return this->totalSamples;
}
/****************************************************/
/************** OTHER METABLOCKS *******************/
/**************************************************/


FLACMetaBlockOther::FLACMetaBlockOther(){
    ;
}

int FLACMetaBlockOther::read(FileReader *fr){
    FLACMetaBlockHeader * h = new FLACMetaBlockHeader();
    this->setHeader(h);
    this->getHeader()->read(fr);
    this->data = (uint8_t *)malloc(sizeof(uint8_t) * h->getBlockLength());
    fr->read_file(this->data, 1, h->getBlockLength());
    // Add error handling
    return 1;
}

void FLACMetaBlockOther::print(FILE *f){
    this->getHeader()->print(f);
}



/********************************************/
/******* Holds all Metadata ****************/
/******************************************/

FLACMetaData::FLACMetaData(){
    this->metadata = new std::vector<FLACMetaDataBlock *>();
}

void FLACMetaData::print(FILE *f){
    std::vector<FLACMetaDataBlock *>::iterator it;
    for(it = this->metadata->begin(); it < this->metadata->end(); it++){
        (*it)->print(f);
    }
}

int FLACMetaData::read(FileReader *fr){
    uint8_t buffer[READSIZE * 2 * 2];
    
    FLACMetaStreamInfo *s = new FLACMetaStreamInfo();
    FLACMetaDataBlock *temp = (FLACMetaDataBlock *) s;
    
    fr->read_file(buffer, 1, 4);
    if (memcmp(buffer, "fLaC", 4)) fr->read_error();
    
    s->read(fr);
    
    this->streaminfo = s;
    
    if (!temp->getHeader()->isLast()){
        do {
            temp = new FLACMetaBlockOther();
            temp->read(fr);
            this->addBlock(temp);
        } while  (!temp->getHeader()->isLast());
    }
}

int FLACMetaData::addBlock(FLACMetaDataBlock *b){
    this->metadata->push_back(b);
    return 1;
}

FLACMetaStreamInfo * FLACMetaData::getStreamInfo(){
    return this->streaminfo;
}

#endif
