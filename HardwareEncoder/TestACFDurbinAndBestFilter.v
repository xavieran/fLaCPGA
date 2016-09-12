`include "Quantizer.v"
`include "GenerateAutocorrelation.v"
`include "fp_convert.v"
`include "FIR_FilterBank.v"
`include "fir_filters.v"
`include "Compare12.v"
`include "mf_fifo.v"
`include "mf_fifo1024.v"
`include "mf_fifo128.v"
`include "DelayRegister.v"

`define DFP(X) $bitstoshortreal(X)

module TestACFDurbinAndBestFilter;

reg clk;
reg signed [15:0] sample;
integer infile, i;
integer cycles;

wire [31:0] acf;
wire acf_valid;
reg acf_ena, acf_rst;

wire fifo1_empty, fifo1_full;
wire [15:0] fifo1_sample;
reg fifo1_read, fifo1_write;
wire [11:0] fifo1_usedw;

wire fifo2_empty, fifo2_full;
wire [15:0] fifo2_sample;
wire [15:0] fifo2_input;
wire [9:0] fifo2_usedw;

wire fifo3_empty, fifo3_full;
wire [15:0] fifo3_sample;
wire [6:0] fifo3_usedw;


GenerateAutocorrelation ga(
    .iClock(clk),
    .iEnable(acf_ena),
    .iReset(acf_rst),
    .iSample(sample),
    .oACF(acf),
    .oValid(acf_valid)
    );


reg db_ena, db_rst;
wire db_valid, db_done;
wire [31:0] db_model;
wire [3:0] db_m;

Durbinator db(
    .iClock(clk),
    .iEnable(db_ena | acf_valid), 
    .iReset(db_rst & !acf_valid),
    
    .iValid(acf_valid),
    .iACF(acf),
    
    .oM(db_m),
    .oModel(db_model),
    .oValid(db_valid),
    .oDone(db_done)
    );

wire signed [15:0] q_model;
wire q_valid;
wire [3:0] q_m;

Quantizer q (
    .iClock(clk),
    .iEnable(db_ena),
    .iReset(db_rst),
    .iValid(db_valid),
    .iM(db_m),
    .iFloatCoeff(db_model),
    .oQuantizedCoeff(q_model),
    .oValid(q_valid),
    .oM(q_m)
    );
    
wire [3:0] best;

FIR_FilterBank fir_fb (
    .iClock(clk), 
    .iEnable(db_ena), 
    .iReset(db_rst),
    
    .iLoad(q_valid),
    .iM(q_m),
    .iCoeff(q_model),
    
    .iValid(fifo1_read), 
    .iSample(fifo3_sample), 
    
    .oBestPredictor(best)
    );

mf_fifo fifo1 (
    .clock(clk),
    .data(sample),
    .rdreq((fifo1_usedw == 4095)),
    .wrreq(fifo1_write),
    .empty(fifo1_empty),
    .full(fifo1_full),
    .usedw(fifo1_usedw),
    .q(fifo1_sample));

DelayRegister #(.LENGTH(12)) dr (
    .iClock(clk), 
    .iEnable(fifo1_write), 
    .iData(fifo1_sample), 
    .oData(fifo2_input));

mf_fifo1024 fifo2 (
    .clock(clk),
    .data(fifo2_input),
    .rdreq((fifo2_usedw == 1023)),
    .wrreq((fifo1_usedw == 4095)),
    .empty(fifo2_empty),
    .full(fifo2_full),
    .usedw(fifo2_usedw),
    .q(fifo2_sample));

mf_fifo128 fifo3 (
    .clock(clk),
    .data(fifo2_sample),
    .rdreq(fifo3_usedw == 127),
    .wrreq((fifo2_usedw == 1023)),
    .empty(fifo3_empty),
    .full(fifo3_full),
    .usedw(fifo3_usedw),
    .q(fifo3_sample));

always begin
    #0 clk = 0;
    #10 clk = 1;
    #10 cycles = cycles + 1;
end

initial begin
    acf_ena = 0; acf_rst = 1; db_ena = 0; db_rst = 1;
    
    infile = $fopen("Pavane16Blocks.txt", "r");
    
    #30;
    fifo1_write = 1;
    #20;
    cycles = 0;
    acf_ena = 1; acf_rst = 0; fifo1_write = 1; fifo1_read = 0;
    for (i = 0; i < 4096; i = i + 1) begin
        $fscanf(infile, "%d\n", sample);
        #20;
    end
    
    while (!acf_valid) #20;
    db_ena = 1; db_rst = 0;
    while (acf_valid) begin
        $display("acf: %f", `DFP(acf));
        #20;
    end
    
    while (!db_done) begin
        if (db_valid) $display("%d %f", db_m, `DFP(db_model));
        if (q_valid) $display("quant: %d", q_model);
        #20;
    end
    
    while (q_valid) begin $display("quant: %d", q_model); #20; end
    
    fifo1_read = 1; // Start writing out from the fifo
    for (i = 0; i < 78; i = i + 1) begin
        #20;
    end
    
    for (i = 0; i < 4096; i = i + 1) begin
        #20;
    end
    $stop;
end
    
    
endmodule;