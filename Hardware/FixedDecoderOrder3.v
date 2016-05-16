/* 
 * FMax: 300MHz
 */
module FixedDecoderOrder3(input iClock,
                    input iReset, 
                    input iEnable, 
                    input signed [15:0] iSample, 
                    output signed [15:0] oData);
                        
reg signed [15:0] dataq0, dataq1, dataq2;
reg signed [15:0] SampleD1, dataq0d2;
reg signed [15:0] term1, term2, term3, term3d1, term4;

reg [3:0] warmup_count;

assign oData = dataq0d2;

always @(posedge iClock)
begin
    if (iReset) begin
        warmup_count <= 4'b0;
        SampleD1 <= 15'b0;
        dataq0 <= 15'b0;
        dataq1 <= 15'b0;
        dataq2 <= 15'b0;
        
        dataq0d2 <= 0;
        term1 <= 0;
        term2 <= 0;
        term3 <= 0;
        term3d1 <= 0;
        term4 <= 0;
        
    end else if (iEnable) begin
        SampleD1 <= iSample;
        
        dataq2 <= dataq1;
        dataq1 <= dataq0;
        dataq0 <= dataq0d2;
        
        if (warmup_count <= 4'd3) begin
            dataq0 <= SampleD1;
            warmup_count <= warmup_count + 1'b1;
        end else begin
            /* dataq0 <= SampleD1 + 15'd3*dataq0 - 15'd3*dataq1 + dataq2; 
             * == (SampleD1 + dataq2) + 3*dataq0 - 3*dataq1
             * == term1 + term2 - term3
             * == (term1 + term2) $$ term3d1
             * == term4 - term3d1
             */
             
            /* Clock 1. */
            term1 <= SampleD1 + dataq2; 
            term2 <= 3*dataq0;          
            term3 <= 3*dataq1;
            
            /* Clock 2. */
            term3d1 <= term3;
            term4 <= term1 + term2;
            
            /* Clock 3. */
            dataq0d2 <= term4 - term3d1;
        end
    end
end
endmodule
