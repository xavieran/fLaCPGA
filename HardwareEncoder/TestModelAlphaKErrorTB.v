`timescale 1ns/100ps
`define MY_SIMULATION 1
`default_nettype wire

`include "CalculateKAndError.v"
`include "AlphaCalculator.v"
`include "ModelSelector.v"
/*`include "fp_mult.v"
`include "fp_add_sub.v"
`include "fp_divider.v"
*/
`define DFP(X) $bitstoshortreal(X)

module TestModelAlphaKErrorTB;

reg clk, ena, rst;
integer i;
integer cycles;

reg [31:0] acf [0:12];
reg [31:0] one;

initial begin
    acf[0] = 32'h3f800000;
    acf[1] = 32'h3f7f7b9e;
    acf[2] = 32'h3f7e0419;
    acf[3] = 32'h3f7b9f56;
    acf[4] = 32'h3f784f4c;
    acf[5] = 32'h3f742268;
    acf[6] = 32'h3f6f266c;
    acf[7] = 32'h3f696b12;
    acf[8] = 32'h3f6302b4;
    acf[9] = 32'h3f5bfe5d;
    acf[10] =32'h3f54710d;
    acf[11] =32'h3f4c6d1e;
    acf[12] =32'h3f4401a3;
    one = 32'h3f800000;
end


/* MODEL SELECTION */
reg [31:0] model1, model2;

reg [31:0] model [0:12];
wire [31:0] newmodel1, newmodel2;

reg [31:0] km, alpha, errorm;
reg [3:0] m;

wire [3:0] sel1, sel2, target1, target2;
wire ms_only_one, ms_valid;

reg MS_ena, MS_rst;
wire MS_done;

/* Calculation of K and Error */
reg [31:0] ckae_alpham, ckae_errorm;
wire [31:0] ckae_kmp1, ckae_errormp1;


reg CKAE_ena,CKAE_rst;
wire CKAE_done;

/* Calculation of Alpha */
reg  [31:0] ac_model1, ac_model2, ac_acf1, ac_acf2;
wire [31:0] ac_alpha;
wire ac_valid;
reg AC_ena, AC_rst, ac_validr;
wire AC_done;

assign ac_valid = ms_valid | ac_validr;

ModelSelector ms (
    .iClock(clk),
    .iReset(MS_rst),
    .iEnable(MS_ena),
    
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
    .oDone(MS_done)
    );

AlphaCalculator ac (
    .iClock(clk),
    .iEnable(AC_ena), 
    .iReset(AC_rst),
    
    .iValid(ac_valid),
    .iACF1(ac_acf1),
    .iACF2(ac_acf2),
    .iModel1(ac_model1),
    .iModel2(ac_model2),
    
    .oAlpha(ac_alpha),
    .oDone(AC_done)
    );

CalculateKAndError ckae(
    .iClock(clk),
    .iEnable(CKAE_ena), 
    .iReset(CKAE_rst),
    
    .iAlpham(ckae_alpham),
    .iErrorm(ckae_errorm), // E_m
    
    .oKmp1(ckae_kmp1), // K_m+1
    .oErrormp1(ckae_errormp1),// E_m+1
    .oDone(CKAE_done)
    );

always begin
    #0 clk = 0;
    #10 clk = 1;
    #10 cycles = cycles + 1;
end

initial begin
    cycles = 0;
    AC_ena = 0; AC_rst = 1;
    CKAE_ena = 0; CKAE_rst = 1;
    MS_ena = 0; MS_rst = 1;
    for (i = 0; i <= 12; i = i + 1) begin
        model[i] = 0;
    end
    $display(" Starting !! (m = 0)");
    ckae_alpham = acf[1];
    ckae_errorm = acf[0];
    $display("Calculating K and E with a: %f e: %f", $bitstoshortreal(ckae_alpham), $bitstoshortreal(ckae_errorm));
    #30;
    #20;
    
    /* CALCULATE ERROR AND REFLECTION */
    CKAE_ena = 1; CKAE_rst = 0;
    while (!CKAE_done) begin
        #20;
    end
    
    // Have calculated the error and new k, so set those values
    km = ckae_kmp1;
    errorm = ckae_errormp1;
    m = 1;
    $display("Calculated K_m and Error_m");
    $display("km: %f em: %f ", $bitstoshortreal(km), $bitstoshortreal(errorm));
    
    
    model[0] = 32'h3f800000; // set model to 1.0
    model[1] = km; // set model[1] to km... first iteration
    
    CKAE_ena = 0; CKAE_rst = 0;
    /* CALCULATE ALPHA */
    ac_model1 = model[1];
    ac_model2 = model[0];
    ac_acf1 = acf[1];
    ac_acf2 = acf[2];
    
    $display("Calculating Alpha");
    $display("m1: %f m2: %f r1:%f r2: %f", `DFP(ac_model1), `DFP(ac_model2), `DFP(ac_acf1), `DFP(ac_acf2));
    
    #20 ;
    CKAE_rst = 1;

    AC_ena = 1; AC_rst = 0;
    ac_validr = 1;
    #20 ;
    ac_validr = 0;
    
    while (!AC_done) begin
        #20 ;
    end
    
    AC_ena = 0; AC_rst = 0;
    
    // save the current alpha.
    alpha = ac_alpha;
    $display("Alpha is now: %f", `DFP(alpha));
    
    
    /* CALCULATE CKAE */
    #20;
    $display(" ");
    $display("M == 1");
    ckae_alpham = ac_alpha;
    ckae_errorm = errorm;
    $display("Calculating K and Error");
    $display("Alpha is: %f and error is: %f", `DFP(ckae_alpham), `DFP(ckae_errorm));
    #20;
    AC_rst = 1;
    CKAE_ena = 1; CKAE_rst = 0;
    while (!CKAE_done) begin
        #20;
    end
    // Have calculated the error and new k, so set those values
    km = ckae_kmp1;
    errorm = ckae_errormp1;
    $display("Calculated K_m and Error_m");
    $display("km: %f em: %f ", `DFP(km), `DFP(errorm));
    
    /* Calculate Model */
    
    $display("Calculating model");
    m = 2;
    CKAE_ena = 0; AC_rst = 0;
    model1 = 0; model2 = 0;
    #20;
    MS_ena = 1; MS_rst = 0;
    #20; // Whilst the MS machine does its business...
    model1 = model[sel1];
    model2 = model[sel2];
    AC_ena = 1;
    ac_model1 = km;
    ac_model2 = one;
    ac_acf1 = acf[1];
    ac_acf2 = acf[m + 1];
    ac_validr = 1;
    #20;
    AC_ena = 0;
    ac_validr = 0;
    
    while (!MS_done) begin
        model1 = model[sel1];
        model2 = model[sel2];
        #20;
    end
    
    while (!ms_valid) begin
        AC_ena = ms_valid;
        #20;
    end
    
    AC_ena = 1;
    while (ms_valid) begin
        if (ms_only_one) begin
            model[target1] = newmodel1;
            
            ac_model1 = newmodel1;
            ac_model2 = 0;
            ac_acf1 = acf[target1 + 1];
            ac_acf2 = 0;
        end else begin
            ac_model1 = newmodel1;
            ac_model2 = newmodel2;
            ac_acf1 = acf[target1];
            ac_acf2 = acf[target2 + 1];
            
            model[target1] = newmodel1;
            model[target2] = newmodel2;
        end
        #20;
    end
    
    AC_ena = 1; ac_validr = 0;
    model[2] = km;
    
    for (i = 0; i < 13; i = i + 1) begin
        $display("m%d: %f", i, $bitstoshortreal(model[i]));
    end
    
    #20; 
    $display("Calculating alpha");
    
    while (!AC_done) begin
        #20;
    end
    
    $display("Alpha is: %f", `DFP(ac_alpha));
    alpha = ac_alpha;
    
    $stop;
end

endmodule