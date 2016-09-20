//`default_nettype none
//`include "GenerateAutocorrelationSums.v"

module ACFDivider (
    input wire iClock,
    input wire iEnable,
    input wire iReset, 
    
    input wire [42:0] iACF,
    input wire iValid,
    
    output wire [31:0] ofACF,
    output wire oValid
    );

parameter ORDER = 12;
parameter DIVIDER_DELAY = 14;
parameter CONVERTER_DELAY = 7;

wire [31:0] one = 32'h3f800000;
reg first;

reg [63:0] integer_data;

reg [31:0] numerator, denominator;
wire [31:0] floating_data;
wire [31:0] result;
reg div_en, conv_en, div_valid, first_valid;
reg [31:0] dividend;

reg [3:0] div_count;

reg [CONVERTER_DELAY:0] conv_delay;
reg [DIVIDER_DELAY:0] div_delay;
wire converter_valid = conv_delay[CONVERTER_DELAY - 1];
wire divider_valid = div_delay[DIVIDER_DELAY];

assign oValid = divider_valid | first_valid;
assign ofACF = dividend;

fp_convert conv (
    .clk_en(conv_en),
    .clock(iClock),
    .dataa(integer_data),
    .result(floating_data));

fp_divider div (
    .clk_en(div_en),
    .clock(iClock),
    .dataa(numerator),
    .datab(denominator),
    .result(result));

always @(posedge iClock) begin
    if (iReset) begin
        conv_delay <= 0;
        numerator <= 0;
        denominator <= 1;
        integer_data <= 0;
        
        first_valid <= 0;
        dividend <= 0;
        div_delay <= 0;
        conv_delay <= 0;
        div_valid <= 0;
        div_count <= 0;
        div_en <= 0;
        conv_en <= 0;
        first <= 1;
    end else if (iEnable) begin
        conv_delay <= conv_delay << 1 | iValid;
        div_delay <= div_delay << 1 | div_valid;
        
        dividend <= result;
        first_valid <= 0;
        
        if (iValid) begin
            conv_en <= 1;
            integer_data <= iACF;
        end
        
        if (converter_valid) begin
            if (first) begin
                denominator <= floating_data;
                dividend <= 32'h3f800000;
                first_valid <= 1;
                first <= 0;
            end else begin
                numerator <= floating_data;
                div_en <= 1;
                div_valid <= 1;
            end
        end
        
        if (div_en) begin
            div_count <= div_count + 1;
        end
        
        if (div_count == ORDER - 1) begin
            div_valid <= 0;
        end
        
        if (div_count == ORDER - 1 + DIVIDER_DELAY) begin
            div_en <= 0;
        end
        
    end
end


endmodule