/*
    == SubframeDecoder ==
    
    Decodes a subframe

    iClock: The iClock
    iReset: hold high for 1 clock cycle to fd_reset
    iEnable: The module only activates when iEnable is high
    iUpperBits: If this is high, the subframe begins in the upper 8 bits of the
                16 bit input word, else in the lower 8 bits
    oSampleValid: Goes high whenever a valid sample has been output
    oFrameDone: Goes high when the whole frame has been read (e.g. all 4096 samples)
    oSample: Signed 16 bit audio sample output
        
    iBlockSize: The block size of the subframe (usually 4096 samples)
    oStartAddress: The address the RAM is pointing to at the start
    iData: A RAM data port
    oReadAddr: Tells the RAM which address to return data from
    
*/


module SubframeDecoder(input iClock,
                       input iReset,
                       input iEnable, 
                       input [15:0] iBlockSize,
                       output oSampleValid,
                       output reg oFrameDone,
                       output signed [15:0] oSample,
                       
                       /* RAM I/O */
                       input iUpperBits,
                       input [15:0] iStartAddress,
                       
                       input [15:0] iData, 
                       output [15:0] oReadAddr
                       );


// Register inputs
reg [15:0] data_buffer; 
reg [15:0] block_size; 
reg upper, lower; 

reg [3:0] predictor_order;
reg [3:0] partition_order;



reg [15:0] sample_count, read_address;

// Warmup stuff
reg signed [15:0] warmup_sample;
reg [15:0] warmup_count;
reg warmup_done;
reg warmup_hi;
reg done;

parameter S_READ_HEADER = 0, S_READU_WARM =  1, S_READL_WARM = 2, 
          S_READU_FIXED = 3, S_READL_FIXED = 4, S_READU_VERBATIM = 5, 
          S_READL_VERBATIM = 6;
reg [2:0] state;
reg [2:0] next_state;
reg wait_for_ram;

// Residual Decoder and Fixed Decoder stuff
reg rd_enable, rd_reset, fd_reset, fd_enable;
wire signed [15:0] rd_residual, fd_sample;
reg [4:0] rd_start_bit;
wire rd_done;
wire [15:0] rd_read_address;

assign oSampleValid = done;

assign oSample = (state == S_READU_FIXED || state == S_READL_FIXED) ? fd_sample : warmup_sample;
assign oReadAddr = rd_enable ? rd_read_address : read_address;


always @(posedge iClock) begin
    if (iReset) begin
        // Register inputs
        data_buffer <= iData;
        block_size <= iBlockSize;
        upper <= iUpperBits;
        lower <= !iUpperBits;
        
        predictor_order <= 0;
        partition_order <= 0;

        sample_count <= 0;
        read_address <= iStartAddress;
        
        warmup_sample <= 0;
        warmup_count <= 0;
        warmup_done <= 0;
        warmup_hi <= 0;
        done <= 0;
        
        state <= S_READ_HEADER;
        next_state <= 3'b0;
        wait_for_ram <= 1'b1;
        
        rd_enable <= 0;
        rd_reset <= 1;
        fd_enable <= 0;
        fd_reset <= 1;
        rd_start_bit <= 5'b0;
        
        oFrameDone <= 0;
        
    end else if (iEnable) begin
        case (state)
        S_READ_HEADER:
        begin
            // 000000 : SUBFRAME_CONSTANT
            if ((upper && data_buffer[14:9] == 6'b000000) || 
                (lower && data_buffer[6:1] == 6'b000000)) begin
            
            // 000001 : SUBFRAME_VERBATIM
            end else if (upper && data_buffer[14:9] == 6'b000001) begin
                warmup_count <= block_size;
                warmup_sample[15:8] <= data_buffer[7:0];
                warmup_hi <= 1'b1;
                read_address <= read_address + 1'b1;
                wait_for_ram <= 1'b1;
                state <= S_READU_VERBATIM;
            end else if (lower && data_buffer[6:1] == 6'b000001) begin
                warmup_count <= block_size;
                read_address <= read_address + 1'b1;
                wait_for_ram <= 1'b1;
                state <= S_READL_VERBATIM;
                
            // 001xxx : if(xxx <= 4) SUBFRAME_FIXED, xxx=order ; else reserved-
            // 54321098 76543210
            // 00010000 001010xx
            // ztttoooz ccpppprr
            end else if (upper && data_buffer[14:12] == 3'b001) begin 
                predictor_order <= data_buffer[11:9];
                
                warmup_count <= data_buffer[11:9];
                if (data_buffer[11:9] == 0) begin
                    partition_order <= data_buffer[5:2];
                    rd_start_bit <= 5'b1;
                    state <= S_READU_FIXED;
                end else if (data_buffer[11:9] != 0) begin
                    warmup_sample[15:8] <= data_buffer[7:0];
                    warmup_hi <= 1'b1;
                    read_address <= read_address + 1'b1;
                    state <= S_READU_WARM;
                    next_state <= S_READU_FIXED;
                end
                
                wait_for_ram <= 1'b1;
                
            end else if (lower && data_buffer[6:4] == 3'b001) begin 
                predictor_order <= data_buffer[3:1];
                warmup_count <= data_buffer[3:1];
                
                if (data_buffer[3:1] == 0) begin
                    state <= S_READL_FIXED;
                    // This is a horrible hacky way of waiting for RAM.... :/
                    next_state <= S_READ_HEADER; 
                    rd_start_bit <= 4'd9;
                end else if (data_buffer[3:1] != 0) begin
                    state <= S_READL_WARM;
                    next_state <= S_READL_FIXED;
                end
                
                read_address <= read_address + 1'b1;
                wait_for_ram <= 1'b1;
                
            // 01xxxx : reserved : SUBFRAME_LPC, xxxxx=order-1
            end else if (data_buffer[14] == 1'b1) begin

            end else begin
                // Raise error?
            end
        end
        
        S_READU_VERBATIM:
        begin
            if (!wait_for_ram) begin
                if (warmup_count == 4'b0) begin
                    warmup_count <= 0;
                    warmup_hi <= 1'b0;
                    warmup_sample[7:0] <= data_buffer[15:8];
                    done <= 1'b1;
                    oFrameDone <= 1'b1;
                    state <= S_READ_HEADER;
                end else if (warmup_count >= 4'b1) begin
                    if (warmup_hi) begin
                        warmup_hi <= 1'b0;
                        warmup_sample[7:0] <= data_buffer[15:8];
                        warmup_count <= warmup_count - 1'b1;
                        done <= 1'b1;
                    end else begin
                        done <= 1'b0;
                        warmup_sample[15:8] <= data_buffer[7:0];
                        warmup_hi <= 1'b1;
                        read_address <= read_address + 1'b1;
                        wait_for_ram <= 1'b1;
                    end
                end 
            end else begin
                wait_for_ram <= 1'b0;
                data_buffer <= iData;
            end
        end       
        
        S_READL_VERBATIM:
        begin
            if (!wait_for_ram) begin
                if (warmup_count == 4'b0) begin             
                    warmup_sample <= data_buffer;
                    warmup_count <= warmup_count - 1'b1;
                    done <= 1'b1;
                    oFrameDone <= 1'b1;
                    state <= S_READ_HEADER;
                end else if (warmup_count >= 4'b1) begin
                    warmup_sample <= data_buffer;
                    warmup_count <= warmup_count - 1'b1;
                    done <= 1'b1;
                end 
                
                read_address <= read_address + 1'b1;
                wait_for_ram <= 1'b1;

            end else begin
                done <= 1'b0;
                wait_for_ram <= 1'b0;
                data_buffer <= iData;
            end
        end

        S_READU_FIXED:
        begin
            fd_enable <= 1'b0;
            warmup_sample <= 16'b0;
            warmup_done <= 1'b0;
            done <= 1'b0;
            oFrameDone <= (sample_count == block_size && done);
            
            if (!wait_for_ram) begin
                rd_enable <= 1'b1;
                fd_enable <= 1'b0;
                rd_reset <= 1'b0;
                fd_reset <= 1'b0;
                
                if (rd_done) begin
                    done <= 1'b1;
                    sample_count <= sample_count + 1'b1;
                end
            end else begin
                done <= 1'b0;
                wait_for_ram <= 1'b0;
            end
        end
        
        S_READL_FIXED:
        begin
            fd_enable <= 1'b0;
            warmup_sample <= 16'b0;
            warmup_done <= 1'b0;
            done <= 1'b0;
            oFrameDone <= (sample_count == block_size && done);
            
            if (!wait_for_ram) begin
                rd_enable <= 1'b1;
                fd_enable <= 1'b0;
                rd_reset <= 1'b0;
                fd_reset <= 1'b0;
                
                if (rd_done) begin
                    done <= 1'b1;
                    sample_count <= sample_count + 1'b1;
                end
            end else begin
                if (next_state != S_READ_HEADER) begin 
                    wait_for_ram <= 1'b0;
                    partition_order <= iData[13:10];
                end else next_state <= S_READL_FIXED;
            end
        end
        //0010 0101 1100 1110
        //ccpp pprr rr
        //5432 10
        
        S_READU_WARM:
        begin
            fd_enable <= 1'b0;
            fd_reset <= 1'b0;
            done <= 1'b0;
            
            if (!wait_for_ram) begin
                if (warmup_count == 4'b0) begin
                    wait_for_ram <= 1'b1;
                    partition_order <= iData[5:2];//data_buffer[5:2]; 
                    state <= next_state;
                end else if (warmup_count == 4'b1) begin
                    warmup_count <= 0;
                    warmup_hi <= 1'b0;
                    warmup_sample[7:0] <= iData[15:8];//data_buffer[15:8]; 
                    done <= 1'b1;
                    sample_count <= sample_count + 1'b1;
                    fd_enable <= 1'b1;
                    rd_start_bit <= 5'd1;
                end else if (warmup_count > 4'b1) begin
                    if (warmup_hi) begin
                        warmup_hi <= 1'b0;
                        warmup_sample[7:0] <= iData[15:8];//data_buffer[15:8]; 
                        done <= 1'b1;
                        fd_enable <= 1'b1;
                    end else begin
                        warmup_count <= warmup_count - 1'b1;
                        sample_count <= sample_count + 1'b1;
                        warmup_sample[15:8] <= iData[7:0];//data_buffer[7:0]; 
                        warmup_hi <= 1'b1;
                        read_address <= read_address + 1'b1;
                        wait_for_ram <= 1'b1;
                    end
                end 
            end else begin
                wait_for_ram <= 1'b0;
            end
        end
        
        S_READL_WARM:
        begin
            done <= 1'b0;
            fd_enable <= 1'b0;
            fd_reset <= 1'b0;
            rd_start_bit <= 5'd9;
            
            if (!wait_for_ram) begin
                
                if (warmup_count == 4'b0) begin //
                    state <= next_state;
                    partition_order <= iData[13:10];
                end
                if (warmup_count == 4'b1) begin
                    warmup_count <= 0;
                    //warmup_sample <= data_buffer;
                    warmup_sample <= iData;
                    done <= 1'b1;
                    sample_count <= sample_count + 1'b1;
                    fd_enable <= 1'b1;
                    read_address <= read_address + 1'b1;
                    wait_for_ram <= 1'b1;
                end
                if (warmup_count > 4'b1) begin
                    //warmup_sample <= data_buffer;
                    warmup_sample <= iData;
                    warmup_count <= warmup_count - 1'b1;
                    fd_enable <= 1'b1;
                    done <= 1'b1;
                    sample_count <= sample_count + 1'b1;
                    read_address <= read_address + 1'b1;
                    wait_for_ram <= 1'b1;
                end
                
                
            end else begin
                warmup_done <= 1'b0;
                wait_for_ram <= 1'b0;
            end
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
