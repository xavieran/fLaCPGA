//`include "fp_divider_bb.v"
//`include "fp_convert_bb.v"
`default_nettype none

module Durbinator (
    input wire iClock,
    input wire iEnable, 
    input wire iReset,
    
    input wire signed [31:0] ACC,
    
    output reg oDone
    );

parameter ORDER = 12;
parameter DIVIDER_DELAY = 14;
parameter CONVERTER_DELAY = 7;

reg signed [31:0] alpha, error, reflection;

reg signed [31:0] autoc[ORDER];
reg signed [31:0] model[ORDER];


endmodule