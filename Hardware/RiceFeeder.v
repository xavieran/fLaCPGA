module RiceFeeder(input iClock,
                input iReset,
                input iEnable,
                input iData,
                input [15:0] iBlockSize, 
                input [15:0] iPartitionOrder,
                input [3:0] iPredictorOrder,
                output reg signed [15:0] oData,
                output oDone);

    /* Given a data stream, this module will decode the rice integers
        and regularly signal that it has done decoding using the 
        "done" flag. This means that the data in oData is a valid decoding 
        of the residual */
                    
    wire [15:0] MSBs, LSBs;
    wire [3:0] RiceParam;
    wire signed [15:0] data;
    wire sr_done;
    reg [1:0] done_hist;
    reg done;

    assign oDone = done;

    RiceDecoder rd (.oData(data),
                    .iRiceParam (RiceParam),
                    .iClock (iClock),
                    .iLSB (LSBs),
                    .iMSB (MSBs));
                    
    RiceStreamReader rf (.iClock(iClock),
                        .iReset(iReset),
                        .iEnable(iEnable),
                        .iData(iData),
                        .iBlockSize(iBlockSize),
                        .iPredictorOrder(iPredictorOrder),
                        .iPartitionOrder(iPartitionOrder),
                        .oMSB(MSBs),
                        .oLSB(LSBs),
                        .oRiceParam(RiceParam),
                        .oDone(sr_done));
                            
    always @(posedge iClock) begin
        done_hist = {done_hist[0], sr_done};
        
        if (iReset) begin
            done_hist <= 2'b0;
            oData <= 15'b0;
            done <= 1'b0;
        end else if (iEnable) begin
            // Detect a positive edge on the done signal from sr
            if (done_hist == 2'b01) begin
                done <= 1'b1;
                oData <= data;
            end else 
                done <= 1'b0;
        end
    end

endmodule
