
module FIR12TB;

reg clk, ena, rst;
integer i, infile, outfile;
integer cycles;

reg load, valid;
reg signed [11:0] coeff;
reg signed [15:0] sample;
wire signed [15:0] residual;
wire r_valid;


always begin
    #0 clk = 0;
    #10 clk = 1;
    #10 cycles = cycles + 1;
end


FIR12 f12 (
    .iEnable(ena),
    .iClock(clk),
    .iReset(rst),
    .iLoad(load), 
    .iQLP(coeff),
    .iValid(valid),
    .iSample(sample),
    .oResidual(residual),
    .oValid(r_valid)
    );

always @(posedge clk) begin
    if (r_valid) begin
        $fwrite(outfile,"%d\n", residual);
    end
end

initial begin
    cycles = 0;
    ena = 0; rst = 1; coeff = 0; sample = 0; load = 0; valid = 0;
    #30;
    coeff = -1;
    #20;
    ena = 1; rst = 0; load = 1;
    infile = $fopen("Pavane16Blocks.txt", "r");
    outfile = $fopen("filter_out.txt", "w");
    
    coeff = -206;
    #20;    
    coeff = 116;
    #20;
    coeff = 131;
    #20;
    coeff = 140;
    #20;
    coeff = 136;
    #20;
    coeff = -54;
    #20;
    coeff = -281;
    #20 ;
    coeff = -134;
    #20 ; 
    coeff = -517;
    #20; 
    coeff = 416;
    #20; 
    coeff = -154;
    #20;
    coeff = 1427;
    #20;
    /*
    coeff = 339;
    #20;
    coeff = 306;
    #20;
    coeff = -1664;
    #20;*/
    
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
    $stop;
end

endmodule