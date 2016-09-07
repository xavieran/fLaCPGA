#!/usr/bin/env python


order = 12
width = 28

print """
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
    
    output wire [3:0] oBestPredictor
    );
    
    
wire [3:0] min_error;
assign oBestPredictor = min_error + 1;

"""


register_string = """
reg [{width}:0] f{i}_total_error;
wire f{i}_load = (iM == {i}) ? iLoad : 0;
wire f{i}_valid;
wire signed [15:0] f{i}_residual;
wire [15:0] abs_f{i}_residual = f{i}_residual >= 0 ? f{i}_residual : -f{i}_residual;"""



module_string = """
FIR{i} f{i} (
    .iEnable(iEnable),
    .iClock(iClock),
    .iReset(iReset),
    .iLoad(f{i}_load),
    .iQLP(iCoeff),
    .iValid(iValid),
    .iSample(iSample),
    .oResidual(f{i}_residual), 
    .oValid(f{i}_valid)
    );
"""

for i in range(1, order + 1):
    print register_string.format(width=width-1, i=i)

for i in range(1,order + 1):
    print module_string.format(i=i)
    
print """
Compare12 c12 (
    .iClock(iClock),
    .iEnable(iEnable),
"""

for i in range(1, order + 1):
    print " "*3, ".iIn{in1}(f{i}_total_error),".format(i=i, in1=i-1)

print " "*3, ".oMinimum(min_error));"
    
    
print """
always @(posedge iClock) begin
    if (iReset) begin
"""

for i in range(1,order + 1):
    print " "*7, "f{i}_total_error <= 0;".format(i=i)
print """
    end else begin
"""

for i in range(1,order + 1):
    print " "*7, """if (f{i}_valid) f{i}_total_error <= f{i}_total_error + abs_f{i}_residual;
""".format(i=i)
        

print """
    end
end
endmodule
"""
