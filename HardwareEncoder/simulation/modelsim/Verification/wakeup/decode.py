#!/usr/bin/env python

orders = [int(i.strip()) for i in open('m.txt').readline().split()]
models = [int(i.strip()) for i in open('model.txt').readlines()]
warmups = [int(i.strip()) for i in open('warmup.txt').readlines()]
residuals = [int(i.strip()) for i in open('residuals.txt').readlines()]
#warmups = [int(i.strip()) for i in open('python_warmup.txt').readlines()]
#residuals = [int(i.strip()) for i in open('python_encoded.txt').readlines()]
output = open('data.txt', "w")
audio_modelled = open('audio_modelled.txt', 'w')

def filter(model, warmup, residuals):
    shift = 10
    order = len(model)
    model.reverse()
    modelled = range(4096)
    data = range(4096)
    for i in range(4096):
        data[i] = 0
    for i in range(order):
        data[i] = warmup[i]
    print warmup
    print data[0:order + 1]
    #   for(i = 0; i < data_len; i++) {
    #    sum = 0;
    #    for(j = 0; j < order; j++)
    #        sum += qlp_coeff[j] * data[i-j-1];
    #    data[i] = residual[i] + (sum >> lp_quantization);
    
    acc = 0
    for i in range(order, 4096):
        for j in range(0, order):
            acc += model[j]*data[i - j - 1]
        data[i] = (acc >> shift) + residuals[i - order]
        modelled[i] = acc >> shift
        acc = 0
    return data, modelled
    
b = 0
res = 0
for o in orders:
    print "Order: ", o
    warmup = warmups[b:b + o]
    print "WARMUP!!!", warmup
    model = models[b:b + o]
    print "MODEL!!!", model
    print 
    b += o
    
    data,modelled = filter(model, warmup, residuals[res:res + (4096 - o)])
    
    res = res + (4096 - o)
    output.write("\n".join([str(i) for i in data]))
    output.write("\n")

    audio_modelled.write("\n".join([str(i) for i in modelled]))
    audio_modelled.write("\n")
    
output.close()
    
    
