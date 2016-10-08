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
    output wire [15:0] oRamData2,
    
    output wire oFrameDone
    );

parameter PARTITION_SIZE = 4096;
reg [3:0] m;

wire [3:0] best_param;

reg ro_rst;
wire [3:0] ro_best;
wire ro_done;

reg [4095:0] valid_delay;

RiceOptimizer ro (
    .iClock(iClock),
    .iEnable(iEnable), 
    .iReset(ro_rst),
    
    .iNSamples(PARTITION_SIZE - m),
    .iValid(iValid),
    .iResidual(iResidual),
    
    .oBest(ro_best),
    .oDone(ro_done)
    );

wire signed [15:0] fifo1_sample;
wire [11:0] fifo1_usedw;
wire fifo1_empty, fifo1_full;
mf_fifo fifo1 (
    .clock(iClock),
    .data(iResidual),
    .rdreq((fifo1_usedw == 4095)),
    .wrreq(iEnable),
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
    
    .iValid(valid_delay[4095]),
    .iSample(fifo1_sample), 
    
    .iRiceParam(current_best),
    .oMSB(re_msb),
    .oLSB(re_lsb), 
    .oBitsUsed(re_bu),
    .oValid(re_valid)
    );

wire [15:0] rw_ra1, rw_rd1, rw_ra2, rw_rd2;
wire rw_re1, rw_re2;
reg rw_rst, rw_flush, rw_ch_param;
RiceWriter rw (
      .iClock(iClock),
      .iReset(rw_rst), 
      .iEnable(re_valid | rw_ch_param | rw_flush), 
      
      .iChangeParam(rw_ch_param),
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


reg frame_done;
reg first_time;
reg rRE_val;
reg dRE_val;

assign oRamEnable1 = rw_re1;
assign oRamEnable2 = rw_re2;
assign oRamAddress1 = rw_ra1;
assign oRamAddress2 = rw_ra2;
assign oRamData1 = rw_rd1;
assign oRamData2 = rw_rd2;
assign oFrameDone = frame_done;
assign best_param = ro_best;



always @(posedge iClock) begin
    if (iReset) begin
        ro_rst <= 1;
        re_rst <= 1;
        rw_rst <= 1;
        rw_ch_param <= 0;
        rw_flush <= 0;
        current_best <= 0;
        m <= 0;
        valid_delay <= 0;
        first_time <= 1;
        rRE_val <= 0;
        dRE_val <= 0;
        frame_done <= 0;
    end else if (iEnable) begin
        valid_delay <= valid_delay << 1 | iValid;
        ro_rst <= 0;
        re_rst <= 0;
        rw_rst <= 0;
        rw_flush <= 0;
        rw_ch_param <= 0;
        frame_done <= 0;
        rRE_val <= re_valid;
        dRE_val <= rRE_val;
        
        if (iFrameDone) begin
            m <= iM;
        end
        

        if (ro_done) begin
            ro_rst <= 1;
            current_best <= best_param;
            if (first_time) begin
                rw_ch_param <= 1;
                first_time <= 0;
            end
        end
        
        if (rRE_val == 0 && dRE_val == 1) begin
            rw_flush <= 1;
        end
        
        if (rw_flush) begin
            frame_done <= 1;
            rw_ch_param <= 1;
        end 
    end
end

endmodule