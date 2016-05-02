`include "RAM.v"

`timescale 1ns / 1ns

`define assert(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value"); \
        end
    
module SubframeDecoderTB;

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

SubframeDecoder DUT (.iClock(clk),
                     .iReset(rst),
                     .iEnable(ena),
                     .iNSamples(4096),
                     .oDone(done),
                     .oSample(oData),
                     
                     /* RAM I/O */
                     .iData(RamData),
                     .oReadAddr(rdaddr)
                     );

RAM ram (.clock(clk),
         .data(iData),
         .rdaddress(rdaddr),
         .wraddress(wraddr),
         .wren(wren),
         .q(RamData)
         );

    always begin
        #10 clk = !clk;
    end
    
    integer samples_read;
    
    always @(posedge clk) begin
        if (done) begin
            $display ("%d", oData);
            samples_read <= samples_read + 1;
        end
        if (samples_read == 16*4) $stop;
    end
    
    initial begin
        /* Read the memory into the RAM */
        clk = 0; wren = 0; rst = 1; ena = 0;
        $readmemh("fixed_subframe.rmh", memory);
        //$readmemh("residual.rmh", memory);
        
        for (i = 0; i < 4096; i = i + 1) begin
            wraddr = i;
            iData = memory[i];
            wren = 1;
            #20;
        end
        iData = 0;
        samples_read = 0;
        /* Now run the residual decoder */
        wren = 0;
        #20;
        n = 4096; pred_o = 0;
        #40 rst = 0; ena = 1;
        

    end
    
endmodule
