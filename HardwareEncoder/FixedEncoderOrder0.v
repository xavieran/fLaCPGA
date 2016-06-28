module FixedEncoderOrder0 (input iClock, 
                           input iEnable,
                           input iReset,
                           input signed [15:0] iSample,
                           output signed [15:0] oData);
/* 
 * Registered to ensure latency is same as the other fixed encoders
 */
 
reg signed [15:0] dataq [0:3];
reg signed [15:0] sample_r;

integer i;

assign oData = dataq[3];

always @(posedge iClock)
begin
    if (iReset) begin
        sample_r <= 0;
        for (i = 0; i < 4; i = i + 1) begin
            dataq[i] <= 0;
        end
    end else if (iEnable) begin
        // Register the input
        sample_r <= iSample;
        
        // Shift the data queue down 1
        for (i = 1; i < 4; i = i + 1) begin
            dataq[i] <= dataq[i - 1];
        end
        
        // Push the sample into the data queue
        dataq[0] <= sample_r;
    end
end
endmodule