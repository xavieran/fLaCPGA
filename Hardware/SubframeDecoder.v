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
reg [3:0] predictor_order;
reg [3:0] partition_order;
reg [15:0] block_size;

reg rd_enable, rd_reset, fd_reset, fd_enable, done;
reg [4:0] rd_start_bit;
reg [15:0] sample_count, read_address;
reg signed [15:0] warmup_sample;
reg [15:0] warmup_count;
reg warmup_done;

parameter S_READ_HEADER = 0, S_READ_WARM = 1, S_READ_FIXED = 2, S_READ_VERBATIM = 3;
reg [2:0] state;
reg [2:0] next_state;
reg wait_for_ram;
reg warmup_hi;


wire rd_done;
wire signed [15:0] rd_residual, fd_sample;
wire [15:0] rd_read_address;
assign oSampleValid = done;


assign oSample = (state == S_READ_FIXED) ? fd_sample : warmup_sample;
assign oReadAddr = rd_enable ? rd_read_address : read_address;


always @(posedge iClock) begin
    if (iReset) begin
        data_buffer <= iData;
        state <= S_READ_HEADER;
        next_state <= 3'b0;
        wait_for_ram <= 1'b1;
        warmup_hi <= 0;
        warmup_done <= 0;
        
        predictor_order <= 0;
        partition_order <= 0;
        block_size <= iBlockSize;
        
        read_address <= 16'b0;
        
        rd_enable <= 0;
        rd_reset <= 1;
        fd_enable <= 0;
        fd_reset <= 1;
        rd_start_bit <= 5'b0;
        
        warmup_count <= 0;
        warmup_sample <= 0;
        sample_count <= 0;
        oFrameDone <= 0;
        done <= 0;
        
    end else if (iEnable) begin
        case (state)
        S_READ_HEADER:
        begin
            done <= warmup_done; // !!!??? Shouldnt we make verbatim cleaner then ??
            // 000000 : SUBFRAME_CONSTANT
            if (data_buffer[14:9] == 6'b000000) begin
            
            // 000001 : SUBFRAME_VERBATIM
            end else if (data_buffer[14:9] == 6'b000001) begin
                warmup_count <= iBlockSize + 1;
                warmup_sample[15:8] <= data_buffer[7:0];
                warmup_hi <= 1'b1;
                read_address <= read_address + 1'b1;
                
                state <= S_READ_VERBATIM;
                
                
            // 001xxx : if(xxx <= 4) SUBFRAME_FIXED, xxx=order ; else reserved-
            // 54321098 76543210
            // 00010000 001010xx
            // ztttoooz ccpppprr
            
            end else if (data_buffer[14:12] == 3'b001) begin 
                /* Warning!!! All this stuff assumes that the header starts as the high byte of the RAM */
                predictor_order <= data_buffer[11:9];
                
                warmup_count <= data_buffer[11:9];
                if (data_buffer[11:9] == 0) begin
                    partition_order <= data_buffer[5:2];
                    rd_start_bit <= 5'b1;
                    state <= S_READ_FIXED;
                end else if (data_buffer[11:9] != 0) begin
                    warmup_sample[15:8] <= data_buffer[7:0];
                    warmup_hi <= 1'b1;
                    read_address <= read_address + 1'b1;
                    state <= S_READ_WARM;
                    next_state <= S_READ_FIXED;
                end
                
                wait_for_ram <= 1'b1;
                
            // 01xxxx : reserved : SUBFRAME_LPC, xxxxx=order-1
            end else if (data_buffer[14] == 1'b1) begin

            end else begin
                // Raise error?
            end
        end
        
        S_READ_VERBATIM:
        begin
            if (!wait_for_ram) begin
                if (warmup_count == 4'b0) begin
                    warmup_count <= 0;
                    if (warmup_hi) begin
                        warmup_hi <= 1'b0;
                        warmup_sample[7:0] <= iData[15:8];
                        done <= 1'b1;
                        wait_for_ram <= 1'b1;
                        state <= S_READ_HEADER;
                    end
                end else if (warmup_count > 4'b1) begin
                    if (warmup_hi) begin
                        warmup_hi <= 1'b0;
                        warmup_sample[7:0] <= iData[15:8];
                        done <= 1'b1;
                    end else begin
                        done <= 1'b0;
                        warmup_sample[15:8] <= iData[7:0];
                        warmup_hi <= 1'b1;
                        warmup_count <= warmup_count - 1'b1;
                        read_address <= read_address + 1'b1;
                        wait_for_ram <= 1'b1;
                    end
                end 
            end else wait_for_ram <= 1'b0;
        end

        S_READ_FIXED:
        begin
            fd_enable <= 1'b0;
            warmup_sample <= 16'b0;
            
            if (!wait_for_ram) begin
                warmup_done <= 1'b0;
                rd_enable <= 1'b1;
                fd_enable <= 1'b0;
                rd_reset <= 1'b0;
                fd_reset <= 1'b0;
                
                done <= rd_done | warmup_done; // Delay rd_done by 1 cycle
                
                if (rd_done) begin
                    sample_count <= sample_count + 1'b1;
                    if (sample_count == iBlockSize) begin
                        state <= S_READ_HEADER;
                        oFrameDone <= 1'b1;
                    end
                end
            end else begin
                wait_for_ram <= 1'b0;
            end
        end
        
        S_READ_WARM:
        begin
            done <= rd_done | warmup_done;
            if (!wait_for_ram) begin
                fd_enable <= 1'b0;
                fd_reset <= 1'b0;
                
                if (warmup_count == 4'b1) begin
                    warmup_count <= 0;
                    if (warmup_hi) begin
                        warmup_hi <= 1'b0;
                        warmup_sample[7:0] <= iData[15:8];
                        warmup_done <= 1'b1;
                        fd_enable <= 1'b1;
                        rd_start_bit <= 5'd1;
                        wait_for_ram <= 1'b1;
                        partition_order <= iData[5:2];
                        state <= next_state;
                    end
                end else if (warmup_count > 4'b1) begin
                    if (warmup_hi) begin
                        warmup_hi <= 1'b0;
                        warmup_sample[7:0] <= iData[15:8];
                        warmup_done <= 1'b1;
                        fd_enable <= 1'b1;
                    end else begin
                        warmup_done <= 1'b0;
                        warmup_sample[15:8] <= iData[7:0];
                        warmup_hi <= 1'b1;
                        warmup_count <= warmup_count - 1'b1;
                        read_address <= read_address + 1'b1;
                        wait_for_ram <= 1'b1;
                    end
                end 
            end else wait_for_ram <= 1'b0;
        end
        
        endcase
    end
end


FixedDecoder fd (.iClock(iClock),
                 .iReset(fd_reset),
                 .iEnable(rd_done | fd_enable),
                 .iOrder(predictor_order),
                 .iSample(rd_residual | warmup_sample),
                 .oData(fd_sample)
                 );


ResidualDecoder rd (
         .iClock(iClock),
         .iReset(rd_reset), 
         .iEnable(rd_enable),
         
         .iBlockSize(block_size),
         .iPredictorOrder(predictor_order),
         .iPartitionOrder(partition_order),
         
         .iStartBit(rd_start_bit),
         .iStartAddr(read_address + 1'b1),
         
         .oResidual(rd_residual),
         .oDone(rd_done),
         
         /* RAM I/O */
         .iData(iData),
         .oReadAddr(rd_read_address)
         );

endmodule
