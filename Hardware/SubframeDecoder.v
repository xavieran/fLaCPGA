module SubframeDecoder(input iClock,
                       input iReset,
                       input iEnable, 
                       input [15:0] iBlockSize,
                       output oSampleValid,
                       output reg oFrameDone,
                       output signed [15:0] oSample,
                       /* RAM I/O */
                       input [15:0] iData, 
                       output [15:0] oReadAddr
                       );
   
reg [15:0] data_buffer;
reg [2:0] state;

reg [3:0] predictor_order;
reg [3:0] partition_order;
reg [15:0] block_size;

reg rd_enable, rd_reset, fd_reset, done;
reg [15:0] sample_count, read_address;

wire rd_done;
wire signed [15:0] rd_residual;
wire [15:0] rd_read_address;

assign oSampleValid = done;

assign oReadAddr = rd_enable ? rd_read_address : read_address;

parameter S_READ_HEADER = 0, S_READ_FIXED = 1, S_READ_VERBATIM = 2;

always @(posedge iClock) begin
    if (iReset) begin
        data_buffer <= iData;
        state <= S_READ_HEADER;
        
        predictor_order <= 0;
        partition_order <= 0;
        block_size <= iBlockSize;
        
        read_address <= 0;
        
        rd_enable <= 0;
        rd_reset <= 1;
        fd_reset <= 1;
        
        sample_count <= 0;
        oFrameDone <= 0;
        done <= 0;
    end else if (iEnable) begin
        case (state)
        S_READ_HEADER:
        begin
            // 000000 : SUBFRAME_CONSTANT
            if (data_buffer[14:9] == 6'b000000) begin
            
            // 000001 : SUBFRAME_VERBATIM
            end else if (data_buffer[14:10] == 6'b00001) begin
                state <= S_READ_VERBATIM;
            
            // 001xxx : if(xxx <= 4) SUBFRAME_FIXED, xxx=order ; else reserved-
            // 54321098 765432
            // 00010000 001010
            // ztttoooz ccpppp
            end else if (data_buffer[14:12] == 3'b001) begin 
                predictor_order <= data_buffer[11:9];
                partition_order <= data_buffer[5:2];
                state <= S_READ_FIXED;
            // 01xxxx : reserved : SUBFRAME_LPC, xxxxx=order-1
            end else if (data_buffer[14] == 1'b1) begin

            end else begin
                // Raise error?
            end
        end

        S_READ_FIXED:
        begin   
            rd_enable <= 1'b1;
            
            rd_reset <= 1'b0;
            fd_reset <= 1'b0;
            
            done <= rd_done; // Delay rd_done by 1 cycle
            
            if (rd_done) begin
                sample_count <= sample_count + 1'b1;
                if (sample_count == iBlockSize) begin
                    state <= S_READ_HEADER;
                    oFrameDone <= 1'b1;
                end
            end
        end
        endcase
    end
end

FixedDecoder fd (.iClock(iClock),
                 .iReset(fd_reset),
                 .iEnable(rd_done),
                 .iOrder(predictor_order),
                 .iSample(rd_residual),
                 .oData(oSample)
                 );

ResidualDecoder rd (
         .iClock(iClock),
         .iReset(rd_reset), 
         .iEnable(rd_enable),
         
         .iBlockSize(block_size),
         .iPredictorOrder(predictor_order),
         .iPartitionOrder(partition_order),
         
         .iStartBit(5'd1),
         .iStartAddr(read_address),
         
         .oResidual(rd_residual),
         .oDone(rd_done),
         
         /* RAM I/O */
         .iData(iData),
         .oReadAddr(rd_read_address)
         );

endmodule
