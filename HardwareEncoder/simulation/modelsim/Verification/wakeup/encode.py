#!/usr/bin/env python

orders = [int(i.strip()) for i in open('m.txt', 'r').readline().split()]
models = [int(i.strip()) for i in open('model.txt', 'r').readlines()]
data = [int(i.strip()) for i in open('../wakeup_pcm.txt', 'r').readlines()]
output = open('python_encoded.txt', 'w')
warmout = open('python_warmup.txt', 'w')

def filter(model, data):
    shift = 10
    order = len(model)
    model.reverse()
    residuals = range(4096 - order)
    warmup = data[0:order]
    for i in range(4096 - order):
        residuals[i] = 0
        
    #for(i = 0; i < data_len; i++) {
    #    sum = 0;
    #    for(j = 0; j < order; j++)
    #        sum += qlp_coeff[j] * data[i-j-1];
    #    residual[i] = data[i] - (sum >> lp_quantization);
        
    #order = 3;
    #i = 3;
    #data = [1,2,3,4,5,6,7,8]
    #residuals = [0,0,0,0,0,0]
    #model = [-2,1,3]
    
    #residuals[3 - 3](0) = data[3] - (-2*data[2] + data[1]*1 + 3*data[0])
    #j = 0
    #3 -0 -1 = 2
    #j = 1
    #3 - 1 - 1 = 1
    #j = 2
    #3 - 2 - 1 = 0
    
    for i in range(order, 4096):
        acc = 0
        for j in range(0, order):
            acc += model[j]*data[i - j - 1]
        residuals[i - order] = data[i] - (acc >> shift)
    return residuals, warmup
    
b = 0
res = 0
for o in orders:
    print "Order: ", o
    model = models[b:b + o]
    print "MODEL!!!", model
    print 
    b += o
    
    residuals, warmup = filter(model, data[res:res + 4096])
    warmout.write("\n".join([str(i) for i in warmup]))
    warmout.write("\n")
    
    res = res + 4096
    
    
    output.write("\n".join([str(i) for i in residuals]))
    output.write("\n")

## Problem #1. Warmups being written too few
## Problem #2. Too many residuals written

output.close()
warmout.close()