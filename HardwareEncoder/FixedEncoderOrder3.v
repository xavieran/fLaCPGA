`ifndef FE3_H
`define FE3_H

module FixedEncoderOrder3 (input wire iClock, 
                           input wire iEnable,
                           input wire iReset,
                           input wire signed [15:0] iSample,
                           output wire signed [15:0] oResidual);
/* 
 * Latency is 8 cycles after enable signal
 */
 
reg signed [15:0] dataq [0:3];
reg signed [15:0] sample_r, termA, termB, termC, termCd1, termD;
reg signed [15:0] residual, residual_d1;

reg warmup;
reg warmup_d1, warmup_d2, warmup_d3, warmup_d4, warmup_d5;

integer i;

assign oResidual = residual_d1;

always @(posedge iClock)
begin
    if (iReset) begin
        sample_r <= 16'b0;
        
        warmup <= 1;
        warmup_d1 <= 0;
        warmup_d2 <= 0;
        warmup_d3 <= 0;
        warmup_d4 <= 0;
        warmup_d5 <= 0;
        
        for (i = 0; i <= 3; i = i + 1) begin
            dataq[i] <= 16'b0;
        end
        
        residual <= 16'b0;
        residual_d1 <= 16'b0;
        
        termA <= 16'b0;
        termB <= 16'b0;
        termC <= 16'b0;
        termCd1 <= 16'b0;
        termD <= 16'b0;
    end else if (iEnable) begin
        // Register the input
        sample_r <= iSample;
        
        // Shift the data queue down
        for (i = 1; i <= 3; i = i + 1) begin
            dataq[i] <= dataq[i - 1];
        end
        
        // Feed the queue
        dataq[0] <= sample_r;
        
        // Fill the queue and then wait 1 cycle
        if (!warmup_d5) begin
            warmup_d1 <= warmup;
            warmup_d2 <= warmup_d1;
            warmup_d3 <= warmup_d2;
            warmup_d4 <= warmup_d3;
            warmup_d5 <= warmup_d4;
        end else begin
            // Phase 1 of pipeline
            termA <= dataq[0] - dataq[3];
            termB <= (dataq[1] << 1) + dataq[1];
            termC <= (dataq[2] << 1) + dataq[2];
            
            // Phase 2 of pipeline
            termD <= termA - termB;
            termCd1 <= termC;
            
            // Phase 3 of pipeline
            residual <= termD + termCd1;
            
            // Delay so it is the same latency as order 4
            residual_d1 <= residual;
        end
    end
end
endmodule

// residual = data0 - 3data1 + 3data2 - data3
// termA = data0 - data3 | termB = data1 + data1 << 1 | termC = data2 + data2 << 1
// termD = termA - termB
// residual = termC + termD

`endif