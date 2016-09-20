/* Stage 3 - Encodes the data
 * 1. Use FIR_FilterBank to find the best iModel
 * 2. Use the best model to calculate the residuals
 * 3. Encode these residuals using the RiceWriter
 */

`default_nettype none


module Stage3_Encode (
    input wire iClock,
    input wire iEnable,
    input wire iReset,
    
    input wire iValid,
    input wire [15:0] iSample,
    
    input wire iLoad,
    input wire [11:0] iModel,
    input wire [3:0] iM, 
    
    output wire oRamEnable1,
    output wire [15:0] oRamAddress1, 
    output wire [15:0] oRamData1,
    
    output wire oRamEnable2,
    output wire [15:0] oRamAddress2, 
    output wire [15:0] oRamData2
    );

reg fir_fb_rst;
reg [3:0] current_best_fir;
wire [3:0] best_fir;
wire fir_fb_done;

FIR_FilterBank fir_fb (
    .iClock(iClock), 
    .iEnable(iEnable), 
    .iReset(fir_fb_rst),
    
    .iLoad(iLoad),
    .iM(iM),
    .iCoeff(iModel),
    
    .iValid(iValid), 
    .iSample(iSample),
    
    .oBestPredictor(best_fir),
    .oDone(fir_fb_done)
    );

wire signed [15:0] fifo1_sample;
wire fifo1_empty, fifo1_full;
wire [11:0] fifo1_usedw;

/* 4096 cycles through the ACF calculator */
mf_fifo fifo1 (
    .clock(iClock),
    .data(iSample),
    .rdreq((fifo1_usedw == 4095)),
    .wrreq(iValid),
    .empty(fifo1_empty),
    .full(fifo1_full),
    .usedw(fifo1_usedw),
    .q(fifo1_sample));

reg ds_unload;
wire [11:0] ds_coeff;
wire ds_valid;
wire ds_done;
reg ds_rst;

DurbinCoefficientStore durb_store (
    .iClock(iClock), 
    .iEnable(iEnable),
    .iReset(ds_rst), 
    .iLoad(iLoad),
    .iM(iM),
    .iCoeff(iModel),
    
    .iUnload(ds_unload), 
    .iBestM(current_best_fir),
    
    .oCoeff(ds_coeff),
    .oValid(ds_valid), 
    .oDone(ds_done));

reg f12_ena, f12_rst, f12_calc;
wire signed [15:0] f12_sample;
wire signed [15:0] f12_residual;
wire f12_valid, f12_done;

FIRX f12 (
    .iEnable(iEnable),
    .iClock(iClock),
    .iReset(iReset),
    .iLoad(ds_valid),
    .iQLP(ds_coeff),
    .iM(current_best_fir),
    
    .iValid(f12_calc),
    .iSample(f12_sample),
    .oResidual(f12_residual), 
    .oValid(f12_valid),
    .oDone(f12_done)
    );

/* 12 cycles to load the best coefficients into f12 */
TappedDelayRegister #(.LENGTH(12)) dr3 (
    .iClock(iClock),
    .iEnable(iEnable),
    .iM(current_best_fir - 2),
    .iData(fifo1_sample),
    .oData(f12_sample));

/*
RiceOptimizer ro (
    .iClock,
    .iEnable, 
    .iReset(f12_rst),
    
    .iResidual(f12_residual),
    
    .oBest(5)
    );*/

wire [15:0] re_msb, re_lsb, re_bu;
wire re_valid;

RiceEncoder re (
    .iClock(iClock),
    .iReset(f12_rst),
    
    .iValid(f12_valid),
    .iSample(f12_residual), 
    .oMSB(re_msb),
    .oLSB(re_lsb), 
    .oBitsUsed(re_bu),
    .oValid(re_valid)
    );

wire [15:0] rw_ra1, rw_rd1, rw_ra2, rw_rd2;
wire rw_re1, rw_re2;

RiceWriter rw (
      .iClock(iClock),
      .iReset(f12_rst), 
      .iEnable(re_valid), 
      
      .iChangeParam(0),
      .iFlush(0),
      .iTotal(re_bu),
      .iUpper(re_msb),
      .iLower(re_lsb), 
      .iRiceParam(5),
      
      .oRamEnable1(rw_re1),
      .oRamAddress1(rw_ra1), 
      .oRamData1(rw_rd1),
      
      .oRamEnable2(rw_re2),
      .oRamAddress2(rw_ra2), 
      .oRamData2(rw_rd2)
      );

assign oRamEnable1 = rw_re1;
assign oRamEnable2 = rw_re2;
assign oRamAddress1 = rw_ra1;
assign oRamAddress2 = rw_ra2;
assign oRamData1 = rw_rd1;
assign oRamData2 = rw_rd2;


reg [3:0] unload_counter;

always @(posedge iClock) begin
    if (iReset) begin
        f12_ena <= 0;
        f12_rst <= 1;
        fir_fb_rst <= 1;
        ds_rst <= 1;
        f12_calc <= 0;
        current_best_fir <= 0;
        unload_counter <= 0;
        ds_unload <= 0;
    end else if (iEnable) begin
        ds_rst <= 0;
        fir_fb_rst <= 0;
        f12_rst <= 0;
        
        if (fir_fb_done) begin
            fir_fb_rst <= 1;
            current_best_fir <= best_fir;
            unload_counter <= best_fir;
        end
        
        if (unload_counter > 0) begin
            ds_unload <= 1;
            unload_counter <= unload_counter - 1;
        end
        
        if (ds_done) begin
            ds_rst <= 1;
            ds_unload <= 0;
            unload_counter <= 0;
            f12_calc <= 1;
        end
        
        if (f12_done) begin
            f12_rst <= 1;
        end
    end
end
endmodule