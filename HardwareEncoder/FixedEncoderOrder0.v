`ifndef FE0_H
`define FE0_H

module FixedEncoderOrder0 (input wire iClock, 
                           input wire iEnable,
                           input wire iReset,
                           input wire signed [15:0] iSample,
                           output wire signed [15:0] oResidual);
/* 
 * Registered to ensure latency is same as the other fixed encoders
 */
 
reg signed [15:0] dataq [0:7];
reg signed [15:0] sample_r;

integer i;

assign oResidual = dataq[7];

always @(posedge iClock)
begin
    if (iReset) begin
        sample_r <= 16'b0;
        for (i = 0; i <= 7; i = i + 1) begin
            dataq[i] <= 16'b0;
        end
    end else if (iEnable) begin
        // Register the input
        sample_r <= iSample;
        
        // Shift the data queue down 1
        for (i = 1; i <= 7; i = i + 1) begin
            dataq[i] <= dataq[i - 1];
        end
        
        // Push the sample into the data queue
        dataq[0] <= sample_r;
    end
end
endmodule

`endif