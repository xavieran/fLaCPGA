#!/usr/bin/env python
import sys
l = int(sys.argv[1])
m = int(sys.argv[2])
k = int(sys.argv[3])

uval = (m << k) | l

if (uval & 1):
    print -(((m << k) | l) >> 1) - 1
else:
    print ((m << k) | l) >> 1
