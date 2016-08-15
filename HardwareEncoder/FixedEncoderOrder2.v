`ifndef FE2_H
`define FE2_H

module FixedEncoderOrder2 (input wire iClock, 
                           input wire iEnable,
                           input wire iReset,
                           input wire signed [15:0] iSample,
                           output wire signed [15:0] oResidual);
/* 
 * Latency is 8 cycles after enable signal
 */
 
reg signed [15:0] dataq [0:2];
reg signed [15:0] sample_r, termA, termB;
reg signed [15:0] residual, residual_d1, residual_d2, residual_d3;

reg warmup;
reg warmup_d1, warmup_d2, warmup_d3, warmup_d4;

integer i;

assign oResidual = residual_d3;

always @(posedge iClock)
begin
    if (iReset) begin
        sample_r <= 16'b0;
        
        warmup <= 1;
        warmup_d1 <= 0;
        warmup_d2 <= 0;
        warmup_d3 <= 0;
        warmup_d4 <= 0;
        
        for (i = 0; i <= 2; i = i + 1) begin
            dataq[i] <= 16'b0;
        end
        residual <= 16'b0;
        residual_d1 <= 16'b0;
        residual_d2 <= 16'b0;
        residual_d3 <= 16'b0;
        
        termA <= 16'b0;
        termB <= 16'b0;
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
        if (!warmup_d4) begin
            warmup_d1 <= warmup;
            warmup_d2 <= warmup_d1;
            warmup_d3 <= warmup_d2;
            warmup_d4 <= warmup_d3;
        end else begin
            
            // Pipelined version runs at 350 MHz
            // Phase 1 of pipeline
            termA <= dataq[0] + dataq[2];
            termB <= dataq[1] << 1;
            
            // Phase 2 of pipeline
            residual <= termA - termB;
            
            // Delay so it is the same latency as order 4
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

`endif
