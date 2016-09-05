`timescale 1ns/100ps
`define MY_SIMULATION 1

module DurbinatorTB;

reg clk, ena, rst;
integer i;
integer cycles;

wire [31:0] alpha, k, error;
wire done;
reg [31:0] acf;

Durbinator db(
    .iClock(clk),
    .iEnable(ena), 
    .iReset(rst),
    
    .iACF(acf),
    .alpha(alpha),
    .error(error),
    .k(k),
    .oDone(done)
    );

always begin
    #0 clk = 0;
    #10 clk = 1;
    #10 cycles = cycles + 1;
end

initial begin
    cycles = 0;
    ena = 0; rst = 1;
    #30;
    #20;    
    
    ena = 1; rst = 0;
    acf = 32'h0x3f800000;
    #20;
    acf = 32'h0x3f7f7bb8;
    #20;
    acf = 32'h0x3f7e0430;
    #20;
    acf = 32'h0x3f7b9f88;
    #20;
    acf = 32'h0x3f784f5a;
    #20;
    acf = 32'h0x3f742267;
    #20;
    acf = 32'h0x3f6f2663;
    #20;
    acf = 32'h0x3f696ae8;
    #20;
    acf = 32'h0x3f63029e;
    #20;
    acf = 32'h0x3f5bfe6b;
    #20;
    acf = 32'h0x3f54715b;
    #20;
    acf = 32'h0x3f4c6cdf;
    #20;
    acf = 32'h0x3f4401d3;
    #20;


    
    for (i = 0; i < 1200; i = i + 1) #20;
    
    $stop;
    
end

endmodule