`ifndef FE4_H
`define FE4_H

module LPC_Encoder (input wire iClock, 
                           input wire iEnable,
                           input wire iReset,
                           input wire signed [15:0] iSample,
                           output wire signed [15:0] oResidual);
/* 
 * This is the slowest, i.e. longest latency, encoder
 * Latency is 8 cycles after enable signal
 */
 
reg signed [15:0] dataq [0:4];
reg signed [15:0] sample_r, termA, termB, termC, termCd1, termD;
reg signed [15:0] residual;
reg [2:0] warmup_count;

integer i;

assign oResidual = residual;

always @(posedge iClock)
begin
    if (iReset) begin
        sample_r <= 16'b0;
        warmup_count <= 0;
        for (i = 0; i <= 4; i = i + 1) begin
            dataq[i] <= 16'b0;
        end
        residual <= 16'b0;
        termA <= 16'b0;
        termB <= 16'b0;
        termC <= 16'b0;
        termD <= 16'b0;
        termCd1 <= 16'b0;
    end else if (iEnable) begin
        // Register the input
        sample_r <= iSample;
        
        // Shift the data queue down
        for (i = 1; i <= 4; i = i + 1) begin
            dataq[i] <= dataq[i - 1];
        end
        
        // Feed the queue
        dataq[0] <= sample_r;
        
        // Fill the queue and then wait 1 cycle to 
        if (warmup_count <= 5) begin
            warmup_count <= warmup_count + 1;
        end else begin
            // Unpipelined version runs at 150 MHz
            //residual <= dataq[0] - 4*dataq[1] + 6*dataq[2] - 4*dataq[3] + dataq[4]; 
            
            // Pipelined version runs at 350 MHz
            // Phase 1 of pipeline
            termA <= dataq[0] + dataq[4];
            termB <= (dataq[1] << 2) + (dataq[3] << 2);
            termC <= (dataq[2] << 2) + (dataq[2] << 1);
            
            // Phase 2 of pipeline
            termD <= termA - termB;
            termCd1 <= termC;
            
            // Phase 3 of pipeline
            residual <= termD + termCd1;
        end
    end
end
endmodule

// data = data0 - 4data1 + 6data2 - 4data3 + data4
// A = d0 + d4 | B = d1 << 2 + d3 << 2 | C = d2 << 2 + d2 << 1
// residual = A - B + C

`endif