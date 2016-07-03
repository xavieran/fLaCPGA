`default_nettype none

module ChooseBestFixed(
    input wire iClock,
    input wire iEnable, 
    input wire iReset,
    input wire signed [15:0] iSample,
    output wire [2:0] oBest
    );

reg [2:0] best;
assign oBest = best;

wire signed [15:0] FE0_residual;
wire signed [15:0] FE1_residual;
wire signed [15:0] FE2_residual;
wire signed [15:0] FE3_residual;
wire signed [15:0] FE4_residual;

wire [15:0] FE0_res_abs = FE0_residual[15] ? -FE0_residual : FE0_residual;
wire [15:0] FE1_res_abs = FE1_residual[15] ? -FE1_residual : FE1_residual;
wire [15:0] FE2_res_abs = FE2_residual[15] ? -FE2_residual : FE2_residual;
wire [15:0] FE3_res_abs = FE3_residual[15] ? -FE3_residual : FE3_residual;
wire [15:0] FE4_res_abs = FE4_residual[15] ? -FE4_residual : FE4_residual;

/* Maximum error is 2^15-1 * 4096. This fits in a 27 bit number */
reg signed [27:0] FE0_error;
reg signed [27:0] FE1_error;
reg signed [27:0] FE2_error;
reg signed [27:0] FE3_error;
reg signed [27:0] FE4_error;

FixedEncoderOrder0 FEO0 (
      .iEnable(iEnable),
      .iReset(iReset),
      .iClock(iClock),
      .iSample(iSample),
      .oResidual(FE0_residual)); 

FixedEncoderOrder1 FEO1 ( 
      .iEnable(iEnable),
      .iReset(iReset),
      .iClock(iClock),
      .iSample(iSample),
      .oResidual(FE1_residual)); 

FixedEncoderOrder2 FEO2  ( 
      .iEnable(iEnable),
      .iReset(iReset),
      .iClock(iClock),
      .iSample(iSample),
      .oResidual(FE2_residual)); 

FixedEncoderOrder3 FEO3  ( 
      .iEnable(iEnable),
      .iReset(iReset),
      .iClock(iClock),
      .iSample(iSample),
      .oResidual(FE3_residual)); 

FixedEncoderOrder4 FEO4 ( 
      .iEnable(iEnable),
      .iReset(iReset),
      .iClock(iClock),
      .iSample(iSample),
      .oResidual(FE4_residual)); 


always @(posedge iClock) begin
    if (iReset) begin
        best = 0;
        FE0_error <= 0;
        FE1_error <= 0;
        FE2_error <= 0;
        FE3_error <= 0;
        FE4_error <= 0;
    end else if (iEnable) begin
        FE0_error <= FE0_error + FE0_res_abs;
        FE1_error <= FE1_error + FE1_res_abs;
        FE2_error <= FE2_error + FE2_res_abs;
        FE3_error <= FE3_error + FE3_res_abs;
        FE4_error <= FE4_error + FE4_res_abs;
        
        if (FE0_error < FE1_error && FE0_error < FE2_error
            && FE0_error < FE3_error && FE0_error < FE4_error) best <= 3'd0;
        
        if (FE1_error < FE0_error && FE1_error < FE2_error
            && FE1_error < FE3_error && FE1_error < FE4_error) best <= 3'd1;
        
        if (FE2_error < FE0_error && FE2_error < FE1_error
            && FE2_error < FE3_error && FE2_error < FE4_error) best <= 3'd2;
        
        if (FE3_error < FE0_error && FE3_error < FE1_error
            && FE3_error < FE2_error && FE3_error < FE4_error) best <= 3'd3;
        
        if (FE4_error < FE0_error && FE4_error < FE1_error
            && FE4_error < FE2_error && FE4_error < FE3_error) best <= 3'd4;
    end
end
endmodule
