`timescale 1ns/100ps
`define MY_SIMULATION 1

module RiceWriterTB;

reg clk, ena, rst;
integer i;
integer cycles;

reg [15:0] upper, lower;
reg [3:0] param;

wire [15:0] total = upper + param + 1;

wire ram_en1;
wire [15:0] ram_ad1, ram_dat1;
wire ram_en2;
wire [15:0] ram_ad2, ram_dat2;

RiceWriter rw (
    .iClock(clk),
    .iReset(rst), 
    .iEnable(ena), 
    
    .iTotal(total),
    .iUpper(upper),
    .iLower(lower), 
    .iRiceParam(param),
    
    .oRamEnable1(ram_en1),
    .oRamAddress1(ram_ad1), 
    .oRamData1(ram_dat1),
    
    .oRamEnable2(ram_en2),
    .oRamAddress2(ram_ad2), 
    .oRamData2(ram_dat2)
    );


always begin
    #0 clk = 0;
    #10 clk = 1;
    #10 cycles = cycles + 1;
end

initial begin
    cycles = 0;
    rst = 1; ena = 0; lower = 0; upper = 0;
    #30
    param = 4;
    
    rst = 0; ena = 1;
    
    upper = 4; lower = 5'b11011;
    #20;
    upper = 2; lower = 5'b10011;
    #20;
    upper = 12; lower = 5'b11001;
    #20;
    upper = 22; lower = 5'b11011;
    #20;
    upper = 33; lower = 5'b10001;
    #20;
    upper = 10; lower = 5'b11101;
    #20;
    /*
    #20;
    lower = 5'b11100;
    upper = 5;    
    #20;
    lower = 5'b10011;
    upper = 3;
    #20;
    lower = 5'b11001;
    upper = 0;
    #20;
    upper = 10;
    lower = 5'b11101;
    #20;
    upper = 4; 
    lower = 5'b10111;
    #20;
    */
    $stop;
end

endmodule