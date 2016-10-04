`ifndef VAR_RICE_ENCODER_H
`define VAR_RICE_ENCODER_H

module VariableRiceEncoder (
    input wire iClock,
    input wire iReset,
    
    input wire iValid,
    input wire signed [15:0] iSample, 
    
    input wire [3:0] iRiceParam,
    output wire [15:0] oMSB,
    output wire [15:0] oLSB, 
    output wire [15:0] oBitsUsed,
    output wire oValid
    );

reg [15:0] sample, unsigned_sample;
reg [2:0] valid;
reg [15:0] msb, lsb, total;
reg [3:0] rice_param, rp_l1, rp_l2;

assign oMSB = msb;
assign oLSB = lsb;
assign oBitsUsed = total;
assign oValid = valid[2];


always @(posedge iClock) begin
    if (iReset) begin
        sample <= 0;
        unsigned_sample <= 0;
        rice_param <= 0;
        rp_l1 <= 0;
        rp_l2 <= 0;
        msb <= 0;
        lsb <= 0;
        total <= 0;
        
        valid <= 0;
    end else begin
        rice_param <= iRiceParam;
        rp_l1 <= rice_param;
        rp_l2 <= rice_param;
        /* Register input */
        sample <= iSample;
        valid <= (valid << 1) | iValid;
        
        /* Convert sample to unsigned sample */
        if (sample[15]) begin
            unsigned_sample <= {sample[14:0], 1'b0} ^ 16'hffff;
        end else begin
            unsigned_sample <= {sample[14:0], 1'b0};
        end
        
        
        msb <= unsigned_sample >> rp_l2;
        lsb <= 1 << rp_l2 | unsigned_sample & ((1 << rp_l2) - 1);
        total <= (unsigned_sample >> rp_l2) + rp_l2 + 1;
        
    end
end

endmodule

`endif