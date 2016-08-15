comparators = 15

print """module ChooseBestRice (
    input wire iClock,
    input wire iEnable, 
    input wire iReset, """
print
for i in range(0, comparators):
    print "    input wire signed [16:0] iRE_BU_%d,"%i
print "    output wire [3:0] oBest"
print "    );"
print

print "reg [3:0] best;"
print "assign oBest = best;"
print

for i in range(0, comparators): 
    print "reg [27:0] Total_BU_%d;"%i
print

print """
always @(posedge iClock) begin
    if (iReset) begin
        best <= 0;
"""
for i in range(0, comparators):
    print "        Total_BU_%d <= 0;"%i
print """   end else if (iEnable) begin"""

for i in range(0, comparators):
    print "        Total_BU_%d <= Total_BU_%d + iRE_BU_%d;"%(i, i, i)
print

BUs = ["Total_BU_%d"%i for i in range(0, comparators)]

for i in range(0, comparators): 
    current = BUs.pop(i)
    print "        if ("
    for b in BUs[:-1]:
        print "        ", current, " < ", b, " &&"
    print "        ", current, " < " , BUs[-1], ") best <= 4'd%d;"%i
    print
    BUs.insert(i, current)
print "    end"
print "end"
print "endmodule"