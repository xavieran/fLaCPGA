module FixedEncoderOrder1 (input iClock, 
                           input iEnable,
                           input iReset,
                           input signed [15:0] iSample,
                           output signed [15:0] oResidual);
/* 
 * Latency is 8 cycles after enable signal
 */
 
reg signed [15:0] dataq [0:1];
reg signed [15:0] sample_r;
reg signed [15:0] residual, residual_d1, residual_d2, residual_d3, residual_d4, residual_d5;

reg warmup;
reg warmup_d1, warmup_d2, warmup_d3;

integer i;

assign oResidual = residual_d5;

always @(posedge iClock)
begin
    if (iReset) begin
        sample_r <= 16'b0;
        
        warmup <= 1;
        warmup_d1 <= 0;
        warmup_d2 <= 0;
        warmup_d3 <= 0;
        
        for (i = 0; i <= 1; i = i + 1) begin
            dataq[i] <= 16'b0;
        end
        
        residual <= 16'b0;
        residual_d1 <= 16'b0;
        residual_d2 <= 16'b0;
        residual_d3 <= 16'b0;
        residual_d4 <= 16'b0;
        residual_d5 <= 16'b0;
        
    end else if (iEnable) begin
        // Register the input
        sample_r <= iSample;
        
        // Shift the data queue down
        for (i = 1; i <= 1; i = i + 1) begin
            dataq[i] <= dataq[i - 1];
        end
        
        // Feed the queue
        dataq[0] <= sample_r;
        
        // Fill the queue and then wait 1 cycle to sample the latest data point
        if (!warmup_d3) begin
            warmup_d1 <= warmup;
            warmup_d2 <= warmup_d1;
            warmup_d3 <= warmup_d2;
        end else begin
            
            residual <= dataq[0] - dataq[1];
            
            // Delay so it is the same latency as order 4
            residual_d1 <= residual;
            residual_d2 <= residual_d1;
            residual_d3 <= residual_d2;
            residual_d4 <= residual_d3;
            residual_d5 <= residual_d4;
        end
    end
end
endmodule