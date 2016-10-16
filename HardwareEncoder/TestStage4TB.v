
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
`include "dual_write_ram.v"

`include "Stage5_Output.v"

module TestStage4TB;

reg clk, ena, rst;
reg signed [15:0] sample;

reg read_file;
integer infile, i, j, fout, fout2;
integer cycles;

always begin
    #0 clk = 0;
    #10 clk = 1;
    #10 cycles = cycles + 1;
end

reg clear;
reg [15:0] last_ram_address;
reg frame_done;
reg [3:0] m;
reg valid;
wire re1, re2;
wire [15:0] ra1, rd1, ra2, rd2;
wire s4_fd;


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
    .oRamData2(rd2),
    .oFrameDone(s4_fd)
    );


wire [31:0] data_out;
wire data_valid;
reg s5_ena;
Stage5_Output s5 (
    .iClock(clk),
    .iEnable(s5_ena),
    .iReset(rst),
    .iClear(clear),
    
    .iRamEnable1(re1),
    .iRamAddress1(ra1), 
    .iRamData1(rd1),
    
    .iRamEnable2(re2),
    .iRamAddress2(ra2), 
    .iRamData2(rd2),
    
    .iFrameDone(s4_fd),
    
    .oData(data_out),
    .oValid(data_valid)
    );

/*
wire [7:0] ram_dat1a, ram_dat1b, ram_dat2a, ram_dat2b;
assign ram_dat1a = q1[15:8];
assign ram_dat1b = q1[7:0];
assign ram_dat2a = q2[15:8];
assign ram_dat2b = q2[7:0];
wire [31:0] encoded_out;
//assign encoded_out = {ram_dat1b, ram_dat1a, ram_dat2b, ram_dat2a};
assign encoded_out = {ram_dat2b, ram_dat2a, ram_dat1b, ram_dat1a};
*/

always @(posedge clk) begin
    if (data_valid) begin
        $fwrite(fout, "%u", data_out);
    end
end

initial begin
    infile = $fopen("residuals.txt", "r");
    fout = $fopen("encoded_res.txt", "w");
    //fout2 = $fopen("ld_coefficients2.txt", "w");
    
    // Reset stuff
    cycles = 0; rst = 1; s5_ena = 0; ena = 0; valid = 0;frame_done = 0; m = 0;
    #20;
    #10;
    
    // Clear the RAMs in s5
    s5_ena = 1;rst = 0; clear = 1;
    for (i = 0; i < 2048; i = i + 1) #20;
    clear = 0;
    ena = 1; 
    
    // !!!!!! One frame to find best param
    // Blip the frame done signal
    frame_done = 1; m = 0;
    #20;
    frame_done = 0;
    #20
    for (i = 0; i < (4096 - m); i = i + 1) begin
        valid = 1;
        $fscanf(infile, "%d\n", sample);
        #20;
    end
    valid = 0;
    #100;
    
    for (j = 0; j < 256; j = j + 1) begin
        // !!! One frame to encode with best param
        frame_done = 1; m = 0;
        #20;
        frame_done = 0;
        #20
        for (i = 0; i < (4096 - m); i = i + 1) begin
            valid = 1;
            $fscanf(infile, "%d\n", sample);
            #20;
        end
        valid = 0;
        #100;
    end
end


endmodule
