`include "RAM.v"
`include "dual_port_ram.v"
//`include "SubframeDecoder.v"

`timescale 1ns / 100ps

`define assert(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value"); \
        end
    
module FrameDecoderTB;

integer i;
reg clk, rst, ena, wren;
wire done, frame_done, bad_frame;

wire signed [15:0] oData;
wire [15:0] rdaddr, RamData;

reg [15:0] WriteAddr;
reg [15:0] iData;

reg[15:0] memory [0:4096];

FrameDecoder DUT (.iClock(clk),
                     .iReset(rst),
                     .iEnable(ena),
                     .iUpperBits(1'b1),
                     .oFrameDone(frame_done),
                     .oSampleValid(done),
                     .oSample(oData),
                     .oBadFrame(bad_frame),
                     
                     /* RAM I/O */
                     .iStartAddress(16'd0),
                     .iData(RamData),
                     .oReadAddr(rdaddr)
                     );

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
        file = $fopen("fixed_o4f.frame", "rb");
        for (i = 0; i < 16000; i = i + 1) begin
            WriteAddr = i;
            hi = $fgetc(file);
            lo = $fgetc(file);
            iData = {hi[7:0], lo[7:0]};
            wren = 1;
            #20;
        end
        $fclose(file);
        file = $fopen("decoded_fixed_o4f.txt", "w");
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
