module ResidualEncoder (
    input iClk,
    input iEnable,
    input iReset,
    input signed [15:0] iSample, 
    output [15:0] oBitStream,
    output oDone);
/* 
 * Each clock cycle, one sample will be encoded and placed into the bit stream buffer.
 * when the buffer is full, it will be placed in oBitStream and the oDone flag will go high
 * for 1 cycle.
 *
 */

/* Problem: 
 * You get a large number, e.g. 50 and a rice parameter of 0. This means you need to fill
 * 50/16 = 4 16 bit buffers.
 * Solution: 
 * Instead this module interfaces directly with a zeroed RAM, and can simply
 * skip the first 3 16 bit numbers before writing its buffer.
 */
 
 endmodule