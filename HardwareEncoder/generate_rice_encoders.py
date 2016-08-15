#!/usr/bin/env python

print """ChooseBestRice CBR (
    .iClock(iClock), 
    .iEnable(cbr_enable), 
    .iReset(cbr_reset), """
for i in range(0, 15):
    print "    .iRE_BU_%d(BU_re_%d),"%(i,i)
print "    .oBest(best_rice_param)"
print "    );"

print
wires_string = """wire [15:0] MSB_re_%d, LSB_re_%d;
wire [16:0] BU_re_%d;"""
for i in range(0, 15):
    print wires_string%(i,i,i)

encoder_string = """
RiceEncoder #(.rice_param(%d))
    RE%d (
    .iClk(iClock),
    .iReset(rice_enc_reset),
    .iSample(best_sample),
    .oMSB(MSB_re_%d),
    .oLSB(LSB_re_%d),
    .oBitsUsed(BU_re_%d));
"""

for i in range(0, 15):
    print encoder_string%(i, i, i, i, i)

print "// THIS GOES IN S_WRITE_RES!!!"
for i in range(0, 15): 
    print "4'b%s: begin best_msb <= MSB_re_%d; best_lsb <= LSB_re_%d; end"%(bin(i)[2:].zfill(4), i, i)