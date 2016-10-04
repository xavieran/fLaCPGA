
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

module TestStage4TB;

reg clk, ena, rst;
reg signed [15:0] sample;

reg read_file;
integer infile, i, fout, fout2;
integer cycles;

always begin
    #0 clk = 0;
    #10 clk = 1;
    #10 cycles = cycles + 1;
end

reg frame_done;
reg [3:0] m;
reg valid;
wire re1, re2;
wire [15:0] ra1, rd1, ra2, rd2;
Stage4_Compress s4 (
    .iClock(clk),
    .iEnable(ena),
    .iReset(rst),
    
    .iFrameDone(frame_done),
    .iM(m),
    .iValid(valid),
    .iResidual(sample),
    
    .oRamEnable1(re1),
    .oRamAddress1(ra1), 
    .oRamData1(rd1),
    
    .oRamEnable2(re2),
    .oRamAddress2(ra2), 
    .oRamData2(rd2)
    );

always @(posedge clk) begin
    if (read_file) begin
        $fscanf(infile, "%d\n", sample);
        valid <= 1;
    end 
end


initial begin
    infile = $fopen("test_stages_res_out.txt", "r");
    //fout = $fopen("test_stages_res_out.txt", "w");
    //fout2 = $fopen("ld_coefficients2.txt", "w");
    
    cycles = 0; rst = 1; ena = 0; valid = 0;frame_done = 0; m = 0;
    // Skip first 5 seconds of wake up
    //for (i = 0; i < 4096*50; i = i + 1) $fscanf(infile, "%d\n", sample);
    #20;
    read_file = 1; ena = 1; rst = 0; frame_done = 1; m = 7;
    #20; 
    frame_done = 0;
    for (i = 0; i < (4096 - m)*1; i = i + 1) #20;
    read_file = 0;
    valid = 0;
    #80;
    m = 4; frame_done = 1; read_file = 1;
    #20
    frame_done = 0;
    for (i = 0; i < (4096 - m)*1; i = i + 1) #20;
    
    #60
    
    $stop;
end


endmodule