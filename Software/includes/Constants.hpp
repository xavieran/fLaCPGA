/**********************************
 * FLAC constants and magic numbers *
 **********************************/

#pragma once

enum FLAC_const {
    CH_INDEPENDENT,
    CH_LEFT,
    CH_RIGHT,
    CH_MID,
    CH_INVALID,

    SUB_CONSTANT,
    SUB_VERBATIM,
    SUB_FIXED,
    SUB_LPC,
    SUB_INVALID,

    FRAME_SYNC = 0x3ffe
};
