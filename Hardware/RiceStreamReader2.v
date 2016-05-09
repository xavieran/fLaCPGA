module RiceStreamReader2(input iClock,
                        input iReset,
                        input iEnable,
                        input [1:0] iData,
                        input [3:0] iRiceParam, 
                        output reg [15:0] oMSB,
                        output reg [15:0] oLSB,
                        output oDone);
/* This module analyses the data stream and outputs the current LSBs and MSBs 
   for the stream. Whenever the done flag is raised, you can sample the correct LSBs and MSBs
*/

    reg [15:0] procMSBs, procLSBs;
    
    parameter IDLE = 2'b00, UNARY = 2'b01, REMAINDER = 2'b10;
    
    reg [1:0] state;
    reg done;
    
    assign oDone = done;
                         
    reg [3:0] rem_bits;
    
    always @(posedge iClock) begin
        if (iReset) begin
            state <= UNARY;
            done <= 0;
            procLSBs <= 0;
            procMSBs <= 0;
            oMSB <= 0;
            oLSB <= 0;
        end else if (iEnable) begin
            case (state)
                UNARY:
                    begin
                        case (iData)
                        2'b00:
                            begin
                            procMSBs <= procMSBs + 2;
                            rem_bits <= rem_bits;
                            procLSBs <= 0;
                            state <= UNARY;
                            done <= 0;
                            end
                        2'b01:
                            begin
                            procMSBs <= procMSBs + 1;
                            rem_bits <= iRiceParam - 1;
                            procLSBs <= 0;
                            state <= REMAINDER;
                            done <= 0;
                            end
                        2'b10:
                            begin
                            procMSBs <= procMSBs;
                            rem_bits <= iRiceParam - 2;
                            procLSBs <= 0;
                            state <= REMAINDER;
                            done <= 0;
                            end
                        2'b11:
                            begin
                            procMSBs <= procMSBs;
                            rem_bits <= iRiceParam - 2;
                            procLSBs[iRiceParam - 1] <= 1;
                            state <= REMAINDER;
                            done <= 0;
                            end
                        endcase
                    end
                REMAINDER:
                    begin
                        if (rem_bits == 0) begin
                            oMSB <= procMSBs;
                            oLSB <= procLSBs | iData[1];
                            done <= 1;
                            if (iData[0] == 0) begin
                                procMSBs <= 1;
                                state <= UNARY;
                            end else begin
                                procMSBs <= 0;
                                procLSBs <= 0;
                                state <= REMAINDER;
                                rem_bits <= iRiceParam - 1;
                            end
                            
                        end else if (rem_bits == 1) begin
                            oLSB <= procLSBs | iData;
                            oMSB <= procMSBs;
                            procMSBs <= 0;
                            
                            done <= 1;
                            state <= UNARY;
                        end else begin
                            done <= 0;
                            procLSBs <= (iData << (rem_bits - 1)) | procLSBs;
                            rem_bits <= rem_bits - 2;
                            state <= REMAINDER;
                        end
                    end
            endcase
        end
    end
        
endmodule
