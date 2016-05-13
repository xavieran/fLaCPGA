module RiceStreamReader(input iClock,
                        input iReset,
                        input iEnable,
                        input iData,
                        input [15:0] iBlockSize,
                        input [3:0] iPredictorOrder,
                        input [3:0] iPartitionOrder,
                        output reg [15:0] oMSB,
                        output reg [15:0] oLSB,
                        output reg [3:0] oRiceParam,
                        output oDone);

    /* Encoded residual. The number of samples (n) in the partition is determined as follows:

    if the partition order is zero, n = frame's blocksize - predictor order
    else if this is not the first partition of the subframe, n = (frame's blocksize / (2^partition order))
    else n = (frame's blocksize / (2^partition order)) - predictor order
    */


    /* The number of samples expected in the current partition */
    reg [15:0] expected_samples;
    /* Used to precompute the typical partition size for this residual */
    reg [15:0] typical_part_size;
    /* The number of samples that have been seen in the current partition */
    reg [15:0] sample_count;
    /* The bits remaining to be read in either the LSBs or the rice parameter*/
    reg [3:0] bits_remaining;
    
    /* The intermediate MSBs, LSBs and Rice Parameter*/
    reg [15:0] procMSBs, procLSBs;
    reg [3:0] procRiceParam;

    /* The current state */
    reg [1:0] state;
    reg done;
    
    /* States */
    parameter IDLE = 2'b00, RICE_PARAMETER = 2'b01, UNARY = 2'b10, REMAINDER = 2'b11;
            
    assign oDone = done;

    always @(posedge iClock) begin
        if (iReset) begin
            state <= RICE_PARAMETER;
            bits_remaining <= 4'd3;
                
            expected_samples <= iPartitionOrder ? (iBlockSize >> iPartitionOrder) - iPredictorOrder - 1'b1 : iBlockSize - iPredictorOrder - 1'b1;
            typical_part_size <= (iBlockSize >> iPartitionOrder) - 1'b1;
            sample_count <= 16'b0;

            done <= 1'b0;
        
            procLSBs <= 16'b0;
            procMSBs <= 16'b0;
            procRiceParam <= 4'b0;
            
            oRiceParam <= 4'b0;
            oMSB <= 16'b0;
            oLSB <= 16'b0;
            
        end else if (iEnable) begin
            case (state)
                RICE_PARAMETER:
                    begin 
                        done <= 1'b0;
                        sample_count <= 16'b0;
                        
                        if (bits_remaining != 4'b0) begin
                            procRiceParam[bits_remaining] <= iData;
                            bits_remaining <= bits_remaining - 1'b1;
                        end else begin
                            oRiceParam <= procRiceParam | iData;
                            state <= UNARY;
                        end
                    end
                        
                UNARY:
                    begin
                        if (iData == 1'b0) begin // Count the 0s not 1s...
                            procMSBs <= procMSBs + 1'b1;
                            done <= 1'b0;
                        end else begin
                            oMSB <= procMSBs;
                            if (oRiceParam != 0) begin
                                bits_remaining <= oRiceParam - 1'b1;
                                procLSBs <= 1'b0;
                                state <= REMAINDER;
                            end else begin
                                procMSBs <= 16'b0;
                                done <= 1'b1;
                                if (sample_count != expected_samples) begin
                                    state <= UNARY;
                                    sample_count <= sample_count + 1'b1;
                                end else begin 
                                    state <= RICE_PARAMETER;
                                    procRiceParam <= 4'b0;
                                    bits_remaining <= 4'd3;
                                    expected_samples <= typical_part_size;
                                end
                            end
                        end
                    end
                
                REMAINDER:
                    begin
                        if (bits_remaining != 4'b0) begin
                            done <= 1'b0;
                            procLSBs[bits_remaining] <= iData;
                            bits_remaining <= bits_remaining - 1'b1;
                        end else begin
                            procMSBs <= 16'b0;
                            oLSB <= procLSBs | iData;
                            done <= 1'b1;
                            
                            if (sample_count != expected_samples) begin
                                state <= UNARY;
                                sample_count <= sample_count + 1'b1;
                            end else begin
                                state <= RICE_PARAMETER;
                                procRiceParam <= 4'b0;
                                bits_remaining <= 4'd3;
                                expected_samples <= typical_part_size;
                            end
                        end
                    end 
                    
            endcase
        end
    end
    
endmodule
