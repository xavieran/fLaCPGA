
`timescale 1ns / 1ns

`define assert(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value"); \
        end
    
module ResidualDecoderTB;

integer i;
reg clk, rst,ena,data_rdy;
wire need_data, done;

reg [15:0] data;
reg [15:0] n;
reg [3:0] pred_o;

wire signed [15:0] oData;

reg[15:0] memory [0:4096];

ResidualDecoder DUT (
         .iClock(clk),
         .iReset(rst),
         .iEnable(ena),
         .iData(data),
         .iNSamples(n),
         .iPredOrder(pred_o),
         .iFreshData(data_rdy),
         .oNeedData(need_data),
         .oResidual(oData),
         .oDone(done)
         );


    always begin
        #10 clk = !clk;
    end

    always @(posedge clk) begin
        if (need_data && !data_rdy) begin
            i = i + 1;
            data = memory[i];
            data_rdy = 1;
            #40
            data_rdy = 0;
        end
    end
    
    initial begin
        $readmemh("residual.rmh", memory);
        clk = 0; rst = 1; ena = 0; data_rdy = 0; i = 0;
        n = 4096; pred_o = 0;
        #20 data = memory[i]; rst = 1;
        #20 rst = 0; ena = 1;
        
        #1000 $stop;

    end
    
/* 29A5 E46F 
 * 0010 1001 1010 0101 1110 0100 0110 1111
 * ccpp pprr rr0 00101 0111001
 *      10    6 MSB: 1 LSB: 23 D: */
                
endmodule
