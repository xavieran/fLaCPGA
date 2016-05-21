`include "RAM.v"

`timescale 1ns / 100ps

`define assert(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value"); \
        end
    
module ResidualDecoderTB;

integer i;
reg clk, rst, ena, wren;
wire Done;

reg [15:0] block_size;
reg [3:0] predictor_order;
reg [3:0] partition_order;

wire signed [15:0] oData;
wire [15:0] ReadAddr, RamData, RamReadAddr;

reg [12:0] WriteAddr;
reg [15:0] SetupReadAddr;
reg [15:0] iData;

assign RamReadAddr = ena ? ReadAddr : SetupReadAddr;

ResidualDecoder DUT (
         .iClock(clk), 
         .iReset(rst), 
         .iEnable(ena),
         .iBlockSize(block_size),
         .iPredictorOrder(predictor_order),
         .iPartitionOrder(partition_order),
         
         .iStartBit(5'd9),
         .iStartAddr(SetupReadAddr + 1'b1),
         
         .oResidual(oData),
         .oDone(Done),
         
         /* RAM I/O */
         .iData(RamData),
         .oReadAddr(ReadAddr)
         );

RAM ram (.clock(clk),
      .data(iData),
      .rdaddress(RamReadAddr),
      .wraddress(WriteAddr),
      .wren(wren),
      .q(RamData));

    always begin
        #10 clk = !clk;
    end
    
    integer samples_read;
    integer file;
    reg [7:0] hi, lo;
    

    initial begin
        /* Read the memory into the RAM */
        clk = 0; wren = 0; rst = 1; ena = 0; 
        SetupReadAddr = 0;
        file = $fopen("residual.bin", "rb");
        
        
        for (i = 0; i < 5775; i = i + 1) begin
            WriteAddr = i;
            hi = $fgetc(file);
            lo = $fgetc(file);
            iData = {hi[7:0], lo[7:0]};
            wren = 1;
            #20;
        end
        $fclose(file);
        file = $fopen("decoded_residuals_v.txt", "w");
        iData = 0;
        samples_read = 0;
        /* Now run the residual decoder */
        wren = 0;
        #20;
        predictor_order = 0; partition_order = RamData[13:10]; block_size = 15'd4096;

        #50 rst = 0; ena = 1;
    end
    
    always @(posedge clk) begin
        if (Done) begin
            $display ("%d", oData);
            $fwrite(file, "%d\n", oData);
            samples_read <= samples_read + 1;
        end
        
        //if (samples_read == 16*4) $stop;
        if (samples_read == block_size) begin
            $fclose(file);
            $stop;
        end
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
