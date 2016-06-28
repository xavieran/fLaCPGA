module FixedEncoderOrder4 (input iClock, 
                           input iEnable,
                           input iReset,
                           input signed [15:0] iSample,
                           output signed [15:0] oResidual);
/* 
 * This is the slowest, i.e. longest latency, encoder
 */
 
reg signed [15:0] dataq [0:4];
reg signed [15:0] sample_r;
reg signed [15:0] residual;

reg [2:0] warmup_count;

integer i;

assign oResidual = residual;

always @(posedge iClock)
begin
    if (iReset) begin
        sample_r <= 0;
        warmup_count <= 0;
        for (i = 0; i <= 4; i = i + 1) begin
            dataq[i] <= 0;
        end
        residual <= 0;
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
            residual <= dataq[0] - 4*dataq[1] + 6*dataq[2] - 4*dataq[3] + dataq[4];
        end
    end
end
endmodule

// data = data0 - 4data1 + 6data2 - 4data3 + data4