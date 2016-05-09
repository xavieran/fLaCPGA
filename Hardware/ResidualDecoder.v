module ResidualDecoder(input iClock, 
         input iReset, 
         input iEnable,
         input [15:0] iNSamples,
         input [3:0] iPredOrder,
         input [4:0] iStartBit,
         input [15:0] iStartAddr,
         output signed [15:0] oResidual,
         output oDone,
         /* RAM I/O */
         input [15:0] iData,
         output [15:0] oReadAddr
         );

 reg [3:0] part_order;
 reg [3:0] rice_param;
 reg [7:0] current_partition;
 reg [15:0] curr_part_size;
 
 reg [15:0] total_samples_read;
 reg [15:0] samples_read;
 reg [4:0] curr_bit;
 
 
 
 reg [47:0] data_buffer; // 3 word buffer prev|current|next
 reg [15:0] rd_addr;
 reg need_data;
 
 reg [3:0] state;
 
 parameter S_RD_INIT1 = 0, S_RD_INIT2 = 1, S_RD_INIT3 = 2, 
           S_RD_PART_INIT1 = 3, S_RD_PART_INIT2 = 4,
           S_RD_PART_RES = 5, S_NEED_DATA = 6;
 
 /* RiceFeeder nets */
 reg rf_idata, rf_enable, rf_rst;
 wire signed [15:0] rf_odata;
 reg signed [15:0] residual;
 wire rf_done;
 reg done;
 
 reg [1:0] delay;
 
 assign oResidual = residual;
 assign oDone = done;
 assign oReadAddr = rd_addr;
 
 RiceFeeder rf (.iClock(iClock),
      .iReset(rf_rst),
      .iEnable(rf_enable),
      .iData(rf_idata),
      .iRiceParam(rice_param),
      .oData(rf_odata),
      .oDone(rf_done));


/* Method::
1. Read in the partition order (4 bits)
2. Read in the rice parameter (4 bits)
3. Store current partition being read 
4. Calculate current partition size 
5. Read and output curr_part_size number of rice samples 
6. Repeat from step 3 
*/

/* INVARIANT: 
 * data_buffer will always have the freshest bits at the top
 * e.g. read 4 bits . Shift data_buffer left 4
 */
always @(posedge iClock) begin
    if (iReset) begin
        state <= S_RD_INIT1;
        
        delay <= 0;
        part_order <= 0;
        rice_param <= 0;
        current_partition <= 0;
        curr_part_size <= 0;
        
        total_samples_read <= 0;
        samples_read <= 0;
        
        curr_bit <= iStartBit;
        rd_addr <= iStartAddr; // Have next data ready
        
        data_buffer <= iData;
        need_data <= 1;
        
        rf_idata <= 0;
        rf_enable <= 0;
        rf_rst <= 1;
        
        done <= 0;
    end else if (iEnable) begin
        /* Reads the data */
        if (need_data) begin
            rd_addr <= rd_addr + 1;
            need_data <= 0;
        end
        
        case (state)        
        default:
        begin
            state <= S_RD_INIT1;
            
            delay <= 0;
            part_order <= 0;
            rice_param <= 0;
            current_partition <= 0;
            curr_part_size <= 0;
            
            total_samples_read <= 0;
            samples_read <= 0;
            curr_bit <= iStartBit;
            rd_addr <= iStartAddr;
            
            data_buffer <= iData;
            need_data <= 1;
            
            rf_idata <= 0;
            rf_enable <= 0;
            rf_rst <= 1;
            
            done <= 0;
        end
                
        S_RD_INIT1: 
        begin
            /* Assuming the residual is byte aligned, which it always should be */
            // coding_method <= data_buffer[15:14];  Ignore coding method (2 bits)
            // ccpp pprr rrml
            
            if (curr_bit == 15) begin
                part_order <= data_buffer[13:10]; // read partition order (4 bits)
                curr_part_size <= (iNSamples >> data_buffer[13:10]) - iPredOrder;
                rice_param <= data_buffer[9:6];
                curr_bit <= 5;
                data_buffer <= data_buffer << 10; // Shift data
                
                current_partition <= 0;
                total_samples_read <= 0;
                rf_rst <= 0;
                
                state <= S_RD_PART_RES;
            /* When residual is second byte-aligned */
            end else if (curr_bit == 7) begin
                part_order <= data_buffer[5:2]; // read partition order (4 bits)
                curr_part_size <= (iNSamples >> data_buffer[5:2]) - iPredOrder;
                rice_param[3:2] <= data_buffer[1:0];
                curr_bit <= 1;
                
                rd_addr <= rd_addr + 1'b1;
                
                current_partition <= 0;
                total_samples_read <= 0;
                rf_rst <= 0;
                
                state <= S_RD_INIT2;
            end
            
        end
        
        S_RD_INIT2:
        begin
            if (delay == 2) begin
                state <= S_RD_INIT3; // Need to delay to wait for RAM
                data_buffer[15:0] <= iData;
                need_data <= 1;
            end else 
                delay <= delay + 1;
        end
        
        S_RD_INIT3:
        begin
            rice_param[1:0] <= data_buffer[15:14];
            data_buffer <= data_buffer << 2;
            curr_bit <= 13;
            state <= S_RD_PART_RES;
        end
        
        S_RD_PART_INIT1: /* Read the first part of the rice param */
        begin
            done <= 0;
            if (part_order == 0) begin /* if the partition order is zero, n = frame's blocksize - predictor order */
                curr_part_size <= iNSamples - iPredOrder;
            end else if (current_partition != 0) begin /* else if this is not the first partition of the subframe, n = (frame's blocksize / (2^partition order)) */
                curr_part_size <= iNSamples >> part_order;
            end else begin
                 /* else n = (frame's blocksize / (2^partition order)) - predictor order */
            end
            
            /* Can't assume byte alignment here */
            /* Note that the rice feeder done signal is delayed 3 clock cycles, so we 
                Use the past values to fill the rice param */
            rice_param <= data_buffer[19:16];
            
            if (curr_bit < 3) begin
                data_buffer[15:0] <= iData;
                need_data <= 1;
                state <= S_RD_PART_INIT2;
            /* This case is when we have read a new value from the RAM just before we
                transitioned here. This means that the curr bit needs to be 15 at the
                end of this iteration... */
            end else if (curr_bit == 3) begin
                curr_bit <= 15;
                state <= S_RD_PART_RES;
                rf_rst <= 0;
            end else begin
                curr_bit <= curr_bit - 4;
                state <= S_RD_PART_RES;
                rf_rst <= 0;
            end
        end

        S_RD_PART_INIT2: /* Read the second part of the rice param */
            begin
                if (curr_bit == 2) begin
                    rice_param[0] <= data_buffer[15];
                    data_buffer <= data_buffer << 1;
                    curr_bit <= 14;
                end else if (curr_bit == 1) begin
                    rice_param[1:0] <= data_buffer[15:14];
                    data_buffer <= data_buffer << 2;
                    curr_bit <= 13;
                end else if (curr_bit == 0) begin
                    rice_param[2:0] <= data_buffer[15:13];
                    data_buffer <= data_buffer << 3;
                    curr_bit <= 12;
                end
                
                state <= S_RD_PART_RES;
                rf_rst <= 0;
            end

        S_RD_PART_RES:
        begin
            done <= 0;
            rf_enable <= 1;
            rf_idata <= data_buffer[15];
            data_buffer <= data_buffer << 1;
            curr_bit <= curr_bit - 1;
            
            /* We need more data */
            if (curr_bit == 0) begin
                curr_bit <= 15; // reset current bit ... 
                data_buffer[15:0] <= iData;
                need_data <= 1;
            end
            
            /* If we've read all data in this partition, go to next */
            if (rf_done && samples_read == curr_part_size - 1) begin
                state <= S_RD_PART_INIT1;
                rf_rst <= 1; // Reset the rice decoder
                rf_enable <= 0;
                current_partition <= current_partition + 1;
                
                curr_bit <= curr_bit + 3;
                
                samples_read <= 0;
                total_samples_read <= total_samples_read + 1;
                
                residual <= rf_odata;
                done <= 1;
            /* We've decoded a residual */
            end else if (rf_done) begin
                samples_read <= samples_read + 1;
                total_samples_read <= total_samples_read + 1;
                
                residual <= rf_odata;
                done <= 1;
            end
        end
        endcase
    end
end

endmodule
