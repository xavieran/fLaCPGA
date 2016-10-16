`default_nettype none

module fLaC_Encoder (
    input wire iClock,
    input wire iEnable, 
    input wire iReset,
    
    input wire  signed [15:0] iSample,
    input wire iValid,
    
    output wire [3:0] oM, 
    output wire signed [14:0] oModel,
    output wire oLoad,
    
    output wire oWValid, 
    output wire signed [15:0] oWarmup,
    
    output wire oFrameDone,
    output wire signed [15:0] oResidual, 
    output wire oRValid,
    
    output wire [31:0] oData,
    output wire oValid    
    );

wire s1_dvalid, s1_valid;
wire [63:0] s1_acf;
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

wire [14:0] s2_model;
wire [3:0] s2_m; 
wire s2_valid, s2_done, s2_dvalid;
wire [15:0] s2_dsample;
Stage2_FindModel s2 (
    .iClock(iClock),
    .iEnable(iEnable), 
    .iReset(iReset | s2_done),
    
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
wire s3_valid, s3_fd, s3_load, s3_wvalid;
wire [3:0] s3_m;
wire signed [14:0] s3_model;
wire signed [15:0] s3_warmup;

Stage3_Encode s3 (
    .iClock(iClock),
    .iEnable(iEnable), 
    .iReset(iReset),
    
    .iSample(s2_dsample),
    .iValid(s2_dvalid),
    
    .iLoad(s2_valid),
    .iModel(s2_model),
    .iM(s2_m),
    
    .oM(s3_m),
    .oModel(s3_model),
    .oLoad(s3_load),
    
    .oWValid(s3_wvalid), 
    .oWarmup(s3_warmup),
    
    .oResidual(s3_residual),
    .oValid(s3_valid), 
    .oFrameDone(s3_fd)
    );

wire re1, re2, s4_fd;
wire [15:0] ra1, ra2, rd1, rd2;
Stage4_Compress s4 (
    .iClock(iClock),
    .iEnable(iEnable), 
    .iReset(iReset),
    
    .iM(s3_m),
    .iFrameDone(s3_fd),
    .iValid(s3_valid),
    .iResidual(s3_residual),
    
    .oRamEnable1(re1),
    .oRamAddress1(ra1), 
    .oRamData1(rd1),
    
    .oRamEnable2(re2),
    .oRamAddress2(ra2), 
    .oRamData2(rd2),
    .oFrameDone(s4_fd)
    );

reg s5_clear;
wire [31:0] s5_data;
wire s5_valid;

Stage5_Output s5 (
    .iClock(iClock),
    .iEnable(iEnable),
    .iReset(iReset),
    .iClear(s5_clear),
    
    .iRamEnable1(re1),
    .iRamAddress1(ra1), 
    .iRamData1(rd1),
    
    .iRamEnable2(re2),
    .iRamAddress2(ra2), 
    .iRamData2(rd2),
    .iFrameDone(s4_fd),
    
    .oData(s5_data),
    .oValid(s5_valid)
    );

assign oData = s5_data;
assign oValid = s5_valid;

assign oLoad = s3_load;
assign oM = s3_m;
assign oModel = s3_model;

assign oWValid = s3_wvalid;
assign oWarmup = s3_warmup;

assign oResidual = s3_residual;
assign oRValid = s3_valid;
assign oFrameDone = s4_fd;

reg [12:0] clear_count;
always @(posedge iClock) begin
    if (iReset) begin
        s5_clear <= 1;
        clear_count <= 0;
    end else begin
        if (clear_count < 4096) begin
            clear_count <= clear_count + 1;
            s5_clear <= 1;
        end else begin
            clear_count <= clear_count;
            s5_clear <= 0;
        end
    end
end

endmodule