`timescale 1ns/100ps
`define MY_SIMULATION 1

module ModelSelectorTB;

reg clk, ena, rst;
integer i;
integer cycles;
reg signed [31:0] km;
reg signed [31:0] model1, model2;

reg signed [31:0] model [0:12];
wire signed [31:0] newmodel1, newmodel2;

reg [3:0] m;
wire [3:0] sel1, sel2, target1, target2;
wire only_one, valid, done;

ModelSelector ms (
    .iClock(clk),
    .iReset(rst),
    .iEnable(ena),
    
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
    
    .oOnlyOne(only_one), // Indicate when we only write one coefficient
    .oValid(valid),
    .oDone(done)
    );

always begin
    #0 clk = 0;
    #10 clk = 1;
    #10 cycles = cycles + 1;
end

initial begin
    cycles = 0;
    ena = 0; rst = 1;
    for (i = 0; i <= 12; i = i + 1) begin
        model[i] = 0;
    end
    #30;    
    /* First iteration of levinson durbin is just km */
    model[0] = 32'h3f800000; // 1.0
    model[1] = 32'hbf7f7cee; // -.998
    // Calculate alpha, error, etc.
    km = 32'h3f6be0df; // .9214
    m = 2;
    model1 = 0;
    model2 = 0;
    #20 
    
    ena = 1; rst = 0;
    
    #20
    while (!done) begin
        model1 = model[sel1]; // 1.0
        model2 = model[sel2]; // .75
        $display("k: %f m1: %f m2: %f", $bitstoshortreal(km), $bitstoshortreal(model1), $bitstoshortreal(model2));
        #20 ;
    end 
    
    while (!valid) begin
        #20 ;
    end
    
    while (valid) begin
        if (only_one) begin
            model[target1] = newmodel1;
        end else begin
            model[target1] = newmodel1;
            model[target2] = newmodel2;
        end
        #20 ;
    end
        
    model[m] = km;
    
    for (i = 0; i < 13; i = i + 1) begin
        $display("m%d: %f", i, $bitstoshortreal(model[i]));
    end
    
    /******************** M = 3 ********************/
    
    ena = 0; rst = 1;
    km = 32'h3eb95810;
    m = 3;
    
    #20 
    ena = 1; rst = 0;
    
    #20
    while (!done) begin
        model1 = model[sel1]; // 1.0
        model2 = model[sel2]; // .75
        $display("k: %f m1: %f m2: %f", $bitstoshortreal(km), $bitstoshortreal(model1), $bitstoshortreal(model2));
        #20 ;
    end 
    
    while (!valid) begin
        #20 ;
    end
    
    while (valid) begin
        if (only_one) begin
            model[target1] = newmodel1;
        end else begin
            model[target1] = newmodel1;
            model[target2] = newmodel2;
        end
        #20 ;
    end
        
    model[m] = km;
    
    for (i = 0; i < 13; i = i + 1) begin
        $display("m%d: %f", i, $bitstoshortreal(model[i]));
    end
    
    
        /******************** M = 4 ********************/
    
    ena = 0; rst = 1;
    km <= 32'h3ea20c4a;
    m = 11;
    #20;
    #20 
    ena = 1; rst = 0;
    
    #20
    while (!done) begin
        model1 = model[sel1]; // 1.0
        model2 = model[sel2]; // .75
        $display("k: %f m1: %f m2: %f", $bitstoshortreal(km), $bitstoshortreal(model1), $bitstoshortreal(model2));
        #20 ;
    end 
    
    while (!valid) begin
        #20 ;
    end
    
    while (valid) begin
        if (only_one) begin
            model[target1] = newmodel1;
        end else begin
            model[target1] = newmodel1;
            model[target2] = newmodel2;
        end
        #20 ;
    end
        
    model[m] = km;
    
    for (i = 0; i < 13; i = i + 1) begin
        $display("m%d: %f", i, $bitstoshortreal(model[i]));
    end
    
    
    $stop;
end

endmodule