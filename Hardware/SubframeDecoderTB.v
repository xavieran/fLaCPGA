`include "RAM.v"
`include "dual_port_ram.v"

`timescale 1ns / 100ps

`define assert(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value"); \
        end
    
module SubframeDecoderTB;

integer i;
reg clk, rst, ena, wren;
wire done, frame_done;
wire [3:0] curr_bit;
wire signed [15:0] oData;
wire [15:0] rdaddr, RamData;

reg [15:0] WriteAddr;
reg [15:0] iData;

reg[15:0] memory [0:4096];

SubframeDecoder DUT (.iClock(clk),
                     .iReset(rst),
                     .iEnable(ena),
                     .iUpperBits(1'b1),
                     .oFrameDone(frame_done),
                     .oSampleValid(done),
                     .oSample(oData),
                     
                     /* RAM I/O */
                     .iBlockSize(16'd4096),
                     .iStartAddress(16'd3),
                     .iData(RamData),
                     .oReadAddr(rdaddr),
                     .oCurrBit(curr_bit)
                     );
/*
RAM ram (.clock(clk),
         .data(iData),
         .rdaddress(rdaddr),
         .wraddress(WriteAddr),
         .wren(wren),
         .q(RamData)
         );
*/
dual_port_ram ram(.clk(clk), 
                  .data(iData),
                  .read_addr(rdaddr), 
                  .write_addr(WriteAddr),
                  .we(wren), 
                  .q(RamData));

    always begin
        #10 clk = !clk;
    end
    
    integer samples_read, file;
    reg [7:0] hi, lo;
    
    initial begin
        /* Read the memory into the RAM */
        clk = 0; wren = 0; rst = 1; ena = 0;
        /* Read the memory into the RAM */
        file = $fopen("fixed_ovf.frame", "rb");
        for (i = 0; i < 16000; i = i + 1) begin
            WriteAddr = i;
            hi = $fgetc(file);
            lo = $fgetc(file);
            iData = {hi[7:0], lo[7:0]};
            wren = 1;
            #20;
        end
        $fclose(file);
        file = $fopen("decoded_fixed_ovf.txt", "w");
        samples_read = 0;
        /* Now run the residual decoder */
        wren = 0;
        #20;
        #50 rst = 0; ena = 1;
    end
    
    always @(posedge clk) begin
        if (done) begin
            $display ("%d", oData);
            $fwrite(file, "%d\n", oData);
            samples_read <= samples_read + 1;
        end
        //if (samples_read == 16*4) $stop;
        //if (samples_read == 4096) begin
        if (frame_done) begin
            $stop;
            $fclose(file);
        end
    end
    
endmodule
