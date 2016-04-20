module ResidualDecoder(input iClock, 
         input iReset, 
         input iEnable,
         input [15:0] iData,
         input [15:0] iNSamples,
         input [3:0] iPredOrder,
         input iFreshData,
         output oNeedData,
         output signed [15:0] oResidual,
         output oDone
         );

 reg [3:0] part_order;
 reg [3:0] rice_param;
 reg [7:0] current_partition;
 reg [15:0] curr_part_size;
 
 reg [15:0] total_samples_read;
 reg [15:0] samples_read;
 reg [3:0] curr_bit;
 
 reg need_data;
 reg [15:0] data_buffer;
 
 reg [2:0] state;
 reg [2:0] prev_state;
 
 parameter S_RD_INIT = 0, S_RD_PART_INIT1 = 1, S_RD_PART_RES = 3, S_NEED_DATA = 4;
 
 /* RiceFeeder nets */
 reg rf_idata, rf_enable, rf_rst;
 wire signed [15:0] rf_odata;
 reg signed [15:0] residual;
 wire rf_done;
 reg done;
 
 assign oNeedData = need_data;
 assign oResidual = residual;
 assign oDone = done;
 
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
        
        need_data <= 0;
        
        data_buffer <= iData;
        prev_state <= 0;
        
        rf_idata <= 0;
        rf_enable <= 0;
        rf_rst <= 0;
        
        done <= 0;
    end else if (iEnable) begin
        case (state)
        
        S_NEED_DATA: /* Sit here while we wait for fresh data */
        begin
            if (iFreshData) begin
                need_data <= 0;
                data_buffer <= iData;
                curr_bit <= 15;
                state <= prev_state;
            end
        end
        
        S_RD_INIT: 
        begin
            /* Assuming the residual is byte aligned, which it always should be */
            // Ignore coding method (2 bits) 
            part_order <= data_buffer[13:10]; // read partition order (4 bits)
            curr_bit <= 9;
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
            rice_param <= data_buffer[15:12];
            curr_bit <= curr_bit - 4;
            data_buffer <= data_buffer << 4;
            samples_read = 0;
            state <= S_RD_PART_RES;
            rf_enable <= 0;
            rf_rst <= 0;
        end

        S_RD_PART_RES:
        begin
            rf_enable <= 1;
            rf_idata <= data_buffer[15];
            data_buffer <= data_buffer << 1;
            curr_bit <= curr_bit - 1;
            
            if (curr_bit == 0) begin /* We need more data */
                need_data <= 1; // signal for more data
                curr_bit <= 15; // reset current bit ... 
                prev_state = state;
                state = S_NEED_DATA;
                rf_enable <= 0;
            end
            
            /* We've decoded a residual */
            if (rf_done) begin
                samples_read <= samples_read + 1;
                total_samples_read <= total_samples_read + 1;
                residual <= rf_odata;
                done <= 1;
                /* If we've read all data in this partition, go to next */
            end else if (samples_read == curr_part_size) begin
                state <= S_RD_PART_INIT1;
                current_partition <= current_partition + 1;
            end
        end
        
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
            
            need_data <= 0;
            
            data_buffer <= iData;
            prev_state <= 0;
            
            rf_idata <= 0;
            rf_enable <= 0;
            
            done <= 0;
        end
        endcase
    end
end

endmodule
