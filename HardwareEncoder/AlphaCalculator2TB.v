`timescale 1ns/100ps
`define MY_SIMULATION 1

module AlphaCalculator2TB;

reg clk, ena, rst;
integer i;
integer cycles;

reg signed [31:0] model1, model2, acf1, acf2;
reg [3:0] m;
wire signed [31:0] alpha;
wire done;
reg valid;

AlphaCalculator2 ac (
    .iClock(clk),
    .iEnable(ena), 
    .iReset(rst),
    
    .iM(m),
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
    
    acf2 = 32'h3f000000; // .5
    model1 = 32'h40000000;// 2
    
    acf1 = 32'h3f000000;// .5
    model2 = 32'h40000000;// 2
    
    valid = 1; // 2
    m =11;
    for (i = 0; i < 6; i = i + 1) #20; // 6 input cycles
    
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