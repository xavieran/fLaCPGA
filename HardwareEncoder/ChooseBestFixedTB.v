`timescale 1ns/100ps

module ChooseBestFixedTB;

reg clk, ena, rst;
reg signed [15:0] sample;
wire [2:0] best;

integer infile, i;

ChooseBestFixed cbf (
    .iClock(clk),
    .iEnable(ena), 
    .iReset(rst),
    .iSample(sample),
    .oBest(best)
    );

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