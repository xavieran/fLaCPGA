
module RiceEncoder (
    input iClk,
    input iReset,
    input signed [15:0] iSample, 
    output [15:0] oMSB,
    output [15:0] oLSB, 
    output [16:0] oBitsUsed);

parameter [3:0] rice_param = 6;

reg [15:0] sample, unsigned_sample;

assign oMSB = unsigned_sample[15:rice_param];
assign oLSB = unsigned_sample[rice_param:0];
assign oBitsUsed = rice_param + oMSB;

always @(posedge iClk) begin
    if (iReset) begin
        sample <= 0;
        unsigned_sample <= 0;
    end else begin
        /* Register input */
        sample <= iSample;
        
        /* Convert sample to unsigned sample */
        unsigned_sample <= {sample[14:0], 1'b0} ^ sample[15];
    end
end

endmodule