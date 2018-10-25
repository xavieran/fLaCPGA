#ifndef CRC_H
#define CRC_H

#include <iostream>
#include <stdint.h>
/* CRC-8, poly = x^8 + x^2 + x^1 + x^0, init = 0 */

class FLAC_CRC {
  static uint8_t crc8_table[256];

  /* CRC-16, poly = x^16 + x^15 + x^2 + x^0, init = 0 */

  static unsigned crc16_table[256];

public:
  static void crc8_update(const uint8_t data, uint8_t *crc);

  static void crc8_update_block(const uint8_t *data, unsigned len,
                                uint8_t *crc);

  static uint8_t crc8(uint8_t *data, unsigned len);

  static unsigned crc16(const uint8_t *data, unsigned len);
};

#endif