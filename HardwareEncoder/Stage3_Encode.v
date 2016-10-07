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
    input wire signed [14:0] iModel,
    input wire [3:0] iM,
    
    output wire signed [15:0] oResidual,
    output wire oValid,
    output wire oFrameDone
    );

reg fir_fb_rst;
reg fir_fb_valid;
reg [3:0] current_best_fir;
wire [3:0] best_fir1;
wire fir_fb_done;

reg first_time;reg f12_first_time;

reg f12_select;
reg phase_select;
reg ds_override;

FIR_FilterBank fir_fb1 (
    .iClock(iClock), 
    .iEnable(iEnable), 
    .iReset(fir_fb_rst & phase_select | (fir_fb_rst & !phase_select & f12_first_time) | ds_override),
    
    .iLoad(iLoad & !phase_select),
    .iM(iM),
    .iCoeff(iModel),
    
    .iValid(iValid & phase_select & fir_fb_valid), 
    .iSample(iSample),
    
    .oBestPredictor(best_fir1),
    .oDone(fir_fb_done)
    );

reg fir_fb_rst2;
wire [3:0] best_fir2;
wire fir_fb_done2;
FIR_FilterBank fir_fb2 (
    .iClock(iClock), 
    .iEnable(iEnable), 
    .iReset(fir_fb_rst & !phase_select & !f12_first_time | ds_override),
    
    .iLoad(iLoad & phase_select),
    .iM(iM),
    .iCoeff(iModel),
    
    .iValid(iValid & !phase_select & fir_fb_valid), 
    .iSample(iSample),
    
    .oBestPredictor(best_fir2),
    .oDone(fir_fb_done2)
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
wire [14:0] ds1_coeff;
wire ds1_valid;
wire ds1_done;
reg ds1_rst;
DurbinCoefficientStore durb_store1 (
    .iClock(iClock), 
    .iEnable(iEnable),
    .iReset(ds1_rst & (!phase_select) | ds_override), 
    .iLoad(iLoad & (!phase_select)),
    .iM(iM),
    .iCoeff(iModel),
    
    .iUnload(ds_unload && (!phase_select)), // if phase_select == 0 write to this one 
    .iBestM(current_best_fir),
    
    .oCoeff(ds1_coeff),
    .oValid(ds1_valid), 
    .oDone(ds1_done));

wire [14:0] ds2_coeff;
wire ds2_valid;
wire ds2_done;
reg ds2_rst;
DurbinCoefficientStore durb_store2 (
    .iClock(iClock), 
    .iEnable(iEnable),
    .iReset(ds2_rst & (phase_select) | ds_override), 
    .iLoad(iLoad & (phase_select)),
    .iM(iM),
    .iCoeff(iModel),
    
    .iUnload(ds_unload && (phase_select)),  // if phase_select == 1 write to this one
    .iBestM(current_best_fir),
    
    .oCoeff(ds2_coeff),
    .oValid(ds2_valid), 
    .oDone(ds2_done));

reg f12_ena, f12_rst, f12_calc;
wire signed [15:0] f12_sample;
wire signed [15:0] f12_residual1, f12_residual2;
wire f12_valid1, f12_done1, f12_idone1;
wire f12_valid2, f12_done2, f12_idone2;

FIRX f12_1 (
    .iEnable(f12_ena),
    .iClock(iClock),
    .iReset(f12_rst & f12_select | ds_override),
    .iLoad((phase_select ? ds2_valid : ds1_valid) & f12_select),
    .iQLP(phase_select ? ds2_coeff : ds1_coeff),
    .iM(current_best_fir),
    
    .iValid(f12_calc & !f12_select),
    .iSample(f12_sample),
    .oResidual(f12_residual1), 
    .oValid(f12_valid1),
    .oInputDone(f12_idone1),
    .oDone(f12_done1)
    );

FIRX f12_2 (
    .iEnable(f12_ena),
    .iClock(iClock),
    .iReset(f12_rst & !f12_select | ds_override),
    .iLoad((phase_select ? ds2_valid : ds1_valid) & !f12_select),
    .iQLP(phase_select ? ds2_coeff : ds1_coeff),
    .iM(current_best_fir),
    
    .iValid(f12_calc & f12_select),
    .iSample(f12_sample),
    .oResidual(f12_residual2), 
    .oValid(f12_valid2),
    .oInputDone(f12_idone2),
    .oDone(f12_done2)
    );

wire signed [15:0] dr1_sample;
DelayRegister #(.LENGTH(4)) dr1 (
    .iClock(iClock),
    .iEnable(iEnable),
    .iData(fifo1_sample),
    .oData(dr1_sample)
    );

/* 12 cycles to load the best coefficients into f12 */
/*TappedDelayRegister #(.LENGTH(12)) dr3 (
    .iClock(iClock),
    .iEnable(iEnable),
    .iM(current_best_fir - 4),
    .iData(fifo1_sample),
    .oData(f12_sample));
*/

assign f12_sample = fifo1_sample;

wire [3:0] best_fir;
reg [3:0] unload_counter;
reg rLoad;
reg dLoad;
reg frame_done;
assign oResidual = ((f12_valid1 ? 16'hffff : 16'h0000) & f12_residual1) | 
                   ((f12_valid2 ? 16'hffff : 16'h0000) & f12_residual2);
assign oValid = f12_valid1 | f12_valid2;
assign best_fir = phase_select ?  best_fir1 : best_fir2;
assign oFrameDone = frame_done;


always @(posedge iClock) begin
    if (iReset) begin
        f12_ena <= 0;
        f12_rst <= 1;
        f12_calc <= 0;
        fir_fb_rst <= 1;
        fir_fb_rst2 <= 1;
        current_best_fir <= 0;
        ds_override <= 1;
        ds1_rst <= 1;
        ds2_rst <= 1;
        ds_unload <= 0;
        first_time <= 1;
        f12_first_time <= 1;
        phase_select <= 0;
        f12_select <= 1;
        fir_fb_valid <= 1;
        rLoad <= 0;
        dLoad <= 0;
        frame_done <= 0;
    end else if (iEnable) begin
        ds_override <= 0;
        rLoad <= iLoad;
        dLoad <= rLoad;
        
        // Detect falling edge of model done...
        if (iM == 12 && rLoad == 0 && dLoad == 1 && first_time == 1) begin
            phase_select <= !phase_select;
            fir_fb_valid <= 1;
            first_time <= 0;
        end
        
        ds1_rst <= 0;
        ds2_rst <= 0;
        fir_fb_rst <= 0;
        fir_fb_rst2 <= 0;
        f12_rst <= 0;
        frame_done <= 0;
        
        if (fir_fb_done | fir_fb_done2) begin
            fir_fb_rst <= 1;
            fir_fb_valid <= 0;
            
            current_best_fir <= best_fir;
            f12_ena <= 1;
            ds_unload <= 1;
            
            if (f12_first_time) begin
                phase_select <= !phase_select;
                fir_fb_valid <= 1;
            end
        end
        
        if (fifo1_usedw == 4095) begin
            f12_calc <= 1;
        end
        
        if (f12_idone1 | f12_idone2) begin
            f12_select <= !f12_select;
            phase_select <= !phase_select;
            fir_fb_valid <= 1;
        end   
        
        if (f12_done1 | f12_done2) begin
            f12_rst <= 1;
            frame_done <= 1;
        end
        
        if (ds1_done | ds2_done) begin
            ds1_rst <= 1;
            ds2_rst <= 1;
            ds_unload <= 0;
            if (f12_first_time) begin
                f12_rst <= 1;
                f12_first_time <= 0;
                f12_select <= !f12_select;
            end
        end
    end
end
endmodule