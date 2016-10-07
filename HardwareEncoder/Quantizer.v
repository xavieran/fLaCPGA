`default_nettype none

`ifndef QUANTIZER_H
`define QUANTIZER_H

`include "int_convert.v"

module Quantizer (
    input wire iClock,
    input wire iEnable,
    input wire iReset,
    
    input wire [3:0] iM,
    input wire iValid,
    input wire [31:0] iFloatCoeff,
    output wire signed [14:0] oQuantizedCoeff,
    output wire oValid,
    output wire [3:0] oM
    );

/* Whilst FLAC supports variable precision and quantization, to keep life simple
 * I will choose a fixed quantization. Coefficients' precision will be sixteen and
 * the shift will be 10. This is based on a histogram of a large WAV file and the 
 * shift that FLAC chose most often. 
 */
   
integer i;

parameter PRECISION = 15;
parameter SHIFT = 10;

parameter MULT_LATENCY = 5;
parameter CONV_LATENCY = 7;
parameter TOTAL_LATENCY = MULT_LATENCY + CONV_LATENCY - 1;

wire signed [31:0] m1_out;
reg [TOTAL_LATENCY:0] valid;

reg [3:0] delayed_m [0:TOTAL_LATENCY];

assign oM = delayed_m[TOTAL_LATENCY];
assign oValid = valid[TOTAL_LATENCY];

reg [31:0] fp_in;

fp_mult m1 (
    .clk_en(iEnable), 
    .clock(iClock),
    .dataa(fp_in),
    .datab(32'hc4800000), // -1024 in floating point... 10
    //.datab(32'hc2800000), // -64 in floating point... 6 
    .nan(),
    .result(m1_out));

int_convert conv1(
    .clk_en(iEnable), 
    .clock(iClock),
    .dataa(m1_out),
    .result(oQuantizedCoeff));

always @(posedge iClock) begin
    if (iReset) begin
        valid <= 0;
    end else begin
        fp_in <= iFloatCoeff;
    
        if (iEnable) begin
            for (i = TOTAL_LATENCY; i > 0; i = i - 1) begin
                delayed_m[i] <= delayed_m[i - 1];
            end
            delayed_m[0] <= iM;
            
            valid <= (valid << 1) | iValid;
        end
    end
end
    
endmodule
    
`endif