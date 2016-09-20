//`include "fp_divider_bb.v"
//`include "fp_convert_bb.v"
//`default_nettype none

module GenerateAutocorrelationSums (
    input wire iClock,
    input wire iEnable, 
    input wire iReset,
    
    input wire signed [15:0] iSample,

    output wire [42:0] oACF,
    output wire oValid
    );

parameter LAGS = 12;
parameter BLOCK_SIZE = 4096;

reg [12:0] sample_count;

reg [3:0] send_count;
reg start_sending;
reg valid;

integer i;

reg signed [42:0] integer_acf_work [0:LAGS];
reg signed [42:0] integer_acf [0:LAGS];

reg signed [31:0] lags [0:LAGS];
reg signed [15:0] dataq [0:LAGS];

assign oACF = integer_acf[0];
assign oValid = valid;

always @(posedge iClock) begin
    if (iReset) begin
        /* Reset arrays */
        for (i = 0; i <= LAGS; i = i + 1) begin
            integer_acf[i] <= 0;
            integer_acf_work[i] <= 0;
            dataq[i] <= 0;
            lags[i] <= 0;
        end
        sample_count <= 0;
        
        start_sending <= 0;
        send_count <= 0;
        valid <= 0;
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
        
        
        if (sample_count == BLOCK_SIZE) begin
            /* Start the division process */
            start_sending <= 1;
            send_count <= 0;
            valid <= 1;
        end
        
        if (start_sending) begin
            send_count <= send_count + 1'b1;
            
            for (i = 0; i < LAGS; i = i + 1) begin
                integer_acf[i] <= integer_acf[i + 1];
            end
        end
        
        if (send_count == LAGS) begin
            start_sending <= 0;
            valid <= 0;
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