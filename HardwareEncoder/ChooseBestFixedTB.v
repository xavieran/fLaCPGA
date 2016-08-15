`timescale 1ns/100ps

module ChooseBestFixedTB;

reg clk, ena, rst;
reg signed [15:0] sample;
wire [2:0] best;

integer infile, i;

wire signed [15:0] FE0_residual;
wire signed [15:0] FE1_residual;
wire signed [15:0] FE2_residual;
wire signed [15:0] FE3_residual;
wire signed [15:0] FE4_residual;

ChooseBestFixed cbf (
    .iClock(clk),
    .iEnable(ena), 
    .iReset(rst),
    .FE0_residual(FE0_residual),
    .FE1_residual(FE1_residual),
    .FE2_residual(FE2_residual),
    .FE3_residual(FE3_residual),
    .FE4_residual(FE4_residual),
    .oBest(best)
    );

FixedEncoderOrder0 FEO0 (
      .iEnable(ena),
      .iReset(rst),
      .iClock(clk),
      .iSample(sample),
      .oResidual(FE0_residual)); 

FixedEncoderOrder1 FEO1 ( 
      .iEnable(ena),
      .iReset(rst),
      .iClock(clk),
      .iSample(sample),
      .oResidual(FE1_residual)); 

FixedEncoderOrder2 FEO2  ( 
      .iEnable(ena),
      .iReset(rst),
      .iClock(clk),
      .iSample(sample),
      .oResidual(FE2_residual)); 

FixedEncoderOrder3 FEO3  ( 
      .iEnable(ena),
      .iReset(rst),
      .iClock(clk),
      .iSample(sample),
      .oResidual(FE3_residual)); 

FixedEncoderOrder4 FEO4 ( 
      .iEnable(ena),
      .iReset(rst),
      .iClock(clk),
      .iSample(sample),
      .oResidual(FE4_residual)); 

always begin
    #0 clk = 0;
    #10 clk = 1;
    #10 ;
end

initial begin
    ena = 0; rst = 1;
    #20;
    ena = 1; rst = 0;

    /* Open up the wave dump file */
    infile = $fopen("Pavane16Blocks.txt", "r");
    for (i = 0; i < 4096; i = i + 1) begin
        $fscanf(infile, "%d\n", sample);
        #20;
    end
    
    $fclose(infile);
    
    //#20 * 8
    #160;
    $stop;
end

endmodule