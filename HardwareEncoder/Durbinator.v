//`include "fp_divider_bb.v"
//`include "fp_convert_bb.v"
//`default_nettype none

`define DFP(X) $bitstoshortreal(X)


module Durbinator (
    input wire iClock,
    input wire iEnable, 
    input wire iReset,
    
    input wire [31:0] iACF,
    
    output wire [31:0] alpha,
    output wire [31:0] error,
    output wire [31:0] k,
    output wire oDone
    );


parameter ORDER = 12;
parameter S_LOAD_ACF = 0;
parameter S_FIRST_K_E = 1;
parameter S_FIRST_ALPHA = 2;
parameter S_CALC_K_E = 3;
parameter S_CALC_MODEL = 4;
parameter S_CALC_ALPHA = 5;
parameter S_CALC_ALPHA = 6;

integer i;

wire [31:0] one = 32'h3f800000;

reg [3:0] durb_state;

reg [31:0] errorm, alpham, km;
reg [3:0] m;
reg done;

assign oDone = done;
assign error = errorm; assign alpha = alpham; assign k = km;

reg [31:0] acf [0:ORDER];
reg [3:0] acf_count;

/* MODEL SELECTION */
reg [31:0] model1, model2;
reg [31:0] model1_mux, model2_mux;
reg [31:0] model [0:12];
wire [31:0] newmodel1, newmodel2;

reg [3:0] dTarget1, dTarget2;
reg [3:0] rTarget1, rTarget2;

wire [3:0] sel1, sel2, target1, target2;
wire ms_only_one, ms_valid;

reg ms_pvalid;

reg ms_ena, ms_rst;
wire ms_done;

/* Calculation of K and Error */
reg [31:0] ckae_alpham, ckae_errorm;
wire [31:0] ckae_kmp1, ckae_errormp1;

reg ckae_ena,ckae_rst;
wire ckae_done;

/* Calculation of Alpha */
reg  [31:0] ac_model1, ac_model2, ac_acf1, ac_acf2;
wire [31:0] ac_alpha;
wire ac_valid;
reg ac_first_load;
reg [31:0] ac_acf2_start; 


reg ac_ena, ac_rst, ac_validr;
wire ac_done;

assign ac_valid = ms_pvalid | ac_validr;

ModelSelector ms (
    .iClock(iClock),
    .iReset(ms_rst),
    .iEnable(ms_ena),
    
    .iM(m),
    .iKm(km),
    .iModel1(model1),
    .iModel2(model2),
    
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

AlphaCalculator ac (
    .iClock(iClock),
    .iEnable(ac_ena), 
    .iReset(ac_rst),
    
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


always @(posedge iClock) begin
    if (iReset) begin
        for (i = 0; i < ORDER; i = i + 1) begin
            acf[i] <= 0;
            model[i] <= 0;
        end
        
        errorm <= 0;
        alpham <= 0;
        km <= 0;
        m <= 0;
        durb_state <= S_LOAD_ACF;
        
        ckae_alpham <= 0;
        ckae_errorm <= 0;
        ckae_rst <= 1;
        ckae_ena <= 0;
        
        ac_model1 <= 0;
        ac_model2 <= 0;
        ac_acf1 <= 0;
        ac_acf2 <= 0;
        ac_validr <= 0;
        ac_first_load <= 0;
        ac_rst <= 1;
        ac_ena <= 0;
        
        model1 <= 0;
        model2 <= 0;
        ms_pvalid <= 0;
        rTarget1 <= 0;
        rTarget2 <= 0;
        dTarget1 <= 0;
        dTarget1 <= 0;
        ms_ena <= 0;
        ms_rst <= 1;
        
        acf_count <= 0;
        
    end else if (iEnable) begin
        case (durb_state) 
        S_LOAD_ACF: 
        begin
            if (acf_count <= 12) begin
                acf_count <= acf_count + 1'b1;
                /* Shift in the autocorrelations */
                for (i = ORDER; i > 0; i = i - 1) begin
                    acf[i] <= acf[i - 1];
                end
                acf[0] <= iACF;
            end else begin
                /* Initialize the variables */
                model[0] <= one;
                errorm <= acf[0];
                alpham <= acf[1];
                m <= 2;
                
                durb_state <= S_FIRST_K_E;
            end
        end
        
        S_FIRST_K_E:
        begin
            /* Calculate the first K and error */
            ckae_alpham <= alpham;
            ckae_errorm <= errorm;
            ckae_ena <= 1; 
            ckae_rst <= 0;
            
            if (ckae_done) begin
                km <= ckae_kmp1;
                model[1] <= ckae_kmp1;
                errorm <= ckae_errormp1;
                ckae_ena <= 0;
                ckae_rst <= 1;
                
                durb_state <= S_FIRST_ALPHA;
                
                $display("Calculated k and e");
                $display("k == %f   e == %f", `DFP(ckae_kmp1), `DFP(ckae_errormp1));
            end
        end
        
        S_FIRST_ALPHA:
        begin
            /* Load and start the alpha calculation */
            if (!ac_first_load) begin
                ac_model1 <= model[1];
                ac_model2 <= model[0];
                ac_acf1 <= acf[1];
                ac_acf2 <= acf[2];
                
                ac_validr <= 1;
                ac_first_load <= 1;
                ac_ena <= 1;
                ac_rst <= 0;
            end else begin
                ac_validr <= 0;
                if (ac_done) begin
                    alpham <= ac_alpha;
                    ac_ena <= 0;
                    ac_rst <= 1;
                    ac_first_load <= 0;
                    
                    durb_state <= S_CALC_K_E;
                    
                    $display("Calculated alpha");
                    $display("alpha == %f", `DFP(ac_alpha));
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
                ac_ena <= 1;
                ac_rst <= 0;
                ac_model1 <= ckae_kmp1;
                ac_model2 <= one;
                ac_acf1 <= acf[1];
                ac_acf2 <= ac_acf2_start;
                ac_validr <= 1;
                
                model[m] <= ckae_kmp1;
                
                durb_state <= S_CALC_MODEL;
                
                $display("Calculated k and e");
                $display("em_n == %f   alpham_n == %f", `DFP(ckae_errorm), `DFP(ckae_alpham));
                $display("k == %f   e == %f", `DFP(ckae_kmp1), `DFP(ckae_errormp1));
            end
        end
        
        S_CALC_MODEL:
        begin
            ac_ena <= ms_valid;
            ac_validr <= 0;
            ms_ena <= 1;
            ms_rst <= 0;
            ms_pvalid <= ms_valid;
            
            rTarget1 <= target1;
            rTarget2 <= target2;
            dTarget1 <= rTarget1;
            dTarget2 <= rTarget2;
            
            if (!ms_done) begin
                model1 <= model1_mux;
                model2 <= model2_mux;
            end
            
            if (ms_valid) begin
                if (ms_only_one) begin
                    model[target1] <= newmodel1;
                    ac_model1 <= newmodel1;
                    ac_model2 <= 0;
                    ac_acf1 <= acf[target1 + 1];
                    ac_acf2 <= 0;
                end else begin
                    model[target1] <= newmodel1;
                    model[target2] <= newmodel2;
                    
                    ac_model1 <= newmodel1;
                    ac_model2 <= newmodel2;
                    ac_acf1 <= acf[target1];
                    ac_acf2 <= acf[target2 + 1];
                end
            end else if (ms_pvalid) begin
                // We caught the falling edge of ms_valid
                ac_ena <= 1;
                ms_ena <= 0;
                ms_rst <= 1;
                
                durb_state = S_CALC_ALPHA;
                
                $display("Calculated model");
                for (i = 0; i <= m; i = i + 1) begin
                    $display("m%d == %f", i, `DFP(model[i]));
                end
            end
        end
        
        S_CALC_ALPHA: 
        begin
            if (m == ORDER) begin
                durb_state <= S_DONE;
            end else if (ac_done) begin
                alpham <= ac_alpha;
                ac_ena <= 0;
                ac_rst <= 1;
                m <= m + 1;
                
                durb_state <= S_CALC_K_E;
                
                $display("Calculated alpha");
                $display("alpha == %f", `DFP(ac_alpha));
            end
        end
        
        S_DONE:
        begin
            done <= 1;
        end
        endcase
    end
end

always @(m or acf) begin
    if (m < ORDER) begin
        ac_acf2_start <= acf[m + 1];
    end else begin
        ac_acf2_start <= 0;
    end
end

always @(model or sel1) begin
    if (sel1 <= ORDER) begin
        model1_mux <= model[sel1];
    end else begin
        model1_mux <= 0;
    end
end 

always @(model or sel2) begin
    if (sel2 <= ORDER) begin
        model2_mux <= model[sel2];
    end else begin
        model2_mux <= 0;
    end
end 

endmodule
