//`include "fp_divider_bb.v"
//`include "fp_convert_bb.v"
`default_nettype none

`define DFP(X) $bitstoshortreal(X)

module Durbinator (
    input wire iClock,
    input wire iEnable, 
    input wire iReset,
    
    input wire [31:0] iACF,
    input wire iValid,
    
    output wire [31:0] alpha,
    output wire [31:0] error,
    output wire [31:0] k,
    
    output wire [3:0] oM,
    output wire [31:0] oModel,
    
    output wire oValid,
    output wire oDone
    );


parameter ORDER = 12;
parameter S_LOAD_ACF = 0;
parameter S_FIRST_K_E = 1;
parameter S_FIRST_ALPHA = 2;
parameter S_CALC_K_E = 3;
parameter S_CALC_MODEL = 4;
parameter S_CALC_ALPHA = 5;
parameter S_DONE = 6;

integer i;

wire [31:0] one = 32'h3f800000;

reg [3:0] durb_state;

reg [31:0] errorm, alpham, km;
reg [3:0] m;
reg done;
reg valid;

assign oValid = valid;
assign oDone = done;
assign error = errorm; assign alpha = alpham; assign k = km;

reg [3:0] acf_count;

/* MODEL SELECTION */
reg [31:0] model1, model2;
reg [31:0] model1_mux, model2_mux;
wire [31:0] newmodel1, newmodel2;

reg rms_valid, dms_valid;

wire [3:0] sel1, sel2, target1, target2;
wire ms_only_one, ms_valid;

reg ms_ena, ms_rst;
wire ms_done;

/* Calculation of K and Error */
reg [31:0] ckae_alpham, ckae_errorm;
wire [31:0] ckae_kmp1, ckae_errormp1;

reg ckae_ena,ckae_rst;
wire ckae_done;

/* Calculation of Alpha */
wire [31:0] ac_alpha, ac_acf1, ac_acf2, ac_model1, ac_model2;
wire ac_valid;
reg ac_first_load;

reg ac_enar, ac_rst, ac_validr;
reg [1:0] wait_for_memory;
wire ac_done, ac_ena;

reg [31:0] model_in1, model_in2;
reg [3:0] model_wr1, model_wr2, model_rd1, model_rd2;
reg model_we1, model_we2;

wire [31:0] model_out1, model_out2;

reg [3:0] final_countdown;

assign ac_valid = dms_valid | ac_validr;
assign ac_ena = dms_valid | ac_enar;
assign oM = m;
assign oModel = model_out1;



register_file model (
    .iClock(iClock),
    
    .iData1(model_in1),
    .iData2(model_in2), 
    
    .iWriteAddress1(model_wr1),
    .iWriteAddress2(model_wr2),
    
    .iReadAddress1(model_rd1), 
    .iReadAddress2(model_rd2),
    
    .iWE1(model_we1),
    .iWE2(model_we2),

    .oData1(model_out1), 
    .oData2(model_out2)
    );

ModelSelector ms (
    .iClock(iClock),
    .iReset(ms_rst),
    .iEnable(ms_ena),
    
    .iM(m),
    .iKm(km),
    .iModel1(model_out1),
    .iModel2(model_out2),
    
    .oSel1(sel1),
    .oSel2(sel2),
    
    .oTarget1(target1), 
    .oTarget2(target2),
    
    .oNewModel1(newmodel1),
    .oNewModel2(newmodel2),
    
    .oOnlyOne(ms_only_one), // Indicate when we only write one coefficient
    .oValid(ms_valid),
    .oDone(ms_done)
    );


AlphaCalculator2 ac (
    .iClock(iClock),
    .iEnable(ac_ena), 
    .iReset(ac_rst),
    
    .iM(m),
    .iValid(ac_valid),
    .iACF1(ac_acf1),
    .iACF2(ac_acf2),
    .iModel1(ac_model1),
    .iModel2(ac_model2),
    
    .oAlpha(ac_alpha),
    .oDone(ac_done)
    );

CalculateKAndError ckae(
    .iClock(iClock),
    .iEnable(ckae_ena),
    .iReset(ckae_rst),
    
    .iAlpham(ckae_alpham),
    .iErrorm(ckae_errorm), // E_m
   
    .oKmp1(ckae_kmp1), // K_m+1
    .oErrormp1(ckae_errormp1),// E_m+1
    .oDone(ckae_done)
    );



reg [31:0] acf_in1, acf_in2;
reg [3:0] acf_wr1, acf_wr2, acf_rd1, acf_rd2;
reg acf_we1, acf_we2;

wire [31:0] acf_out1, acf_out2;

register_file acf (
    .iClock(iClock),
    
    .iData1(acf_in1),
    .iData2(acf_in2), 
    
    .iWriteAddress1(acf_wr1),
    .iWriteAddress2(acf_wr2),
    
    .iReadAddress1(acf_rd1), 
    .iReadAddress2(acf_rd2),
    
    .iWE1(acf_we1),
    .iWE2(acf_we2),

    .oData1(acf_out1), 
    .oData2(acf_out2)
    );

assign ac_acf1 = acf_out1;
assign ac_acf2 = acf_out2;
assign ac_model1 = model_out1;
assign ac_model2 = model_out2;


always @(posedge iClock) begin
    if (iReset) begin
        model_in1 <= 0;
        model_in2 <= 0;
        model_wr1 <= 0;
        model_wr2 <= 0;
        model_we1 <= 0;
        model_we2 <= 0;
        model_rd1 <= 0;
        model_rd2 <= 0;
        
        acf_in1 <= 0;
        acf_in2 <= 0;
        acf_wr1 <= 0;
        acf_wr2 <= 0;
        acf_we1 <= 0;
        acf_we2 <= 0;
        acf_rd1 <= 0;
        acf_rd2 <= 0;
        
        errorm <= 0;
        alpham <= 0;
        km <= 0;
        m <= 0;
        durb_state <= S_LOAD_ACF;
        done <= 0;
        valid <= 0;
        
        ckae_alpham <= 0;
        ckae_errorm <= 0;
        ckae_rst <= 1;
        ckae_ena <= 0;
        
        ac_validr <= 0;
        ac_first_load <= 0;
        ac_rst <= 1;
        ac_enar <= 0;
        
        rms_valid <= 0;
        dms_valid <= 0;
        ms_ena <= 0;
        ms_rst <= 1;
        
        final_countdown <= 0;
        acf_count <= 0;
        wait_for_memory <= 0;
        
    end else if (iEnable) begin            
        /* Delay the valid and model signals for the acf calculator */
        rms_valid <= ms_valid;
        dms_valid <= rms_valid;
    
        case (durb_state) 
        S_LOAD_ACF: 
        begin
            if (acf_count <= 12 && iValid) begin
                acf_we1 <= 1;
                acf_wr1 <= acf_count;
                acf_in1 <= iACF;
                acf_count <= acf_count + 1'b1;
                //$display("ACF: %d -- %f", acf_count, `DFP(iACF));
                acf_rd1 <= 0;
                acf_rd2 <= 1;
            end else if (acf_count > 12) begin
                acf_we1 <= 0;
                /* Initialize the variables */
                model_in1 <= one;
                model_wr1 <= 0;
                model_we1 <= 1;
                
                model_in2 <= 0;
                model_wr2 <= 15;
                model_we2 <= 1;
                
                acf_in2 <= 0;
                acf_wr2 <= 15;
                acf_we2 <= 1;
                
                errorm <= acf_out1;
                alpham <= acf_out2;
                m <= 1;
                
                durb_state <= S_FIRST_K_E;
                
                //$display("First error: %f First Alpha: %f", `DFP(acf_out1), `DFP(acf_out2));
            end
        end
        
        S_FIRST_K_E:
        begin
            /* Calculate the first K and error */
            model_we1 <= 0;
            model_we2 <= 0;
            acf_we2 <= 0;
            ckae_alpham <= alpham;
            ckae_errorm <= errorm;
            ckae_ena <= 1; 
            ckae_rst <= 0;
            
            if (ckae_done) begin
                km <= ckae_kmp1;
                model_wr1 <= 1;
                model_we1 <= 1;
                model_in1 <= ckae_kmp1;
                
                
                errorm <= ckae_errormp1;
                ckae_ena <= 0;
                ckae_rst <= 1;
                durb_state <= S_FIRST_ALPHA;
                
                // Select memory reads for next cycle
                acf_rd1 <= 2;
                acf_rd2 <= 1;
                model_rd1 <= 1;
                model_rd2 <= 0;
                
                //$display("Calculated k and e");
                //$display("k == %f   e == %f", `DFP(ckae_kmp1), `DFP(ckae_errormp1));
            end
        end
        
        S_FIRST_ALPHA:
        begin
            valid <= 0;
            model_we1 <= 0;
            /* Load and start the alpha calculation */
            if (!ac_first_load) begin
                valid <= 1;
                ac_validr <= 1;
                ac_first_load <= 1;
                ac_enar <= 1;
                ac_rst <= 0;
                
                //$display("Calculating alpha");
                //$display("Model1: %f Model2: %f acf1: %f acf2: %f", `DFP(ac_model1), `DFP(ac_model2), `DFP(ac_acf1), `DFP(ac_acf2));
            end else begin
                ac_validr <= 0;
                if (ac_done) begin
                    alpham <= ac_alpha;
                    ac_enar <= 0;
                    ac_rst <= 1;
                    ac_first_load <= 0;
                    
                    durb_state <= S_CALC_K_E;
                    m <= m + 1;
                    //$display("Calculated alpha");
                    //$display("alpha == %f", `DFP(ac_alpha));
                end
            end
        end
        
        S_CALC_K_E:
        begin
            ckae_alpham <= alpham;
            ckae_errorm <= errorm;
            ckae_ena <= 1;
            ckae_rst <= 0;
                        
            if (ckae_done) begin
                km <= ckae_kmp1;
                errorm <= ckae_errormp1;
                ckae_ena <= 0;
                ckae_rst <= 1;
                
                /* Load the first thing into the alpha calc */
                ac_rst <= 0;
                
                model_rd1 <= m;
                model_rd2 <= 0;
                acf_rd1 <= m + 1;
                acf_rd2 <= 1;
                wait_for_memory <= 1;
                
                model_in1 <= ckae_kmp1;
                model_we1 <= 1;
                model_wr1 <= m;
                
                durb_state <= S_CALC_MODEL;
                
                //$display("Calculated k and e");
                //$display("em_n == %f   alpham_n == %f", `DFP(ckae_errorm), `DFP(ckae_alpham));
                //$display("k == %f   e == %f", `DFP(ckae_kmp1), `DFP(ckae_errormp1));
            end
        end
        
        S_CALC_MODEL:
        begin
            model_we1 <= 0;
            model_we2 <= 0;
            ac_validr <= 0;
            ms_ena <= 1;
            ms_rst <= 0;
            ac_enar <= rms_valid;
            
            model_rd1 <= sel1;
            model_rd2 <= sel2;
            
            if (wait_for_memory == 1) begin    
                //$display("\n *********** !!!!!!!! M == %d", m);
                // waiting a cycle
                ac_validr <= 1;
                ac_enar <= 1;
                wait_for_memory <= 0;
            end
            
            if (ms_valid) begin
                if (ms_only_one) begin
                    model_in1 <= newmodel1;
                    model_we1 <= 1;
                    model_wr1 <= target1;
                    
                    model_rd1 <= target1;
                    model_rd2 <= 15; // these will read a zero
                    acf_rd1 <= 15;
                    acf_rd2 <= target1 + 1; // these will read a zero
                    
                end else begin
                    model_we1 <= 1;
                    model_we2 <= 1;
                    model_in1 <= newmodel1;
                    model_in2 <= newmodel2;
                    model_wr1 <= target1;
                    model_wr2 <= target2;
                    
                    model_rd1 <= target1;
                    model_rd2 <= target2;
                    
                    acf_rd1 <= target1 + 1;
                    acf_rd2 <= target2 + 1;
                end
                
                //$display("NEW MODEL COEFF: Target1: %d Model1: %f Target2: %d Model2: %f", target1, `DFP(newmodel1), target2, `DFP(newmodel2));
            end else if (dms_valid) begin
                // We caught the falling edge of ms_valid
                ac_enar <= 1;
                ms_ena <= 0;
                ms_rst <= 1;
                
                model_rd1 <= m;
                durb_state <= S_CALC_ALPHA;
            end
        end
        
        S_CALC_ALPHA: 
        begin
            if (model_rd1 > 0) begin
                valid <= 1;
                model_rd1 <= model_rd1 - 1'b1;
            end else begin
                valid <= 0;
            end
            
            if (m == ORDER) begin
                
                if (model_rd1 == 0)
                    durb_state <= S_DONE;
            end else if (ac_done) begin
                alpham <= ac_alpha;
                dms_valid <= 0;
                ac_enar <= 0;
                ac_rst <= 1;
                m <= m + 1;
                durb_state <= S_CALC_K_E;
                
                ckae_alpham <= ac_alpha;
                ckae_errorm <= errorm;
                ckae_ena <= 1;
                ckae_rst <= 0;
                
                //$display("Calculated alpha");
                //$display("alpha == %f", `DFP(ac_alpha));
            end
        end
        
        S_DONE:
        begin
            done <= 1;
        end
        endcase
    end
end

endmodule
