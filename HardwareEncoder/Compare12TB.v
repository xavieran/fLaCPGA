`timescale 1ns/100ps
`define MY_SIMULATION 1

`define DFP(X) $bitstoshortreal(X)
module Compare12TB;

reg clk, ena, rst;
integer i;
integer cycles;

reg [31:0] in0, in1, in2, in3, in4, in5, in6, in7, in8, in9, in10, in11;
wire [3:0] min;

Compare12 c12 (
    .iClock(clk),
    .iEnable(ena),
    .iIn0(in0),
    .iIn1(in1),
    .iIn2(in2),
    .iIn3(in3),
    .iIn4(in4),
    .iIn5(in5),
    .iIn6(in6),
    .iIn7(in7),
    .iIn8(in8),
    .iIn9(in9),
    .iIn10(in10),
    .iIn11(in11),
    .oMinimum(min)
    );

always begin
    #0 clk = 0;
    #10 clk = 1;
    #10 cycles = cycles + 1;
end


initial begin
    cycles = 0;
    ena = 0;
    in0 = 2000;
    in1 = 120;
    in2 = 30;
    in3 = 10000;
    in4 = 50;
    in5 = 12;
    in6 = 912;
    in7 = 56;
    in8 = 5128;
    in9= 12002;
    in10 = 2002;
    in11 = 50;
    #30;
    #20;    

    ena = 1;
    
    for (i = 0; i < 20; i = i + 1) #20;
    
    $display("Minimum: %d", min);
    
    $stop;
    
end

endmodule