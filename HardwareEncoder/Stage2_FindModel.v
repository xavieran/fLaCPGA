/* 
 * Stage 2 - Finds the appropriate model coefficients
 * 1. Divides the autocorrelation coefficients
 * 2. Runs the Durbinator on them
 * 3. Quantizes and spits out the model coefficients
 */


module Stage2_FindModel (
    input wire iClock,
    input wire iEnable, 
    input wire iReset,
    
    input wire signed [15:0] iSample,
    input wire iSValid,
    output wire signed [15:0] oDSample,
    output wire oDValid,
    
    input wire [63:0] iACF,
    input wire iValid,
    
    output wire signed [14:0] oModel,
    output wire [3:0] oM, 
    output wire oValid,
    output wire oDone
    );

wire [31:0] facf;
wire fvalid;

ACFDivider div (
    .iClock(iClock),
    .iEnable(iEnable),
    .iReset(iReset), 
    
    .iACF(iACF),
    .iValid(iValid),
    
    .ofACF(facf),
    .oValid(fvalid)
    );

wire [3:0] d_m;
wire [31:0] d_model;
wire d_valid;
wire d_done;

Durbinator durb (
    .iClock(iClock),
    .iEnable(iEnable), 
    .iReset(iReset),
    
    .iACF(facf),
    .iValid(fvalid),
    
    .oM(d_m),
    .oModel(d_model),
    
    .oValid(d_valid),
    .oDone(d_done)
    );


wire signed [14:0] q_model;
wire q_valid;
wire [3:0] q_m;

reg [11:0] q_done;

Quantizer quant (
    .iClock(iClock),
    .iEnable(iEnable),
    .iReset(iReset),
    
    .iM(d_m),
    .iValid(d_valid),
    .iFloatCoeff(d_model),
    .oQuantizedCoeff(q_model),
    .oValid(q_valid),
    .oM(q_m)
    );

assign oModel = q_model;
assign oM = q_m;
assign oValid = q_valid;
assign oDone = q_done[11];


/* 22 cycles to divide all the coefficients */
wire signed [15:0] dr1_sample;
reg [21:0] dr1_read;

DelayRegister #(.LENGTH(22)) dr1 (
    .iClock(iClock),
    .iEnable(iSValid),
    .iData(iSample),
    .oData(dr1_sample));

wire fifo1_empty, fifo1_full;
wire [9:0] fifo1_usedw;
wire signed [15:0] fifo1_sample;

mf_fifo1024 fifo1 (
    .clock(iClock),
    .data(dr1_sample),
    .rdreq((fifo1_usedw == 1023)),
    .wrreq(dr1_read[21]),
    .empty(fifo1_empty),
    .full(fifo1_full),
    .usedw(fifo1_usedw),
    .q(fifo1_sample));

wire fifo2_empty, fifo2_full;
wire [6:0] fifo2_usedw;
wire signed [15:0] fifo2_sample;

mf_fifo128 fifo2 (
    .clock(iClock),
    .data(fifo1_sample),
    .rdreq(fifo2_usedw == 127),
    .wrreq((fifo1_usedw == 1023)),
    .empty(fifo2_empty),
    .full(fifo2_full),
    .usedw(fifo2_usedw),
    .q(fifo2_sample));

DelayRegister #(.LENGTH(13)) dr2 (
    .iClock(iClock),
    .iEnable((fifo2_usedw == 127)),
    .iData(fifo2_sample),
    .oData(oDSample));

reg [14:0] dr2_read;

assign oDValid = dr2_read[14];

always @(posedge iClock) begin
    dr2_read <= dr2_read << 1 | (fifo2_usedw == 127);
    dr1_read <= dr1_read << 1 | iSValid;
    q_done <= q_done << 1 | d_done;
end

endmodule