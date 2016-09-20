/* Stage 1 - Calculates the autocorrelation sums
 * 
 * Latency of 4096 + 12 cycles
 */
`default_nettype none

module Stage1_Autocorrelation (
    input wire iClock,
    input wire iEnable, 
    input wire iReset,
    
    input wire  signed [15:0] iSample,
    input wire iValid,
    output wire signed [15:0] oDSample,
    output wire oDValid, 
    
    output wire [42:0] oACF,
    output wire oValid
    );

wire fifo1_empty, fifo1_full;
wire [11:0] fifo1_usedw;


GenerateAutocorrelationSums ga(
    .iClock(iClock),
    .iEnable(iValid), 
    .iReset(iReset),
    
    .iSample(iSample),

    .oACF(oACF),
    .oValid(oValid)
    );

wire signed [15:0] fifo1_sample;
/* 4096 cycles through the ACF calculator */
mf_fifo fifo1 (
    .clock(iClock),
    .data(iSample),
    .rdreq((fifo1_usedw == 4095)),
    .wrreq(iValid),
    .empty(fifo1_empty),
    .full(fifo1_full),
    .usedw(fifo1_usedw),
    .q(fifo1_sample));

/* 12 cycles to spit out the values */

reg [14:0] dr1_read;
DelayRegister #(.LENGTH(14)) dr1 (
    .iClock(iClock),
    .iEnable((fifo1_usedw == 4095)),
    .iData(fifo1_sample),
    .oData(oDSample));

assign oDValid = dr1_read[14];

always @(posedge iClock) begin
    dr1_read <= dr1_read << 1 | (fifo1_usedw == 4095);
end

endmodule