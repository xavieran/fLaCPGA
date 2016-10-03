/* The optimal rice parameter can be estimated from the expectation of 
 * the sequence of numbers as log(|E|, 2) according to  Weinberger (1996)
 * This can be calculated as the smallest k that satisfies 2^k*N >= A
 * where N is the number of samples seen and A is their sum
 */

module RiceOptimizer (
    input iClock,
    input iEnable, 
    input iReset,
    
    input iValid,
    input signed [15:0] iResidual,
    
    output signed [3:0] oBest,
    output oDone
    );

parameter PARTITION_SIZE = 1024;

reg [15:0] sample_count;
wire re_rst;
reg done;

wire [15:0] r0_bu;
wire r0_v;
RiceEncoder0 r0 (
    .iClock(iClock), 
    .iReset(re_rst), 
    .iValid(iValid), 
    .iSample(iResidual), 
    .oBitsUsed(r0_bu),
    .oValid(r0_v));

wire [15:0] r1_bu;
wire r1_v;
RiceEncoder #(.rice_param(1)) r1 (
    .iClock(iClock), 
    .iReset(re_rst), 
    .iValid(iValid), 
    .iSample(iResidual), 
    .oBitsUsed(r1_bu),
    .oValid(r1_v));

wire [15:0] r2_bu;
wire r2_v;
RiceEncoder #(.rice_param(2)) r2 (
    .iClock(iClock), 
    .iReset(re_rst), 
    .iValid(iValid), 
    .iSample(iResidual), 
    .oBitsUsed(r2_bu),
    .oValid(r2_v));

wire [15:0] r3_bu;
wire r3_v;
RiceEncoder #(.rice_param(3)) r3 (
    .iClock(iClock), 
    .iReset(re_rst), 
    .iValid(iValid), 
    .iSample(iResidual), 
    .oBitsUsed(r3_bu),
    .oValid(r3_v));

wire [15:0] r4_bu;
wire r4_v;
RiceEncoder #(.rice_param(4)) r4 (
    .iClock(iClock), 
    .iReset(re_rst), 
    .iValid(iValid), 
    .iSample(iResidual), 
    .oBitsUsed(r4_bu),
    .oValid(r4_v));

wire [15:0] r5_bu;
wire r5_v;
RiceEncoder #(.rice_param(5)) r5 (
    .iClock(iClock), 
    .iReset(re_rst), 
    .iValid(iValid), 
    .iSample(iResidual), 
    .oBitsUsed(r5_bu),
    .oValid(r5_v));

wire [15:0] r6_bu;
wire r6_v;
RiceEncoder #(.rice_param(6)) r6 (
    .iClock(iClock), 
    .iReset(re_rst), 
    .iValid(iValid), 
    .iSample(iResidual), 
    .oBitsUsed(r6_bu),
    .oValid(r6_v));

wire [15:0] r7_bu;
wire r7_v;
RiceEncoder #(.rice_param(7)) r7 (
    .iClock(iClock), 
    .iReset(re_rst), 
    .iValid(iValid), 
    .iSample(iResidual), 
    .oBitsUsed(r7_bu),
    .oValid(r7_v));

wire [15:0] r8_bu;
wire r8_v;
RiceEncoder #(.rice_param(8)) r8 (
    .iClock(iClock), 
    .iReset(re_rst), 
    .iValid(iValid), 
    .iSample(iResidual), 
    .oBitsUsed(r8_bu),
    .oValid(r8_v));

wire [15:0] r9_bu;
wire r9_v;
RiceEncoder #(.rice_param(9)) r9 (
    .iClock(iClock), 
    .iReset(re_rst), 
    .iValid(iValid), 
    .iSample(iResidual), 
    .oBitsUsed(r9_bu),
    .oValid(r9_v));

wire [15:0] r10_bu;
wire r10_v;
RiceEncoder #(.rice_param(10)) r10 (
    .iClock(iClock), 
    .iReset(re_rst), 
    .iValid(iValid), 
    .iSample(iResidual), 
    .oBitsUsed(r10_bu),
    .oValid(r10_v));

wire [15:0] r11_bu;
wire r11_v;
RiceEncoder #(.rice_param(11)) r11 (
    .iClock(iClock), 
    .iReset(re_rst), 
    .iValid(iValid), 
    .iSample(iResidual), 
    .oBitsUsed(r11_bu),
    .oValid(r11_v));

wire [15:0] r12_bu;
wire r12_v;
RiceEncoder #(.rice_param(12)) r12 (
    .iClock(iClock), 
    .iReset(re_rst), 
    .iValid(iValid), 
    .iSample(iResidual), 
    .oBitsUsed(r12_bu),
    .oValid(r12_v));

wire [15:0] r13_bu;
wire r13_v;
RiceEncoder  #(.rice_param(13)) r13 (
    .iClock(iClock), 
    .iReset(re_rst), 
    .iValid(iValid), 
    .iSample(iResidual), 
    .oBitsUsed(r13_bu),
    .oValid(r13_v));

wire [15:0] r14_bu;
wire r14_v;
RiceEncoder #(.rice_param(14)) r14 (
    .iClock(iClock), 
    .iReset(re_rst), 
    .iValid(iValid), 
    .iSample(iResidual), 
    .oBitsUsed(r14_bu),
    .oValid(r14_v));


reg [31:0] r0_total;
reg [31:0] r1_total;
reg [31:0] r2_total;
reg [31:0] r3_total;
reg [31:0] r4_total;
reg [31:0] r5_total;
reg [31:0] r6_total;
reg [31:0] r7_total;
reg [31:0] r8_total;
reg [31:0] r9_total;
reg [31:0] r10_total;
reg [31:0] r11_total;
reg [31:0] r12_total;
reg [31:0] r13_total;
reg [31:0] r14_total;
wire [3:0] best;

Compare15 c15 (
    .iClock(iClock),
    .iEnable(iEnable),
    
    .iIn0(r0_total),
    .iIn1(r1_total),
    .iIn2(r2_total),
    .iIn3(r3_total),
    .iIn4(r4_total),
    .iIn5(r5_total),
    .iIn6(r6_total),
    .iIn7(r7_total),
    .iIn8(r8_total),
    .iIn9(r9_total),
    .iIn10(r10_total),
    .iIn11(r11_total),
    .iIn12(r12_total),
    .iIn13(r13_total),
    .iIn14(r14_total),
    .oMinimum(best));

assign oDone = done;
assign oBest = best;
assign re_rst = iReset;

always @(posedge iClock) begin
    if (iReset) begin
        r0_total  <= 0;
        r1_total  <= 0;
        r2_total  <= 0;
        r3_total  <= 0;
        r4_total  <= 0;
        r5_total  <= 0;
        r6_total  <= 0;
        r7_total  <= 0;
        r8_total  <= 0;
        r9_total  <= 0;
        r10_total <= 0;
        r11_total <= 0;
        r12_total <= 0;
        r13_total <= 0;
        r14_total <= 0;
        done <= 0;
        sample_count <= 0;
    end else begin
        if (iValid) sample_count <= sample_count + 1;
        if (r0_v) r0_total <= r0_total + r0_bu;

        if (r1_v) r1_total <= r1_total + r1_bu;
        if (r2_v) r2_total <= r2_total + r2_bu;
        if (r3_v) r3_total <= r3_total + r3_bu;
        if (r4_v) r4_total <= r4_total + r4_bu;
        if (r5_v) r5_total <= r5_total + r5_bu;
        if (r6_v) r6_total <= r6_total + r6_bu;
        if (r7_v) r7_total <= r7_total + r7_bu;
        if (r8_v) r8_total <= r8_total + r8_bu;
        if (r9_v) r9_total <= r9_total + r9_bu;
        if (r10_v) r10_total <= r10_total + r10_bu;
        if (r11_v) r11_total <= r11_total + r11_bu;
        if (r12_v) r12_total <= r12_total + r12_bu;
        if (r13_v) r13_total <= r13_total + r13_bu;
        if (r14_v) r14_total <= r14_total + r14_bu;
        
        if (sample_count == (PARTITION_SIZE - 8)) begin
            done <= 1;
        end
        
        if (done == 1) done <= 0;
    end
end


endmodule