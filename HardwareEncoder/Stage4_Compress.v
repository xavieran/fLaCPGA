//Stage4_Compress.v


`default_nettype none


module Stage3_Encode (
    input wire iClock,
    input wire iEnable,
    input wire iReset,
    
    input wire iValid,
    input wire [15:0] iResidual,
    
    output wire oRamEnable1,
    output wire [15:0] oRamAddress1, 
    output wire [15:0] oRamData1,
    
    output wire oRamEnable2,
    output wire [15:0] oRamAddress2, 
    output wire [15:0] oRamData2
    );



RiceOptimizer ro (
    .iClock,
    .iEnable, 
    .iReset(f12_rst),
    
    .iResidual(f12_residual),
    
    .oBest(5)
    );

wire [15:0] re_msb, re_lsb, re_bu;
wire re_valid;

RiceEncoder re (
    .iClock(iClock),
    .iReset(f12_rst),
    
    .iValid(f12_valid),
    .iSample(f12_residual), 
    .oMSB(re_msb),
    .oLSB(re_lsb), 
    .oBitsUsed(re_bu),
    .oValid(re_valid)
    );

wire [15:0] rw_ra1, rw_rd1, rw_ra2, rw_rd2;
wire rw_re1, rw_re2;

RiceWriter rw (
      .iClock(iClock),
      .iReset(f12_rst), 
      .iEnable(re_valid), 
      
      .iChangeParam(0),
      .iFlush(0),
      .iTotal(re_bu),
      .iUpper(re_msb),
      .iLower(re_lsb), 
      .iRiceParam(5),
      
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


endmodule