
module ReflectionError (
    input wire iClock,
    input wire iEnable, 
    input wire iReset,
    
    input wire signed [31:0] iAlpha;
    input wire signed [31:0] iError;
    
    output wire signed [31:0] oReflection;
    output wire signed [31:0] oError;
    
    output reg oDone
    );

endmodule

/* k = alpha/error
 * error = error - error*k*k;
 */
 
fp_divider div (
    .clk_en(div_en),
    .clock(iClock),
    .dataa(numerator),
    .datab(denominator),
    .result(result));
