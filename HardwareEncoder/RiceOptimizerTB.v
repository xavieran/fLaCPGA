
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

module RiceOptimizerTB;

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

reg ro_ena;

wire ro_done;
wire [3:0] ro_best;

RiceOptimizer ro (
    .iClock(clk),
    .iEnable(ro_ena), 
    .iReset(rst),
    
    .iValid(valid),
    .iResidual(residual),
    
    .oDone(ro_done),
    .oBest(ro_best)
    );
 
 
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
end

initial begin
    infile = $fopen("test_stages_res_out.txt", "r");
    //infile = $fopen("wakeup_pcm.txt", "r");
    //fout = $fopen("test_stages_res_out.txt", "w");
    //fout2 = $fopen("ld_coefficients2.txt", "w");
    valid = 0; read_file = 0; ro_ena = 0; rst = 1;
    cycles = 0;
    #30
    // Skip first 5 seconds of wake up
    //for (i = 0; i < 4096*50; i = i + 1) $fscanf(infile, "%d\n", sample);
    #20;
    ro_ena = 1; rst = 0;
    read_file = 1;
    for (i = 0; i < 4096*4; i = i + 1) #20;
    #20;
    
    //for (i = 0; i < 4096*16; i = i + 1) #20;
    read_file = 0;
    valid = 0;
    
    for (i = 0; i < 10*1; i = i + 1) #20;
    
    #60
    
    $stop;
end

endmodule