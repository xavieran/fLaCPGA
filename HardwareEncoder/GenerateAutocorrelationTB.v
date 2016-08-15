`timescale 1ns/100ps
`define MY_SIMULATION 1

module GenerateAutocorrelationTB;

reg clk, ena, rst;
reg signed [15:0] sample;

integer infile, i;

wire signed [31:0] acf0, acf1, acf2, acf3;

GenerateAutocorrelation ga(
    .iClock(clk),
    .iEnable(ena), 
    .iReset(rst),
    
    .iSample(sample),

    .oACF0(acf0),
    .oACF1(acf1),
    .oACF2(acf2),
    .oACF3(acf3)
    );

always begin
    #0 clk = 0;
    #10 clk = 1;
    #10 ;
end

initial begin
    ena = 0; rst = 1;
    #30;
    ena = 1; rst = 0;

    // Fill the internal sample RAM
    infile = $fopen("Pavane16Blocks.txt", "r");
    for (i = 0; i < 4096; i = i + 1) begin
        $fscanf(infile, "%d\n", sample);
        #20;
    end
    #10
    $fclose(infile);
    
    /* Step 2 - Division */
    #20;
    ena = 1; rst = 0;
    for (i = 0; i < 14 + 7 + 5; i = i + 1) begin
        #20;
    end
    $stop;
end

endmodule