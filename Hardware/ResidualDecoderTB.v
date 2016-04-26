`include "RAM.v"

`timescale 1ns / 1ns

`define assert(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value"); \
        end
    
module ResidualDecoderTB;

integer i;
reg clk, rst, ena, wren;
wire done;

reg [15:0] n;
reg [3:0] pred_o;

wire signed [15:0] oData;
wire [15:0] rdaddr, RamData;

reg [12:0] wraddr;
reg [15:0] iData;

reg[15:0] memory [0:4096];

ResidualDecoder DUT (
         .iClock(clk),
         .iReset(rst),
         .iEnable(ena),
         .iNSamples(n),
         .iPredOrder(pred_o),
         .oResidual(oData),
         .oDone(done),
         
         .iData(RamData),
         .oReadAddr(rdaddr)
         );

RAM ram (.clock(clk),
      .data(iData),
      .rdaddress(rdaddr),
      .wraddress(wraddr),
      .wren(wren),
      .q(RamData));

    always begin
        #10 clk = !clk;
    end
    
    always @(posedge clk) begin
        if (done) begin
            $display ("%d", oData);
        end
    end
    
    initial begin
        /* Read the memory into the RAM */
        clk = 0; wren = 0; rst = 1; ena = 0;
        $readmemh("residual.rmh", memory);
        
        for (i = 0; i < 4096; i = i + 1) begin
            wraddr = i;
            iData = memory[i];
            wren = 1;
            #20;
        end
        iData = 0;
        /* Now run the residual decoder */
        wren = 0;
        #20;
        n = 4096; pred_o = 0;
        #40 rst = 0; ena = 1;
        #4000;
        //#4000 $stop;

    end
    
/* 29A5                 E46F                 3FB0                 BE7D                    
 * 0010 1001 1010 0101  1110 0100 0110 1111  0011 1111 1011 0000  1011 1110 0111 1101
 * ccpp pprr rrml llll  lmll llll mmll llll  mmml llll lrrr rmmm  mlll lllm mmll llll
 *      10    6|        ||    |    |      |   |    |
 *             0       11|    |    1     47   2   15
 *             |         0   36    |          |
 *             |         |         |          |
 *            -6         18       -56        -96
 */
endmodule
