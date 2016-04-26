module ResidualDecoder(input iClock, 
         input iReset, 
         input iEnable,
         input [15:0] iNSamples,
         input [3:0] iPredOrder,
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
 
 reg [31:0] data_buffer;
 reg [15:0] rd_addr;
 reg need_data;
 
 reg [2:0] state;
 reg [2:0] prev_state;
 
 
 
 parameter S_RD_INIT = 0, S_RD_PART_INIT1 = 1, S_RD_PART_INIT2 = 2, S_RD_PART_RES = 3, S_NEED_DATA = 4;
 
 /* RiceFeeder nets */
 reg rf_idata, rf_enable, rf_rst;
 wire signed [15:0] rf_odata;
 reg signed [15:0] residual;
 wire rf_done;
 reg done;
 
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
        state <= S_RD_INIT;
        
        part_order <= 0;
        rice_param <= 0;
        current_partition <= 0;
        curr_part_size <= 0;
        
        total_samples_read <= 0;
        samples_read <= 0;
        curr_bit <= 15;
        
        data_buffer <= iData;
        rd_addr <= 0;
        need_data <= 1;
        prev_state <= 0;
        
        rf_idata <= 0;
        rf_enable <= 0;
        rf_rst <= 0;
        
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
            state <= S_RD_INIT;
            
            part_order <= 0;
            rice_param <= 0;
            current_partition <= 0;
            curr_part_size <= 0;
            
            total_samples_read <= 0;
            samples_read <= 0;
            curr_bit <= 15;
            
            data_buffer <= iData;
            need_data <= 1;
            rd_addr <= 0;
            prev_state <= 0;
            
            rf_idata <= 0;
            rf_enable <= 0;
            
            done <= 0;
        end
                
        S_RD_INIT: 
        begin
            /* Assuming the residual is byte aligned, which it always should be */
            // coding_method <= data_buffer[15:14];  Ignore coding method (2 bits) 
            part_order <= data_buffer[13:10]; // read partition order (4 bits)
            curr_bit <= curr_bit - 6;
            data_buffer <= data_buffer << 6; // Shift data
            current_partition <= 0;
            total_samples_read <= 0;
            state <= S_RD_PART_INIT1;
            rf_rst <= 1;
        end
        
        S_RD_PART_INIT1: /* Read the first part of the rice param */
        begin
            done <= 0;
            if (part_order == 0) begin /* if the partition order is zero, n = frame's blocksize - predictor order */
                curr_part_size <= iNSamples - iPredOrder;
            end else if (current_partition != 0) begin /* else if this is not the first partition of the subframe, n = (frame's blocksize / (2^partition order)) */
                curr_part_size <= iNSamples >> part_order;
            end else begin
                curr_part_size <= (iNSamples >> part_order) - iPredOrder; /* else n = (frame's blocksize / (2^partition order)) - predictor order */
            end
            
            /* Can't assume byte alignment here */
            if (current_partition != 0) begin
                /* Note that the rice feeder done signal is delayed 3 clock cycles, so we 
                   Use the past values to fill the rice param */
                rice_param <= data_buffer[19:16];
                
                if (curr_bit < 3) begin
                    data_buffer[15:0] <= iData;
                    need_data <= 1;
                    
                    state <= S_RD_PART_INIT2;
                end else begin
                    curr_bit <= curr_bit - 4;
                    
                    state <= S_RD_PART_RES;
                    rf_rst <= 0;
                end
            end else begin
                rice_param <= data_buffer[15:12];
                curr_bit <= curr_bit - 4;
                data_buffer <= data_buffer << 4;
                
                state <= S_RD_PART_RES;
                rf_enable <= 0;
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
