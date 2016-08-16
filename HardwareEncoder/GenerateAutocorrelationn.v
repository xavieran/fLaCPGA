//`include "fp_divider_bb.v"
//`include "fp_convert_bb.v"
`default_nettype none

module GenerateAutocorrelation (
    input wire iClock,
    input wire iEnable, 
    input wire iReset,
    
    input wire signed [15:0] iSample,

    output wire [31:0] oACF0,
    output wire [31:0] oACF1,
    output wire [31:0] oACF2,
    output wire [31:0] oACF3,
    output reg oDone
    );

parameter LAGS = 12;
parameter BLOCK_SIZE = 4096;
parameter DIVIDER_DELAY = 14;
parameter CONVERTER_DELAY = 7;

reg [63:0] integer_data;
wire [31:0] floating_data;

reg [31:0] numerator, denominator;
wire [31:0] result;
reg div_en, conv_en;

reg [12:0] sample_count;
reg [3:0] division_step;

reg [4:0] division_counter;
reg [4:0] conversion_counter;

integer i;

reg signed [42:0] integer_acf [0:LAGS];
reg [31:0] floating_acf[0:LAGS];

reg signed [31:0] lags [0:LAGS];
reg signed [15:0] dataq [0:LAGS];

assign oACF0 = floating_acf[0];
assign oACF1 = floating_acf[1];
assign oACF2 = floating_acf[2];
assign oACF3 = floating_acf[3];

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
        /* Reset arrays */
        for (i = 0; i <= LAGS; i = i + 1) begin
            integer_acf[i] <= 0;
            dataq[i] <= 0;
            lags[i] <= 0;
        end
        
        sample_count <= 0;
        division_step <= 0;
        
        division_counter <= 0;
        conversion_counter <= 0;
        
        integer_data <= 0;
        numerator <= 0;
        denominator <= 0;
        div_en <= 0;
        conv_en <= 0;
        
        oDone <= 0;
    end else if (iEnable) begin
        /* Sum the lags of the incoming data */
        if (sample_count < BLOCK_SIZE) begin
            sample_count <= sample_count + 1'b1;
            
            /* Shift the data through */
            for (i = LAGS - 1; i >= 0; i = i - 1) begin
                dataq[i + 1] <= dataq[i];
            end
            dataq[0] <= iSample;
            
            /* Calculate the lags */
            for (i = 0; i <= LAGS; i = i + 1) begin
                lags[i] <= dataq[0]*dataq[i];
            end
        
            /* Calculate the autocorrelation sums */
            for (i = 0; i <= LAGS; i = i + 1) begin
                integer_acf[i] <= integer_acf[i] + lags[i];
            end
            
        /* Divide the result */
        end else if (!oDone) begin
            conv_en <= 1'b1;
            
            if (conversion_counter < CONVERTER_DELAY) begin
                conversion_counter <= conversion_counter + 1'b1;
                integer_data <= integer_acf[0];
                
                for (i = 0; i < LAGS; i = i + 1) begin
                    integer_acf[i] <= integer_acf[i + 1];
                end
                
            end else begin
                if (division_counter == 0) begin
                    denominator <= floating_data;
                end else begin
                    numerator <= floating_data;
                    div_en <= 1'b1;
                end
                
                if (division_counter >= DIVIDER_DELAY + 1) begin
                    floating_acf[LAGS] <= result;
                    
                    for (i = 0; i < LAGS; i = i + 1) begin
                        floating_acf[i] <= floating_acf[i + 1];
                    end
                end
                
                division_counter <= division_counter + 1'b1;
                
                if (division_counter == DIVIDER_DELAY + LAGS + 1) begin
                    oDone <= 1'b1;
                    div_en <= 1'b0;
                    conv_en <= 1'b0;
                    for (i = 0; i <= LAGS; i = i + 1) begin
                        $display("ACF%d == %f", i, $bitstoshortreal(floating_acf[i]));
                    end
                end
            end
        end
    end
end

endmodule   

/* function ACF = my_autocorr(data, lags)

i=1, j = 0;
j = 1;

ACF = zeros(lags + 1, 1);

for i = 1:max(size(data))
    for j = 0:lags
        if (i + j) < max(size(data))
            ACF(j + 1) = ACF(j + 1) + data(i)*data(i + j);
        end
    end
end

ACF = ACF/ACF(1);
end*/