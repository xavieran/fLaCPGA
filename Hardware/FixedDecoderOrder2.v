/*
 * Fmax: 940 MHz
 */

module FixedDecoderOrder2(input iClock,
                    input iReset, 
                    input iEnable, 
                    input signed [15:0] iSample, 
                    output signed [15:0] oData);
                        
reg signed [15:0] dataq0;
reg signed [15:0] dataq1;
reg signed [15:0] SampleD1;
reg [1:0] warmup_count;

assign oData = dataq0;

always @(posedge iClock)
begin
    
    if (iReset) begin
        warmup_count <= 2'b0;
        dataq0 <= 15'b0;
        dataq1 <= 15'b0;
    end else if (iEnable) begin
        SampleD1 <= iSample;
        
        dataq1 <= dataq0;
        
        if (warmup_count < 2'd2) begin
            dataq0 <= SampleD1;
        end else begin
            /* iSample + 2*dataq0 - dataq1
             * 2*dataq0 == dataq0 << 1
             * dataq0 << 1 == {dataq0, 1'b0 */
            dataq0 <= SampleD1 + {dataq0, 1'b0} - dataq1;
        end
    end
end
endmodule
