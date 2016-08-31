`timescale 1ns/100ps
`define MY_SIMULATION 1

module CalculateKAndErrorTB;

reg clk, ena, rst;
integer i;
integer cycles;
reg [31:0] alpham, errorm;

wire [31:0] kmp1, errormp1;
wire done;

CalculateKAndError ckae(
    .iClock(clk),
    .iEnable(ena), 
    .iReset(rst),
    
    .iAlpham(alpham),
    .iErrorm(errorm), // E_m
    
    .oKmp1(kmp1), // K_m+1
    .oErrormp1(errormp1),// E_m+1
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
    alpham = 32'h3ca3d70a; // .02
    errorm = 32'h3f666666; // .9
    #20; 
    
    ena = 1; rst = 0;
    
    for (i = 0; i < 200; i = i + 1) begin
        if (done) begin
            $display("cycles: %d kmp1: %f emp1: %f", cycles,$bitstoshortreal(kmp1),$bitstoshortreal(errormp1));
            $stop;
        end
        #20 ;
    end
    $stop;
    
end

endmodule