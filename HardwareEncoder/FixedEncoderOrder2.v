module FixedEncoderOrder2 (input iClock, 
                           input iEnable,
                           input iReset,
                           input signed [15:0] iSample,
                           output signed [15:0] oResidual);
/* 
 * This is the slowest, i.e. longest latency, encoder
 * Latency is 8 cycles after enable signal
 */
 
reg signed [15:0] dataq [0:2];
reg signed [15:0] sample_r, termA, termB, termC, termCd1, termD;
reg signed [15:0] residual, residual_d1, residual_d2, residual_d3;
reg [2:0] warmup_count;

integer i;

assign oResidual = residual_d3;

always @(posedge iClock)
begin
    if (iReset) begin
        sample_r <= 0;
        warmup_count <= 0;
        for (i = 0; i <= 2; i = i + 1) begin
            dataq[i] <= 0;
        end
        residual <= 0;
        residual_d1 <= 0;
        residual_d2 <= 0;
        residual_d3 <= 0;
        
        termA <= 0;
        termB <= 0;
        termC <= 0;
        termCd1 <= 0;
        termD <= 0;
    end else if (iEnable) begin
        // Register the input
        sample_r <= iSample;
        
        // Shift the data queue down
        for (i = 1; i <= 2; i = i + 1) begin
            dataq[i] <= dataq[i - 1];
        end
        
        // Feed the queue
        dataq[0] <= sample_r;
        
        // Fill the queue and then wait 1 cycle to sample the latest data point
        if (warmup_count <= 3) begin
            warmup_count <= warmup_count + 1;
        end else begin
            
            // Pipelined version runs at 350 MHz
            // Phase 1 of pipeline
            termA <= dataq[0] + dataq[2];
            termB <= data1 << 1;
            
            // Phase 3 of pipeline
            residual <= termA - termB;
            
            // Slow down so it is the same latency as order 4
            residual_d1 <= residual;
            residual_d2 <= residual_d1;
            residual_d3 <= residual_d2;
        end
    end
end
endmodule
// residual = data0 - 2data1 + data2
// termA = data0 + data2 | termB = data1 << 1;
// residual = termA + termB