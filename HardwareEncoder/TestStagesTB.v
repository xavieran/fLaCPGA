
`include "Stage2_FindModel.v"
`include "Quantizer.v"
`include "ACFDivider.v"
`include "fp_divider.v"
`include "Durbinator.v"
`include "register_file.v"
`include "ModelSelector.v"
`include "AlphaCalculator2.v"
`include "CalculateKAndError.v"
`include "GenerateAutocorrelationSums.v"

`include "fp_convert.v"
`include "fp_add_sub.v"
`include "fp_mult.v"
`include "FIR_FilterBank.v"
`include "fir_filters.v"
`include "Compare12.v"
`include "mf_fifo.v"
`include "mf_fifo1024.v"
`include "mf_fifo128.v"
`include "DelayRegister.v"
`include "TappedDelayRegister.v"

`include "Stage3_Encode.v"
`include "DurbinCoefficientStore.v"
`include "RiceWriter.v"
`include "RiceEncoder.v"

module TestStagesTB;

reg clk;
reg signed [15:0] sample;

reg read_file;
integer infile, i, fout, fout2;
integer cycles;

always begin
    #0 clk = 0;
    #10 clk = 1;
    #10 cycles = cycles + 1;
end

reg valid;
reg s1_ena, s1_rst, s3_rst;
wire signed [15:0] s1_dsample;
wire s1_dvalid;

wire [42:0] s1_acf;
wire s1_valid;

Stage1_Autocorrelation s1_a (
    .iClock(clk),
    .iEnable(s1_ena), 
    .iReset(s1_rst),
    
    .iSample(sample),
    .iValid(valid),
    .oDSample(s1_dsample),
    .oDValid(s1_dvalid), 
    
    .oACF(s1_acf),
    .oValid(s1_valid)
    );

wire signed [15:0] s2_dsample;
wire s2_dvalid;
wire s2_valid,s2_done;
wire signed [11:0] s2_model;
wire [3:0] s2_m;

Stage2_FindModel s2_fm(
    .iClock(clk),
    .iEnable(s1_ena), 
    .iReset(s1_rst | s2_done),
    
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

wire s3_valid;
wire signed [15:0] residual;
Stage3_Encode s3_e(
    .iClock(clk),
    .iEnable(s1_ena),
    .iReset(s3_rst),
    
    .iValid(s2_dvalid),
    .iSample(s2_dsample),
    
    .iLoad(s2_valid),
    .iModel(s2_model),
    .iM(s2_m), 
    
    .oResidual(residual),
    .oValid(s3_valid)
    );

/*
wire s3_re1, s3_re2;
wire [15:0] s3_ra1, s3_ra2, s3_rd1, s3_rd2;

    .oRamEnable1(s3_re1),
    .oRamAddress1(s3_ra1), 
    .oRamData1(s3_rd1),
    
    .oRamEnable2(s3_re2),
    .oRamAddress2(s3_ra2), 
    .oRamData2(s3_rd2)*/

reg [15:0] output_count;
always @(posedge clk) begin
    if (read_file) begin
        $fscanf(infile, "%d\n", sample);
        valid <= 1;
    end
end

always @(posedge clk) begin
    if (s2_valid) begin
        $display("MODEL: %d -- %d", s2_m, s2_model);
    end
end

always @(posedge clk) begin
    if (s3_valid) begin
        $fwrite(fout, "%d\n", residual);
        output_count <= output_count + 1;
    end 
end


initial begin
    infile = $fopen("Pavane16Blocks.txt", "r");
    //infile = $fopen("wakeup_pcm.txt", "r");
    fout = $fopen("test_stages_res_out.txt", "w");
    //fout2 = $fopen("ld_coefficients2.txt", "w");
    s1_ena = 0; s1_rst = 1; valid = 0; read_file = 0; s3_rst = 1;output_count = 0;
    cycles = 0;
    #30
    // Skip first 5 seconds of wake up
    //for (i = 0; i < 4096*50; i = i + 1) $fscanf(infile, "%d\n", sample);
    #20;
    read_file = 1;
    s1_rst = 0; s1_ena = 1;s3_rst = 0;
    for (i = 0; i < 4096*16; i = i + 1) #20;
    read_file = 0;
    valid = 0;
    
    for (i = 0; i < 4096*1; i = i + 1) #20;
    
    #60
    
    $stop;
end

endmodule