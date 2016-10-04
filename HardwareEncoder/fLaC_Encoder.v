

module fLaC_Encoder (
    input wire iClock,
    input wire iEnable, 
    input wire iReset,
    
    input wire  signed [15:0] iSample,
    input wire iValid,
    
    //output wire signed [15:0] oResidual,
    //output wire oValid    
    output wire oRamEnable1,
    output wire [15:0] oRamAddress1, 
    output wire [15:0] oRamData1,
    
    output wire oRamEnable2,
    output wire [15:0] oRamAddress2, 
    output wire [15:0] oRamData2
    );

wire s1_dvalid, s1_valid;
wire [42:0] s1_acf;
wire signed [15:0] s1_dsample;

Stage1_Autocorrelation s1 (
    .iClock(iClock),
    .iEnable(iEnable), 
    .iReset(iReset),
    
    .iSample(iSample),
    .iValid(iValid),
    .oDSample(s1_dsample),
    .oDValid(s1_dvalid), 
    
    .oACF(s1_acf),
    .oValid(s1_valid)
    );

wire [11:0] s2_model;
wire [3:0] s2_m; 
wire s2_valid, s2_done;
Stage2_FindModel s2 (
    .iClock(iClock),
    .iEnable(iEnable), 
    .iReset(iReset),
    
    .iSample(s1_dsample),
    .iSValid(s1_dvalid),
    .oDSample(s2_dsample),
    .oDValid(s2_dvalid),
    
    .iACF(s1_acf),
    .iValid(s1_valid),
    
    .oModel(s2_model),
    .oM(s2_m), 
    .oValid(s2_valid),
    .oDone(s2_done)
    );

wire signed [15:0] s3_residual;
wire s3_valid;

Stage3_Encode s3 (
    .iClock(iClock),
    .iEnable(iEnable), 
    .iReset(iReset),
    
    .iSample(s1_dsample),
    .iValid(s1_dvalid),
    
    .iLoad(s2_valid),
    .iModel(s2_model),
    .iM(s2_m),
    
    .oResidual(s3_residual),
    .oValid(s3_valid)
    );

wire re1, re2;
wire [15:0] ra1, ra2, rd1, rd2;
Stage4_Compress s4 (
    .iClock(iClock),
    .iEnable(iEnable), 
    .iReset(iReset),
    
    .iValid(s3_valid),
    .iResidual(s3_valid),
    
    .oRamEnable1(re1),
    .oRamAddress1(ra1), 
    .oRamData1(rd1),
    
    .oRamEnable2(re2),
    .oRamAddress2(ra2), 
    .oRamData2(rd2)
    );

assign oRamEnable1 = re1;
assign oRamEnable2 = re2;
assign oRamAddress1 = ra1;
assign oRamAddress2 = ra2;
assign oRamData1 = rd1;
assign oRamData2 = rd2;

endmodule