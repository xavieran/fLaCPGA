`timescale 1ns / 1ns

`define assert(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value"); \
        end
		  
module RiceFeederTB;

integer i,j;

reg iClock, rst, ena, data;
wire done;
wire signed [15:0] residual;

RiceFeeder DUT (.iClock(iClock),
                .iReset(rst),
                .iEnable(ena),
                .iData(data),
                .iBlockSize(16'd16), 
                .iPartitionOrder(4'd2),
                .iPredictorOrder(4'd1),
                .oData(residual),
                .oDone(done));

always
  begin
    #10 iClock = !iClock;
  end
  
  /* Block Size of 16, Predictor Order of 1, Partition Order of 2 => 
   Samples Per Partition 4
   Samples in first partition 3
   Partition 0
   Rice Param = 0
   Data = 1M2L0, 3M6L0, -2M3L0 
   
   Rice Param = 1
   Data = 1M1L0, -2M1L1, 3M3L0, 11M11L0
   
   Rice Param = 3
   Data = 1M0L2, 3M0L6, -2M0L3, -23M5L5 
   
   Rice Param = 2
   Data = 1M0L2, 3M1L2, -23M11L1, -2M0L3 
   
   Expected Data:
   1,3,-2,1,-2,3,11,1,3,-2,-23,1,3,-23,-2
   
 */
  
    reg [15:0] memory [0:20];
    initial begin     //rrrr  2       6
        #0
        memory[0] = 16'b0000001000000100;
                    // 3rrrr
        memory[1] = 16'b0100010100110001;
                    //              rr
        memory[2] = 16'b0000000000001000;
                    //  rr lll lll lll
        memory[3] = 16'b1110101110101100;
                    //      lllrrrr ll
        memory[4] = 16'b0001101001011001;
                    //  ll            ll
        memory[5] = 16'b1000000000000101;
                    //   ll
        memory[6] = 16'b1110000000000000;
    end
    
    initial begin
        #0 iClock = 0; rst = 1; ena = 0; data = 0; 
        #30 ena = 1; rst = 0;
        
        for (i = 0; i < 6; i = i + 1) begin
            for (j = 15; j >= 0; j = j - 1) begin
                data = memory[i][j];
                #20;
            end
        end
            
        #20 $stop;
    end
  
  
endmodule
