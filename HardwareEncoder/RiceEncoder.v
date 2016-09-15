`ifndef RICE_ENCODER_H
`define RICE_ENCODER_H


module RiceEncoder (
    input wire iClock,
    input wire iReset,
    
    input wire iValid,
    input wire signed [15:0] iSample, 
    output wire [15:0] oMSB,
    output wire [15:0] oLSB, 
    output wire [15:0] oBitsUsed,
    output wire oValid
    );

parameter [3:0] rice_param = 4;

reg [15:0] sample, unsigned_sample;
reg [2:0] valid;
reg [15:0] msb, lsb, total;

assign oMSB = msb;
assign oLSB = lsb;
assign oBitsUsed = total;
assign oValid = valid[2];


always @(posedge iClock) begin
    if (iReset) begin
        sample <= 0;
        unsigned_sample <= 0;
        
        msb <= 0;
        lsb <= 0;
        total <= 0;
        
        valid <= 0;
    end else begin
        /* Register input */
        sample <= iSample;
        valid <= (valid << 1) | iValid;
        
        /* Convert sample to unsigned sample */
        //unsigned_sample <= {sample[14:0], 1'b0} ^ sample[15];
        
        
        if (sample[15]) begin
            unsigned_sample <= {sample[14:0], 1'b0} ^ 16'hffff;
        end else begin
            unsigned_sample <= {sample[14:0], 1'b0};
        end
        
        
        msb <= unsigned_sample[15:rice_param];
        lsb <=  {1'b1, unsigned_sample[rice_param - 1:0]};
        total <= unsigned_sample[15:rice_param] + rice_param + 1;
        
    end
end

endmodule

`endif