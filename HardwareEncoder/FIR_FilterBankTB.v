
module FIR_FilterBankTB;

reg clk, ena, rst;
integer i, infile, outfile, ldfile;
integer cycles;

reg load, valid;
reg signed [11:0] coeff;
reg signed [15:0] sample;
reg [3:0] m;
wire [3:0] best;

always begin
    #0 clk = 0;
    #10 clk = 1;
    #10 cycles = cycles + 1;
end

FIR_FilterBank fir_fb (
    .iClock(clk), 
    .iEnable(ena), 
    .iReset(rst),
    
    .iLoad(load),
    .iM(m),
    .iCoeff(coeff),
    
    .iValid(valid), 
    .iSample(sample), 
    
    .oBestPredictor(best)
    );

initial begin
    cycles = 0;
    ena = 0; rst = 1; coeff = 0; sample = 0; load = 0; valid = 0;
    #30;
    coeff = -1;
    #20;
    ena = 1; rst = 0;
    ldfile = $fopen("ld_coefficients.txt", "r");
    infile = $fopen("Pavane16Blocks.txt", "r");
    #20;
    for (i = 0; i < 78; i = i + 1) begin
        $fscanf(ldfile, "%d %d\n", m, coeff);
        load = 1;
        #20;
    end
    load = 0;
    
    #100;
    
    valid = 1;
    for (i = 0; i < 4096; i = i + 1) begin
        $fscanf(infile, "%d\n", sample);
        #20;
    end
    valid = 0;
    
    for (i = 0; i < 20; i = i + 1) #20;
    
    $fclose(infile);
    $fclose(outfile);
    $display("Best predictor: %d", best);
    $stop;
end

endmodule