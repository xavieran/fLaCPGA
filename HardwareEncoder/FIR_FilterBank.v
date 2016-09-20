
/* Computes the sum of errors, outputs the best residual */

module FIR_FilterBank (
    input wire iClock, 
    input wire iEnable, 
    input wire iReset,
    
    input wire iLoad,
    input wire [3:0] iM,
    input wire [11:0] iCoeff,
    
    input wire iValid, 
    input wire signed [15:0] iSample, 
    
    output wire [3:0] oBestPredictor,
    output wire oDone
    );
    
reg done;
reg [15:0] sample_count;
wire [3:0] min_error;
assign oBestPredictor = min_error + 1;
assign oDone = done;


reg [27:0] f1_total_error;
wire f1_load = (iM == 1) ? iLoad : 0;
wire f1_valid;
wire signed [15:0] f1_residual;
wire [15:0] abs_f1_residual = f1_residual >= 0 ? f1_residual : -f1_residual;

reg [27:0] f2_total_error;
wire f2_load = (iM == 2) ? iLoad : 0;
wire f2_valid;
wire signed [15:0] f2_residual;
wire [15:0] abs_f2_residual = f2_residual >= 0 ? f2_residual : -f2_residual;

reg [27:0] f3_total_error;
wire f3_load = (iM == 3) ? iLoad : 0;
wire f3_valid;
wire signed [15:0] f3_residual;
wire [15:0] abs_f3_residual = f3_residual >= 0 ? f3_residual : -f3_residual;

reg [27:0] f4_total_error;
wire f4_load = (iM == 4) ? iLoad : 0;
wire f4_valid;
wire signed [15:0] f4_residual;
wire [15:0] abs_f4_residual = f4_residual >= 0 ? f4_residual : -f4_residual;

reg [27:0] f5_total_error;
wire f5_load = (iM == 5) ? iLoad : 0;
wire f5_valid;
wire signed [15:0] f5_residual;
wire [15:0] abs_f5_residual = f5_residual >= 0 ? f5_residual : -f5_residual;

reg [27:0] f6_total_error;
wire f6_load = (iM == 6) ? iLoad : 0;
wire f6_valid;
wire signed [15:0] f6_residual;
wire [15:0] abs_f6_residual = f6_residual >= 0 ? f6_residual : -f6_residual;

reg [27:0] f7_total_error;
wire f7_load = (iM == 7) ? iLoad : 0;
wire f7_valid;
wire signed [15:0] f7_residual;
wire [15:0] abs_f7_residual = f7_residual >= 0 ? f7_residual : -f7_residual;

reg [27:0] f8_total_error;
wire f8_load = (iM == 8) ? iLoad : 0;
wire f8_valid;
wire signed [15:0] f8_residual;
wire [15:0] abs_f8_residual = f8_residual >= 0 ? f8_residual : -f8_residual;

reg [27:0] f9_total_error;
wire f9_load = (iM == 9) ? iLoad : 0;
wire f9_valid;
wire signed [15:0] f9_residual;
wire [15:0] abs_f9_residual = f9_residual >= 0 ? f9_residual : -f9_residual;

reg [27:0] f10_total_error;
wire f10_load = (iM == 10) ? iLoad : 0;
wire f10_valid;
wire signed [15:0] f10_residual;
wire [15:0] abs_f10_residual = f10_residual >= 0 ? f10_residual : -f10_residual;

reg [27:0] f11_total_error;
wire f11_load = (iM == 11) ? iLoad : 0;
wire f11_valid;
wire signed [15:0] f11_residual;
wire [15:0] abs_f11_residual = f11_residual >= 0 ? f11_residual : -f11_residual;

reg [27:0] f12_total_error;
wire f12_load = (iM == 12) ? iLoad : 0;
wire f12_valid;
wire signed [15:0] f12_residual;
wire [15:0] abs_f12_residual = f12_residual >= 0 ? f12_residual : -f12_residual;

FIR1 f1 (
    .iEnable(iEnable),
    .iClock(iClock),
    .iReset(iReset),
    .iLoad(f1_load),
    .iQLP(iCoeff),
    .iValid(iValid),
    .iSample(iSample),
    .oResidual(f1_residual), 
    .oValid(f1_valid)
    );


FIR2 f2 (
    .iEnable(iEnable),
    .iClock(iClock),
    .iReset(iReset),
    .iLoad(f2_load),
    .iQLP(iCoeff),
    .iValid(iValid),
    .iSample(iSample),
    .oResidual(f2_residual), 
    .oValid(f2_valid)
    );


FIR3 f3 (
    .iEnable(iEnable),
    .iClock(iClock),
    .iReset(iReset),
    .iLoad(f3_load),
    .iQLP(iCoeff),
    .iValid(iValid),
    .iSample(iSample),
    .oResidual(f3_residual), 
    .oValid(f3_valid)
    );


FIR4 f4 (
    .iEnable(iEnable),
    .iClock(iClock),
    .iReset(iReset),
    .iLoad(f4_load),
    .iQLP(iCoeff),
    .iValid(iValid),
    .iSample(iSample),
    .oResidual(f4_residual), 
    .oValid(f4_valid)
    );


FIR5 f5 (
    .iEnable(iEnable),
    .iClock(iClock),
    .iReset(iReset),
    .iLoad(f5_load),
    .iQLP(iCoeff),
    .iValid(iValid),
    .iSample(iSample),
    .oResidual(f5_residual), 
    .oValid(f5_valid)
    );


FIR6 f6 (
    .iEnable(iEnable),
    .iClock(iClock),
    .iReset(iReset),
    .iLoad(f6_load),
    .iQLP(iCoeff),
    .iValid(iValid),
    .iSample(iSample),
    .oResidual(f6_residual), 
    .oValid(f6_valid)
    );


FIR7 f7 (
    .iEnable(iEnable),
    .iClock(iClock),
    .iReset(iReset),
    .iLoad(f7_load),
    .iQLP(iCoeff),
    .iValid(iValid),
    .iSample(iSample),
    .oResidual(f7_residual), 
    .oValid(f7_valid)
    );


FIR8 f8 (
    .iEnable(iEnable),
    .iClock(iClock),
    .iReset(iReset),
    .iLoad(f8_load),
    .iQLP(iCoeff),
    .iValid(iValid),
    .iSample(iSample),
    .oResidual(f8_residual), 
    .oValid(f8_valid)
    );


FIR9 f9 (
    .iEnable(iEnable),
    .iClock(iClock),
    .iReset(iReset),
    .iLoad(f9_load),
    .iQLP(iCoeff),
    .iValid(iValid),
    .iSample(iSample),
    .oResidual(f9_residual), 
    .oValid(f9_valid)
    );


FIR10 f10 (
    .iEnable(iEnable),
    .iClock(iClock),
    .iReset(iReset),
    .iLoad(f10_load),
    .iQLP(iCoeff),
    .iValid(iValid),
    .iSample(iSample),
    .oResidual(f10_residual), 
    .oValid(f10_valid)
    );


FIR11 f11 (
    .iEnable(iEnable),
    .iClock(iClock),
    .iReset(iReset),
    .iLoad(f11_load),
    .iQLP(iCoeff),
    .iValid(iValid),
    .iSample(iSample),
    .oResidual(f11_residual), 
    .oValid(f11_valid)
    );


FIR12 f12 (
    .iEnable(iEnable),
    .iClock(iClock),
    .iReset(iReset),
    .iLoad(f12_load),
    .iQLP(iCoeff),
    .iValid(iValid),
    .iSample(iSample),
    .oResidual(f12_residual), 
    .oValid(f12_valid)
    );


Compare12 c12 (
    .iClock(iClock),
    .iEnable(iEnable),

    .iIn0(f1_total_error),
    .iIn1(f2_total_error),
    .iIn2(f3_total_error),
    .iIn3(f4_total_error),
    .iIn4(f5_total_error),
    .iIn5(f6_total_error),
    .iIn6(f7_total_error),
    .iIn7(f8_total_error),
    .iIn8(f9_total_error),
    .iIn9(f10_total_error),
    .iIn10(f11_total_error),
    .iIn11(f12_total_error),
    .oMinimum(min_error));

always @(posedge iClock) begin
    if (iReset) begin
        sample_count <= 0;
        done <= 0;
        f1_total_error <= 0;
        f2_total_error <= 0;
        f3_total_error <= 0;
        f4_total_error <= 0;
        f5_total_error <= 0;
        f6_total_error <= 0;
        f7_total_error <= 0;
        f8_total_error <= 0;
        f9_total_error <= 0;
        f10_total_error <= 0;
        f11_total_error <= 0;
        f12_total_error <= 0;
        
    end else begin
        if (iValid) sample_count <= sample_count + 1;
        if (f1_valid) f1_total_error <= f1_total_error + abs_f1_residual;

        if (f2_valid) f2_total_error <= f2_total_error + abs_f2_residual;

        if (f3_valid) f3_total_error <= f3_total_error + abs_f3_residual;

        if (f4_valid) f4_total_error <= f4_total_error + abs_f4_residual;

        if (f5_valid) f5_total_error <= f5_total_error + abs_f5_residual;

        if (f6_valid) f6_total_error <= f6_total_error + abs_f6_residual;

        if (f7_valid) f7_total_error <= f7_total_error + abs_f7_residual;

        if (f8_valid) f8_total_error <= f8_total_error + abs_f8_residual;

        if (f9_valid) f9_total_error <= f9_total_error + abs_f9_residual;

        if (f10_valid) f10_total_error <= f10_total_error + abs_f10_residual;

        if (f11_valid) f11_total_error <= f11_total_error + abs_f11_residual;

        if (f12_valid) f12_total_error <= f12_total_error + abs_f12_residual;
        
        if (sample_count == 4096) begin
            done <= 1;
        end
    end
end
endmodule

