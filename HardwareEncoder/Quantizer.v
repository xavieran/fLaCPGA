`default_nettype none


module Quantizer (
    input wire iClock,
    input wire iEnable,
    input wire iReset,
    
    input wire iValid,
    input wire [31:0] iFloatCoeff,
    output wire signed [11:0] oQuantizedCoeff,
    output wire oValid
    );

/* Whilst FLAC supports variable precision and quantization, to keep life simple
   I will choose a fixed quantization. Coefficients precision will be twelve and
   the shift will be 10. This is based on a histogram of a large WAV file and the 
   shift that FLAC chose most often. */
   
parameter PRECISION = 12;
parameter SHIFT = 10;

parameter MULT_LATENCY = 5;
parameter CONV_LATENCY = 7;
parameter TOTAL_LATENCY = MULT_LATENCY + CONV_LATENCY - 1;

wire [31:0] m1_out;
reg [TOTAL_LATENCY:0] valid;

assign oValid = valid[TOTAL_LATENCY];

fp_mult m1 (
    .clk_en(iEnable), 
    .clock(iClock),
    .dataa(iFloatCoeff),
    .datab(32'h44800000), // 1024 in floating point...
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
        if (iEnable) begin
            valid <= (valid << 1) | iValid;
        end
    end
end
    
endmodule
    