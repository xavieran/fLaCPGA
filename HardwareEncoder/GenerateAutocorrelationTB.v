`timescale 1ns/100ps
`define MY_SIMULATION 1

`define DFP(X) $bitstoshortreal(X)

module GenerateAutocorrelationTB;

reg clk, ena, rst;
reg signed [15:0] sample;

integer infile, i;

wire signed [31:0] acf;
wire valid;
GenerateAutocorrelation ga(
    .iClock(clk),
    .iEnable(ena), 
    .iReset(rst),
    
    .iSample(sample),

    .oACF(acf),
    .oValid(valid)
    );

always begin
    #0 clk = 0;
    #10 clk = 1;
    #10 ;
end

initial begin
    ena = 0; rst = 1;


    // Fill the internal sample RAM
    infile = $fopen("Pavane16Blocks.txt", "r");
    /* skip the first block...
    for (i = 0; i < 4096; i = i + 1) begin
        $fscanf(infile, "%d\n", sample);
    end*/
    
    #30;
    ena = 1; rst = 0;
    for (i = 0; i < 4096; i = i + 1) begin
        $fscanf(infile, "%d\n", sample);
        #20;
    end
    
    /*
    for (i = 0; i < 4096; i = i + 1) begin
        $fscanf(infile, "%d\n", sample);
        #20;
    end*/
    
    /* Step 2 - Division */
    ena = 1; rst = 0;
    for (i = 0; i < 60; i = i + 1) begin
        if (valid) $display("%f", `DFP(acf));
        #20;
    end
    $stop;
end

endmodule