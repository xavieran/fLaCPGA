#!/usr/bin/env python
import sys, struct

acf = [1.000000000000000,
      0.997981554947980,
         0.992251395488185,
            0.982903007882259,
               0.969960812307969,
                  0.953649933428738,
                     0.934179469609090,
                        0.911787499148218,
                           0.886758679617906,
                              0.859350831985190,
                                 0.829854642519605,
                                    0.798536241567618,
                                       0.765652854584048]

def float_to_hex(f):
    return hex(struct.unpack('<I', struct.pack('<f', f))[0])
#for i in acf:
#    print "acf = 32'h%s;\n#20;"%float_to_hex(i)

print float_to_hex(float(sys.argv[1]))
