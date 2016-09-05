
`ifndef MODEL_SEL_H
`define MODEL_SEL_H

`default_nettype none

module ModelSelector(
    input wire iClock,
    input wire iReset,
    input wire iEnable,
    
    input wire [3:0] iM,
    input wire [31:0] iKm,
    input wire [31:0] iModel1,
    input wire [31:0] iModel2,
    
    output wire [3:0] oSel1,
    output wire [3:0] oSel2,
    
    output wire [3:0] oTarget1, 
    output wire [3:0] oTarget2,
    
    output reg [31:0] oNewModel1,
    output reg [31:0] oNewModel2,
    
    output wire oOnlyOne, // Indicate when we only write one coefficient
    output wire oValid,
    output reg oDone
    );

integer i;
parameter ORDER = 12;
parameter MULT_LATENCY = 5;
parameter ADD_LATENCY = 7;
parameter TOTAL_LATENCY = MULT_LATENCY + ADD_LATENCY + 2 + 1;

reg [3:0] n;

reg [3:0] dTarget1 [0:TOTAL_LATENCY];
reg [3:0] dTarget2 [0:TOTAL_LATENCY];
reg  [TOTAL_LATENCY:0] only_one;
reg [TOTAL_LATENCY:0] valid;

reg [31:0] dModel1 [0:MULT_LATENCY];
reg [31:0] dModel2 [0:MULT_LATENCY];
reg [31:0] rModel1, rModel2;

wire [31:0] mult1, mult2, NewModel1, NewModel2;

reg [3:0] a, b; // Hold the targets
reg [3:0] m;
reg [31:0] km;

reg mult_en, add_en;
reg start;

assign oTarget1 = dTarget1[TOTAL_LATENCY];
assign oTarget2 = dTarget2[TOTAL_LATENCY];
assign oOnlyOne = only_one[TOTAL_LATENCY];
assign oValid = valid[TOTAL_LATENCY];

assign oSel1 = a;
assign oSel2 = b;

fp_mult m1 (
    .clk_en(mult_en),
    .clock(iClock),
    .dataa(km),
    .datab(rModel1),
    .nan(),
    .result(mult1));


fp_mult m2 (
    .clk_en(mult_en),
    .clock(iClock),
    .dataa(km),
    .datab(rModel2),
    .nan(),
    .result(mult2));

fp_add_sub a1 (
    .add_sub(1'b1),
    .clk_en(add_en),
    .clock(iClock),
    .dataa(mult2),
    .datab(dModel1[MULT_LATENCY]),
    .result(NewModel1));

fp_add_sub a2 (
    .add_sub(1'b1),
    .clk_en(add_en),
    .clock(iClock),
    .dataa(mult1),
    .datab(dModel2[MULT_LATENCY]),
    .result(NewModel2));


always @(posedge iClock) begin
    if (iReset) begin
        m <= iM;
        km <= iKm;
        n <= 1;
        valid <= 0;
        mult_en <= 0;
        add_en <= 0;
        only_one <= 0;
        a <= 15;
        b <= 0;
        oDone <= 1'b1;
        start <= 0;
    end else if (iEnable) begin
        rModel1 <= iModel1;
        rModel2 <= iModel2;
        
        oNewModel1 <= NewModel1;
        oNewModel2 <= NewModel2;
        oDone <= 1'b0;
        mult_en <= 1'b1;
        add_en <= 1'b1;
        
        if (n == ((m >> 1) + 1)) begin
            oDone <= 1'b1;
        end else begin
            n <= n + 1'b1;
        end
        
        start <= 1;
        a <= n;
        b <= m - n;
        
        /* Do the various delayings */
        for (i = 1; i <= MULT_LATENCY; i = i + 1) begin
            dModel1[i] <= dModel1[i - 1];
            dModel2[i] <= dModel2[i - 1];
        end
        dModel1[0] <= iModel1;
        dModel2[0] <= iModel2;
        
        for (i = 1; i <= TOTAL_LATENCY; i = i + 1) begin
            dTarget1[i] <= dTarget1[i - 1];
            dTarget2[i] <= dTarget2[i - 1];
        end
        dTarget1[0] <= a;
        dTarget2[0] <= b;
        
        only_one <= (only_one << 1) | (a == b);
        valid <= (valid << 1) | !oDone;
        
    end
end
    
endmodule

`endif