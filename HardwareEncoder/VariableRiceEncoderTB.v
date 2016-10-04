
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

module VariableRiceEncoderTB;

reg clk, rst;
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
reg signed [15:0] residual;

reg [3:0] vre_rp;
wire [15:0] vre_msb, vre_lsb, vre_bu;
wire vre_valid;

VariableRiceEncoder vre (
    .iClock(clk),
    .iReset(rst),
    
    .iValid(valid),
    .iSample(residual), 
    
    .iRiceParam(vre_rp),
    .oMSB(vre_msb),
    .oLSB(vre_lsb), 
    .oBitsUsed(vre_bu),
    .oValid(vre_valid)
    );
 
 /*
reg [15:0] output_count;
always @(posedge clk) begin
    if (read_file) begin
        $fscanf(infile, "%d\n", residual);
        valid <= 1;
    end
    
    if (ro_done) begin
        rst = 1;
    end else begin
        rst = 0;
    end
end*/

initial begin
    infile = $fopen("test_stages_res_out.txt", "r");
    //infile = $fopen("wakeup_pcm.txt", "r");
    //fout = $fopen("test_stages_res_out.txt", "w");
    //fout2 = $fopen("ld_coefficients2.txt", "w");
    valid = 0; read_file = 0; rst = 1;
    cycles = 0;
    #30
    // Skip first 5 seconds of wake up
    //for (i = 0; i < 4096*50; i = i + 1) $fscanf(infile, "%d\n", sample);
    #20;
    rst = 0;
    valid = 1;
    vre_rp = 0;
    residual = 20;
    #20
    vre_rp = 4;
    residual = -123;
    #100
    
    $stop;
end

endmodule