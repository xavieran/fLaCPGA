/*
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
`include "TappedDelayRegister.v"
`include "DurbinCoefficientStore.v"*/

`define DFP(X) $bitstoshortreal(X)

module CompressData(
    input wire clk,
    input wire [15:0] sample,
    output wire [15:0] oResidual
    );



wire [31:0] acf;
wire acf_valid;
reg acf_ena, acf_rst;

wire fifo1_empty, fifo1_full;
wire signed [15:0] fifo1_sample;
reg fifo1_read, fifo1_write;
wire [11:0] fifo1_usedw;

wire fifo2_empty, fifo2_full;
wire signed [15:0] fifo2_sample;
wire signed [15:0] fifo2_input;
wire [9:0] fifo2_usedw;

wire fifo3_empty, fifo3_full;
wire signed [15:0] fifo3_sample;
wire [6:0] fifo3_usedw;

wire fifo4_empty, fifo4_full;
wire [15:0] fifo4_in;
wire signed [15:0] fifo4_sample;
wire [11:0] fifo4_usedw;

reg ds_unload;
wire signed [11:0] ds_coeff;
wire ds_valid;

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
//reg [3:0] best;
reg fir_fb_valid;

FIR_FilterBank fir_fb (
    .iClock(clk), 
    .iEnable(db_ena), 
    .iReset(db_rst),
    
    .iLoad(q_valid),
    .iM(q_m),
    .iCoeff(q_model),
    
    .iValid(fir_fb_valid), 
    .iSample(fifo4_in),
    
    .oBestPredictor(best)
    );

DurbinCoefficientStore durb_store (
    .iClock(clk), 
    .iEnable(db_ena),
    .iReset(db_rst), 
    .iLoad(q_valid), 
    .iM(q_m), 
    .iCoeff(q_model), 
    
    .iUnload(ds_unload), 
    .iBestM(best),
    
    .oCoeff(ds_coeff),
    .oValid(ds_valid));

reg f12_ena, f12_rst, f12_calc;
wire signed [15:0] f12_sample;
wire signed [15:0] f12_residual;
wire f12_valid;

FIRX f12 (
    .iEnable(f12_ena),
    .iClock(clk),
    .iReset(f12_rst),
    .iLoad(ds_valid),
    .iQLP(ds_coeff),
    .iM(best),
    .iValid(f12_calc),
    .iSample(f12_sample),
    .oResidual(f12_residual), 
    .oValid(f12_valid)
    );

/* 4096 cycles through the ACF calculator */
mf_fifo fifo1 (
    .clock(clk),
    .data(sample),
    .rdreq((fifo1_usedw == 4095)),
    .wrreq(fifo1_write),
    .empty(fifo1_empty),
    .full(fifo1_full),
    .usedw(fifo1_usedw),
    .q(fifo1_sample));

/* 12 cycles to copy the ACF coefficients into the Durbinator */
DelayRegister #(.LENGTH(12)) dr1 (
    .iClock(clk), 
    .iEnable(fifo1_write), 
    .iData(fifo1_sample), 
    .oData(fifo2_input));

/* 1024 + 128 cycles to calculate the model coefficients */
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

DelayRegister #(.LENGTH(13)) dr2 (
    .iClock(clk),
    .iEnable(fifo1_write),
    .iData(fifo3_sample),
    .oData(fifo4_in));

/* 4096 cycles to find the best model */
mf_fifo fifo4 (
    .clock(clk),
    .data(fifo4_in),
    .rdreq((fifo4_usedw == 4095)),
    .wrreq(fifo3_usedw == 127),
    .empty(fifo4_empty),
    .full(fifo4_full),
    .usedw(fifo4_usedw),
    .q(fifo4_sample));


/* 12 cycles to load the best coefficients into f12 */
TappedDelayRegister #(.LENGTH(12)) dr3 (
    .iClock(clk),
    .iEnable(fifo1_write),
    .iM(best - 2),
    .iData(fifo4_sample),
    .oData(f12_sample));


assign oResidual = f12_residual;
    
always @(posedge clk) begin
    fifo1_write <= 1;
    db_ena <= 1;
    db_rst <= 0;
    acf_ena <= 1;
    acf_rst <= 0;
    ds_unload <= 1;
    fir_fb_valid <= 1;
    f12_ena <= 1;
    f12_rst <= 0;
    f12_calc <= 1;
    fifo1_read <= 1;
end
    
endmodule