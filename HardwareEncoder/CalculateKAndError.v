`default_nettype none

module CalculateKAndError (
    input wire iClock,
    input wire iEnable, 
    input wire iReset,
    
    input wire [31:0] iAlpham,
    input wire [31:0] iKm, // K_m
    input wire [31:0] iErrorm, // E_m
    
    output wire [31:0] oKmp1, // K_m+1
    output wire [31:0] oErrormp1,// E_m+1
    output wire oDone
    );

// Divide Multiply Multiply Add == 14 + 5 + 5 + 7 = 31 cycles latency

integer i;
parameter DIV_LATENCY = 14;
parameter MULT_LATENCY = 5;
parameter ADD_LATENCY = 7;
parameter TOTAL_LATENCY = DIV_LATENCY + MULT_LATENCY + MULT_LATENCY + ADD_LATENCY + 5;
wire [31:0] neg_alpha = iAlpham ^ 32'h80000000; // flip sign bit to obtain negative alpha

reg calculate;
reg done;
reg [7:0] counter;

reg [31:0] alpha, km, errorm;

reg [31:0] o_error;
reg [31:0] o_k;

reg [31:0] kmp1, kmp1_sq, errormp1, mult_term;

wire [31:0] d1_out, m1_out, m2_out, s1_out;

assign oKmp1 = o_k;
assign oErrormp1 = o_error;
assign oDone = done;

fp_divider div (
    .clk_en(calculate),
    .clock(iClock),
    .dataa(alpha),
    .datab(errorm),
    .result(d1_out));

fp_mult m1 (
    .clk_en(calculate),
    .clock(iClock),
    .dataa(kmp1),
    .datab(kmp1),
    .nan(),
    .result(m1_out));

fp_mult m2 (
    .clk_en(calculate),
    .clock(iClock),
    .dataa(errorm),
    .datab(kmp1_sq),
    .nan(),
    .result(m2_out));

// Subtractor...
fp_add_sub s1 (
    .add_sub(1'b0),
    .clk_en(calculate),
    .clock(iClock),
    .dataa(errorm),
    .datab(mult_term),
    .result(s1_out));

always @(posedge iClock) begin
    if (iReset) begin
        done <= 0;
        counter <= 0;
        calculate <= 1'b0;
        
        o_error <= 0;
        o_k <= 0;
        
        alpha <= 0;
        km <= 0;
        errorm <= 0;
        kmp1 <= 0;
        kmp1_sq <= 0;
        mult_term <= 0;
        errormp1 <= 0;
    end else if (iEnable) begin
        if (counter < TOTAL_LATENCY) begin
            counter <= counter + 1'b1;
            calculate <= 1'b1;
        end else begin
            done <= 1'b1;
            calculate <= 1'b0;
            o_error <= errormp1;
            o_k <= kmp1;
        end
        
        alpha <= neg_alpha;
        km <= iKm;
        errorm <= iErrorm;
        
        kmp1 <= d1_out;
        
        kmp1_sq <= m1_out;
        
        mult_term <= m2_out;
        
        errormp1 <= s1_out;
    end
end


endmodule
        
        
