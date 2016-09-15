`timescale 1ns/100ps
`define MY_SIMULATION 1

`include "RiceEncoder.v"

module RiceWriterTB;

reg clk, ena, rst;
integer i, fin, fout, fsplit;
integer cycles;

wire [15:0] upper, lower;
reg [3:0] param;
wire re_valid;
reg sample_valid;

wire [15:0] total;
reg signed [15:0] sample;

wire ram_en1;
wire [15:0] ram_ad1;
wire [15:0] ram_dat1; // REVERSED FOR PRINTING 
wire ram_en2;
wire [15:0] ram_ad2;
wire [15:0] ram_dat2;

RiceEncoder re (
    .iClock(clk), 
    .iReset(rst),
    .iValid(sample_valid), 
    .iSample(sample),
    .oMSB(upper), 
    .oLSB(lower),
    .oBitsUsed(total),
    .oValid(re_valid)
    );

RiceWriter rw (
    .iClock(clk),
    .iReset(rst), 
    .iEnable(re_valid), 
    
    .iTotal(total),
    .iUpper(upper),
    .iLower(lower), 
    .iRiceParam(param),
    
    .oRamEnable1(ram_en1),
    .oRamAddress1(ram_ad1), 
    .oRamData1(ram_dat1),
    
    .oRamEnable2(ram_en2),
    .oRamAddress2(ram_ad2), 
    .oRamData2(ram_dat2)
    );


always begin
    #0 clk = 0;
    #10 clk = 1;
    #10 cycles = cycles + 1;
end

reg flip;
reg [15:0] prior;

// We have to do a bunch of byte swapping in order to get it to 
// it in the order FLAC wants.. little endian or something?
wire [7:0] ram_dat1a, ram_dat1b, priora, priorb;
assign ram_dat1a = ram_dat1[15:8];
assign ram_dat1b = ram_dat1[7:0];
assign priora = prior[15:8];
assign priorb = prior[7:0];
wire [31:0] write_out = {ram_dat1b, ram_dat1a, priorb, priora};

always @(negedge clk) begin
    if (re_valid) begin
        $fwrite(fsplit, "%d %d\n", upper, lower[3:0]);
    end

    if (ram_en1 && ram_en2) begin
        flip <= !flip;
        if (flip)
            $fwrite(fout, "%u", write_out);
        else 
            prior <= ram_dat2;
    end else if (ram_en1) begin
        flip <= !flip;
        if (flip)
            $fwrite(fout, "%u", write_out);
        else 
            prior <= ram_dat1;
    end
end

initial begin
    flip = 0;
    cycles = 0;
    rst = 1; ena = 0; 
    sample_valid = 0;
    #30
    param = 4;
    //lower = 0; upper = 0;
    fsplit = $fopen("rice_pairs.txt", "w");
    fout = $fopen("rice_residuals.txt", "wb");
    fin = $fopen("residual_pipelined.txt", "r");
    rst = 0; ena = 1;
    #20;
    sample_valid = 1;
    for (i = 0; i < 4096; i = i + 1) begin
        $fscanf(fin, "%d\n", sample);
        #20;
    end
    #20;
    #20;
    #20;
    /*
    upper = 4; lower = 5'b11011;
    #20;
    upper = 2; lower = 5'b10011;
    #20;
    upper = 12; lower = 5'b11001;
    #20;
    upper = 22; lower = 5'b11011;
    #20;
    upper = 33; lower = 5'b10001;
    #20;
    upper = 10; lower = 5'b11101;
    #20;*/
    /*
    #20;
    lower = 5'b11100;
    upper = 5;    
    #20;
    lower = 5'b10011;
    upper = 3;
    #20;
    lower = 5'b11001;
    upper = 0;
    #20;
    upper = 10;
    lower = 5'b11101;
    #20;
    upper = 4; 
    lower = 5'b10111;
    #20;
    */
    $stop;
    
    $fclose(fin);$fclose(fout);$fclose(fsplit);
end

endmodule