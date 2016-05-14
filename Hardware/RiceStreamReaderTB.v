`timescale 1ns / 1ns

`define assert(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value"); \
        end
    
module RiceStreamReaderTB;
    integer i, j;
    reg iClock, rst, en, data;
    wire [15:0] MSB, LSB;
    wire [3:0] RiceParam;
    wire Done;
    
    RiceStreamReader DUT (.iClock(iClock), 
                          .iReset(rst), 
                          .iEnable(en), 
                          .iData(data), 
                          .iBlockSize(16'd16),
                          .iPredictorOrder(4'b0),
                          .iPartitionOrder(4'd2),
                          .oMSB(MSB), 
                          .oLSB(LSB),
                          .oRiceParam(RiceParam), 
                          .oDone(Done));

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
   M: 2,6,3, 1,1,3,11, 0,0,0,5, 0,1,11,0
   L: 0,0,0, 0,1,0, 0, 2,6,3,5, 2,2, 1,3
 */
 
/*
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
*/

/*  Difficult Case
    Rice Param: 1
    Data = 0M0L0, -1M0L1, 2M2L0, -1M0L1
    Rice Param: 0
    Data = 2M4L0, 1M2L0, -1M1L0, 1M2L0
    Rice Param: 1
    Data = -1M0L1, 2M2L0,0M0L0, 2M2L0
    Rice Param: 0
    Data = 0M0L0, 0M0L0, 1M2L0, 0M0L0
    
    Expected Data:
    M: 0,0,2,0, 4,2,1,2, 0,2,0,2, 0,0,2,0
    L: 0,1,0,1, 0,0,0,0, 1,0,0,0, 0,0,0,0
*/

    reg [15:0] memory [0:20];
    initial begin     //rrrr  2       6
        #0                //          rr
        memory[0] = 16'b0001101100101100;
                    //  rr             r
        memory[1] = 16'b0000001001010010;
                    //  rrr            r
        memory[2] = 16'b0011100101000100;
                    //  rrr
        memory[3] = 16'b000110011xxxxxxx;
    end



    initial begin
        #0 iClock = 0; rst = 1; en = 0; data = 0; 
        #30 en = 1; rst = 0;
        
        for (i = 0; i < 4; i = i + 1) begin
            for (j = 15; j >= 0; j = j - 1) begin
                data = memory[i][j];
                #20;
            end
        end
            
        #20 $stop;
    end
    
endmodule
