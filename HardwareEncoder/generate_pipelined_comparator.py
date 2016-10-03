#!/usr/bin/env python

# Generate pipelined n-input comparator

from math import *

inputs = 15;
input_width = 31;
log2 = lambda x: int(ceil(log(x, 2)))

def generate_comps(inputs):
    return (inputs / 2, int(ceil(inputs/2.0) - inputs/2))


stages = log2(inputs)
input_list= ["iIn{i}".format(i=i) for i in range(0,inputs)]

print """
module Compare{inputs}(
    input wire iClock,
    input wire iEnable,
    """.format(inputs=inputs)
    
for i in input_list:
    print " "*3, "input wire [{widthn1}:0] ".format(widthn1=input_width - 1), i + ","

print " "*3, "output wire [3:0] oMinimum);"

print 

input_regs = input_list
index_registers = []
for i in range(stages):
    comps, regs = generate_comps(len(input_regs))
    outputs = ["index{i}_{j}".format(i=i,j=j) for j in range(comps)]
    
    if (regs > 0):
        outputs.append("rindex{i}_{jp1}".format(i=i,jp1=comps))
    index_registers.extend(outputs)
    input_regs = outputs

input_regs = input_list
value_registers = []
for i in range(stages):
    comps, regs = generate_comps(len(input_regs))
    outputs = ["value{i}_{j}".format(i=i,j=j) for j in range(comps)]
    
    if (regs > 0):
        outputs.append("rvalue{i}_{jp1}".format(i=i,jp1=comps))
    value_registers.extend(outputs)
    input_regs = outputs
    
for r in index_registers: 
    print "reg [3:0]",  r + ";"
for r in value_registers:
    print "reg [{widthn1}:0]".format(widthn1=input_width-1), r + ";"

print
print "assign oMinimum = ", index_registers[-1], ";"
    
print """
always @(posedge iClock) begin
    if (iEnable) begin"""

value_inputs = input_list
index_inputs = range(inputs)
for i in range(stages):
    comps, regs = generate_comps(len(value_inputs))
    value_outputs = ["value{i}_{j}".format(i=i, j=j) for j in range(comps)]
    index_outputs = ["index{i}_{j}".format(i=i, j=j) for j in range(comps)]
    if (regs > 0):
        value_outputs.append("rvalue{i}_{jp1}".format(i=i, jp1=comps))
        index_outputs.append("rindex{i}_{jp1}".format(i=i, jp1=comps))
                       
    for c in range(0, comps*2, 2):
        print " "*3, value_outputs[c/2], "<= ({a0} < {a1}) ? {a0} : {a1};".format(a0=value_inputs[c], a1=value_inputs[c+1])
        print " "*3, index_outputs[c/2], "<= ({a0} < {a1}) ? {i0} : {i1};".format(a0=value_inputs[c], a1=value_inputs[c+1],
                                                                                  i0=index_inputs[c], i1=index_inputs[c+1])
    for r in range(regs):
        print " "*3, value_outputs[-1], "<=", value_inputs[-1], ";"
        print " "*3, index_outputs[-1], "<=", index_inputs[-1], ";"
    
    value_inputs = value_outputs
    index_inputs = index_outputs
    

print """
    end
end

endmodule
"""
                       

    
