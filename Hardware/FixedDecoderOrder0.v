/* 
 * Fmax: 940MHz
 */ 

module FixedDecoderOrder0(input iClock,
                    input iReset, 
                    input iEnable, 
                    input signed [15:0] iSample, 
                    output signed [15:0] oData);
                        
reg signed [15:0] dataq;
reg [3:0] warmup_count;
reg signed [15:0] SampleD1;

assign oData = dataq;

always @(posedge iClock)
begin
    if (iReset) begin
        dataq <= 0;
    end else if (iEnable) begin
        SampleD1 <= iSample;
        dataq <= SampleD1;
    end
end
endmodule
