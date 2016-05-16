module FixedDecoder(input iClock,
                    input iReset, 
                    input iEnable, 
                    input [3:0] iOrder, 
                    input signed [15:0] iSample, 
                    output signed [15:0] oData);
                        
reg signed [15:0] dataq [0:4];
reg [3:0] warmup_count;

assign oData = dataq[0];

always @(posedge iClock)
begin
    if (iReset) begin
        warmup_count <= 4'b0;
        dataq[0] <= 15'b0;
        dataq[1] <= 15'b0;
        dataq[2] <= 15'b0;
        dataq[3] <= 15'b0;
        dataq[4] <= 15'b0;
    end else if (iEnable) begin
        dataq[4] <= dataq[3];
        dataq[3] <= dataq[2];
        dataq[2] <= dataq[1];
        dataq[1] <= dataq[0];
        
        if (warmup_count < iOrder) begin
            dataq[0] <= iSample;
            warmup_count <= warmup_count + 1'b1;
        end else if (iOrder == 3'd0) begin
            dataq[0] <= iSample;
        end else if (iOrder == 3'd1) begin
            dataq[0] <= iSample + dataq[0]; 
        end else if (iOrder == 3'd2) begin
            dataq[0] <= iSample + 15'd2*dataq[0] - dataq[1];    
        end else if (iOrder == 3'd3) begin
            dataq[0] <= iSample + 15'd3*dataq[0] - 15'd3*dataq[1] + dataq[2];   
        end else if (iOrder == 3'd4) begin
            dataq[0] <= iSample + 15'd4*dataq[0] - 15'd6*dataq[1] + 15'd4*dataq[2] - dataq[3];  
        end
    end
end
endmodule
