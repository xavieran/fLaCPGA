//Stage4_Compress.v


`default_nettype none


module Stage4_Compress (
    input wire iClock,
    input wire iEnable,
    input wire iReset,
    
    input wire iFrameDone,
    input wire [3:0] iM,
    input wire iValid,
    input wire [15:0] iResidual,
    
    output wire oRamEnable1,
    output wire [15:0] oRamAddress1, 
    output wire [15:0] oRamData1,
    
    output wire oRamEnable2,
    output wire [15:0] oRamAddress2, 
    output wire [15:0] oRamData2
    );

parameter PARTITION_SIZE = 1024;
reg [3:0] m;

wire [3:0] best_param;

reg rst_override;
reg ro_select;
reg ro_rst;
wire [3:0] ro1_best;
wire ro1_done;

reg [1023:0] valid_delay;

RiceOptimizer ro1 (
    .iClock(iClock),
    .iEnable(iEnable), 
    .iReset(ro_rst & ro_select | rst_override),
    
    .iNSamples(PARTITION_SIZE - m),
    .iValid(iValid & !ro_select),
    .iResidual(iResidual),
    
    .oBest(ro1_best),
    .oDone(ro1_done)
    );

wire [3:0] ro2_best;
wire ro2_done;

RiceOptimizer ro2 (
    .iClock(iClock),
    .iEnable(iEnable), 
    .iReset(ro_rst & !ro_select | rst_override),
    
    .iNSamples(PARTITION_SIZE - m),
    .iValid(iValid & ro_select),
    .iResidual(iResidual),
    
    .oBest(ro2_best),
    .oDone(ro2_done)
    );

wire signed [15:0] fifo1_sample;
wire [9:0] fifo1_usedw;
wire fifo1_empty, fifo1_full;
mf_fifo1024 fifo1 (
    .clock(iClock),
    .data(iResidual),
    .rdreq((fifo1_usedw == 1023)),
    .wrreq(iValid),
    .empty(fifo1_empty),
    .full(fifo1_full),
    .usedw(fifo1_usedw),
    .q(fifo1_sample));


reg re_rst;
wire [15:0] re_msb, re_lsb, re_bu;
wire re_valid;
reg [3:0] current_best;
VariableRiceEncoder vre (
    .iClock(iClock),
    .iReset(re_rst),
    
    .iValid(valid_delay[1023]),
    .iSample(fifo1_sample), 
    
    .iRiceParam(current_best),
    .oMSB(re_msb),
    .oLSB(re_lsb), 
    .oBitsUsed(re_bu),
    .oValid(re_valid)
    );

wire [15:0] rw_ra1, rw_rd1, rw_ra2, rw_rd2;
wire rw_re1, rw_re2;
reg rw_rst, rw_flush;
reg [12:0] rw_ch_param;
RiceWriter rw (
      .iClock(iClock),
      .iReset(rw_rst), 
      .iEnable(re_valid), 
      
      .iChangeParam(rw_ch_param[12]),
      .iFlush(rw_flush),
      .iTotal(re_bu),
      .iUpper(re_msb),
      .iLower(re_lsb), 
      .iRiceParam(current_best),
      
      .oRamEnable1(rw_re1),
      .oRamAddress1(rw_ra1), 
      .oRamData1(rw_rd1),
      
      .oRamEnable2(rw_re2),
      .oRamAddress2(rw_ra2), 
      .oRamData2(rw_rd2)
      );

assign oRamEnable1 = rw_re1;
assign oRamEnable2 = rw_re2;
assign oRamAddress1 = rw_ra1;
assign oRamAddress2 = rw_ra2;
assign oRamData1 = rw_rd1;
assign oRamData2 = rw_rd2;

assign best_param = ro_select ? ro2_best : ro1_best;

reg [2:0] partition_count;

always @(posedge iClock) begin
    if (iReset) begin
        ro_rst <= 1;
        re_rst <= 1;
        rw_rst <= 1;
        rst_override <= 1;
        rw_ch_param <= 0;
        current_best <= 0;
        ro_select <= 0;
        partition_count <= 0;
        m <= 0;
        valid_delay <= 0;
    end else if (iEnable) begin
        ro_rst <= 0;
        re_rst <= 0;
        rw_rst <= 0;
        rst_override <= 0;
        valid_delay <= valid_delay << 1 | iValid;
        rw_ch_param <= rw_ch_param << 1;
        
        if (iFrameDone) begin
            m <= iM;
        end
        
        if (ro1_done | ro2_done) begin
            current_best <= best_param;
            ro_rst <= 1;
            ro_select <= !ro_select;
            
            rw_ch_param <= 1 << (12 - m);
            
            m <= 0;
        end
    end
end

endmodule