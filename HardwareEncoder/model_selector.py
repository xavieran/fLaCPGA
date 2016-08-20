#!/usr/bin/env python

# If m is even we have an odd number of things...

for m in range(1, 13):
    for n in range(1, m):
        print "a_%d,%d = a_%d,%d + k_%d*a_%d,%d"%(m + 1,n + 1, m-1+ 1, n+ 1, m+ 1, m-1 + 1, m-n + 1)
    print "\n"

