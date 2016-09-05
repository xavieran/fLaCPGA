`timescale 1ns/100ps
`define MY_SIMULATION 1

module register_fileTB;

reg clk;
integer i;
integer cycles;

reg [31:0] in_data1, in_data2;
reg [3:0] in_wa1, in_wa2, in_ra1, in_ra2;
reg we1, we2;
wire [31:0] data1, data2;

register_file rf (
    .iClock(clk),
    .iData1(in_data1),
    .iData2(in_data2), 
    .iWriteAddress1(in_wa1),
    .iWriteAddress2(in_wa2),
    .iReadAddress1(in_ra1), 
    .iReadAddress2(in_ra1),
    .iWE1(we1),
    .iWE2(we2),
    .oData1(data1), 
    .oData2(data2)
    );

always begin
    #0 clk = 0;
    #10 clk = 1;
    #10 cycles = cycles + 1;
end

initial begin
    in_data1 = 0;
    in_data2 = 0;
    we1 = 0; we2 = 0;
    in_ra1 = 0;
    in_ra2 = 0;
    in_wa1 = 0;
    in_wa2 = 0;
    
    cycles = 0;
    #30;
    #20;    
    
    for (i = 0; i < 16; i = i + 1) begin
        in_data1 = i*20;
        we1 = 1;
        in_wa1 = i;
        #20;
    end
    
    we1 = 0;
    
    for (i = 0;i < 16; i = i + 1) begin
        in_ra1 = i;
        #20;
        $display("data @%d %d", i, data1);
    end
    
    $stop;
    
end

endmodule