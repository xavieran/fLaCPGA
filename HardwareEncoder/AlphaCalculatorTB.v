`timescale 1ns/100ps
`define MY_SIMULATION 1

module AlphaCalculatorTB;

reg clk, ena, rst;
integer i;
integer cycles;

reg signed [31:0] model1, model2, acf1, acf2;

wire signed [31:0] alpha;
wire done;
reg valid;

AlphaCalculator a (
    .iClock(clk),
    .iEnable(ena), 
    .iReset(rst),
    
    .iValid(valid),
    .iACF1(acf1),
    .iACF2(acf2),
    .iModel1(model1),
    .iModel2(model2),
    
    .oAlpha(alpha),
    .oDone(done)
    );

always begin
    #0 clk = 0;
    #10 clk = 1;
    #10 cycles = cycles + 1;
end

initial begin
    cycles = 0;
    rst = 1; ena = 0;
    #30 
    
    rst = 0; ena = 1;
    acf1 = 32'hbf000000;// -.5
    acf2 = 32'h3f000000; // .5
    model1 = 32'h40000000;// 2
    model2 = 32'h40800000; // 4
    valid = 1; // 2
    
    for (i = 0; i < 1; i = i + 1) #20; // 6 input cycles
    
    valid = 0;
    for (i = 0; i < 100; i = i + 1) begin
        if (done == 1) begin
            $display("cycle: %d A: %f", cycles, $bitstoshortreal(alpha));
            $stop;
        end
        #20 ;
    end
    
    $stop;
end

endmodule