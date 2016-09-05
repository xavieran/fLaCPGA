`timescale 1ns/100ps
`define MY_SIMULATION 1

`define DFP(X) $bitstoshortreal(X)
module QuantizerTB;

reg clk, ena, rst;
integer i;
integer cycles;

reg valid;
reg [31:0] coeff;
wire signed [11:0] quant;
wire q_valid;

Quantizer q(
    .iClock(clk), 
    .iEnable(ena), 
    .iReset(rst),
    .iValid(valid), 
    .iFloatCoeff(coeff), 
    .oQuantizedCoeff(quant),
    .oValid(q_valid));

always begin
    #0 clk = 0;
    #10 clk = 1;
    #10 cycles = cycles + 1;
end

initial begin
    cycles = 0;
    ena = 0;rst = 1;valid=0;coeff=0;
    #30;
    #20;    
    
    ena = 1;valid = 1;rst = 0;
    coeff = 32'h0x3f800000;
    $display("%f", `DFP(coeff));
    #20;
    coeff = 32'h0x3f7f7bb8;
    $display("%f", `DFP(coeff));
    #20;
    coeff = 32'h0xbf7e0430;$display("%f", `DFP(coeff));
    #20;
    coeff = 32'h0x3f7b9f88;$display("%f",`DFP(coeff));
    #20;
    coeff = 32'h0x3f784f5a;$display("%f", `DFP(coeff));
    #20;
    coeff = 32'h0xbf742267;$display("%f", `DFP(coeff));
    #20;
    coeff = 32'h0x3f6f2663;$display("%f", `DFP(coeff));
    #20;
    coeff = 32'h0x3f696ae8;$display("%f", `DFP(coeff));
    #20;
    coeff = 32'h0x3f63029e;$display("%f", `DFP(coeff));
    #20;
    coeff = 32'h0x3f5bfe6b;$display("%f", `DFP(coeff));
    #20;
    coeff = 32'h0x3f54715b;$display("%f",`DFP(coeff));
    #20;
    coeff = 32'h0x3f4c6cdf;$display("%f", `DFP(coeff));
    #20;
    coeff = 32'h0x3f4401d3;$display("%f", `DFP(coeff));
    #20;
    valid = 0;

    for (i = 0; i < 80; i = i + 1) begin
        if (q_valid) begin
            $display("%d", quant);
        end
        #20;
    end
    
    $stop;
    
end

endmodule