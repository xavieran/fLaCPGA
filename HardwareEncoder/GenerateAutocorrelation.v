//`include "fp_divider_bb.v"
//`include "fp_convert_bb.v"
//`default_nettype none

module GenerateAutocorrelation (
    input wire iClock,
    input wire iEnable, 
    input wire iReset,
    
    input wire signed [15:0] iSample,

    output wire [31:0] oACF,
    output wire oValid
    );

parameter LAGS = 12;
parameter BLOCK_SIZE = 4096;
parameter DIVIDER_DELAY = 14;
parameter CONVERTER_DELAY = 7;

reg [63:0] integer_data;
reg [42:0] converter_mux_out;
wire [31:0] floating_data;

reg start_division;

reg [31:0] numerator, denominator;
wire [31:0] result;
reg div_en, conv_en;
reg done;

reg [12:0] sample_count;

reg [5:0] process_counter;
wire [3:0] converter_select = process_counter;



integer i;

reg signed [42:0] integer_acf_work [0:LAGS];
reg signed [42:0] integer_acf [0:LAGS];
reg [31:0] floating_acf[0:LAGS];

reg signed [31:0] lags [0:LAGS];
reg signed [15:0] dataq [0:LAGS];


wire [31:0] one = 32'h3f800000;
reg [31:0] first;

assign oACF = result | first;
/*assign oACF = integer_acf[0] & integer_acf[1] & integer_acf[2] &  
              integer_acf[3] & integer_acf[4] & integer_acf[5] & 
              integer_acf[6] & integer_acf[7] & integer_acf[8] & 
              integer_acf[9] & integer_acf[10] & integer_acf[11];*/ 
assign oValid = done;

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
            integer_acf_work[i] <= 0;
            integer_acf[i] <= 0;
            dataq[i] <= 0;
            lags[i] <= 0;
        end
        sample_count <= 0;
    end else if (iEnable) begin
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
            integer_acf_work[i] <= integer_acf_work[i] + lags[i];
        end
        
        if (sample_count == BLOCK_SIZE) begin
            /* Reset the sample count and the working sums, lags, dataq
             * Copy across the working sums to the fp calculation sums
             */
            sample_count <= 0;            
            for (i = 0; i <= LAGS; i = i + 1) begin
                integer_acf[i] <= integer_acf_work[i];
                
                integer_acf_work[i] <= 0;
                dataq[i] <= 0;
                lags[i] <= 0;
            end
        end else begin
            sample_count <= sample_count + 1'b1;
        end
        
    end
end

always @(posedge iClock) begin
    if (iReset) begin
        for (i = 0; i <= LAGS; i = i + 1) begin
            floating_acf[i] <= 0;
        end
        
        start_division <= 0;
        integer_data <= 0;
        process_counter <= 0;
        
        numerator <= 0;
        denominator <= 1;
        
        div_en <= 0;
        conv_en <= 0;
        done <= 0;
        first <= 0;
    end else if (iEnable) begin
        if (sample_count == BLOCK_SIZE) begin
            /* Start the division process */
            start_division <= 1'b1;
            conv_en <= 1'b1;
            div_en <= 1'b1;
            process_counter <= 0;
            done <= 0;
        end
        first <= 0;
        
        if (start_division) begin
            process_counter <= process_counter + 1'b1;
        end
        
        integer_data <= converter_mux_out;
        
        if (process_counter == CONVERTER_DELAY) begin
            denominator <= floating_data;
        end else begin
            numerator <= floating_data;
        end
        
        if (process_counter == CONVERTER_DELAY + DIVIDER_DELAY) begin
            done <= 1'b1;
            first <= one;
        end

        if (process_counter == CONVERTER_DELAY + DIVIDER_DELAY + LAGS + 1) begin
            done <= 1'b0;
            start_division <= 1'b0;
            numerator <= 0;
            denominator <= 0;
        end
    end
end

always @(converter_select or integer_acf) begin
    if (converter_select <= LAGS) begin
        converter_mux_out = {21'b0, integer_acf[converter_select]};
    end else begin
        converter_mux_out = 0;
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