/* 
 * Fmax: 334.78 MHz
 */ 

module FixedDecoderOrder1(input iClock,
                    input iReset, 
                    input iEnable, 
                    input signed [15:0] iSample, 
                    output signed [15:0] oData);
                        
reg signed [15:0] dataq;
reg warmup_count;

reg signed [15:0] SampleD1;

assign oData = dataq;

always @(posedge iClock)
begin
    if (iReset) begin
        warmup_count <= 1'b0;
        dataq <= 15'b0;
    end else if (iEnable) begin
        SampleD1 <= iSample;
        
        if (warmup_count == 1'b0) begin
            dataq <= SampleD1;
            warmup_count <= 1'b1;
        end else begin
            dataq <= SampleD1 + dataq;
        end
    end
end
endmodule
