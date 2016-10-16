#!/usr/bin/python


warmup_file = "warmup.txt"
model_file = "models.txt"

mout= open("wakeup/m.txt", "w")
modelout = open("wakeup/model.txt", "w")


fin = open(model_file)

s = fin.readline()
state = 0
count = 0
m_list = []
model_list = []

while s:
    m, model = [int(i) for i in s.strip().split()]
    if state == 0:
        count = m - 1
        state = 1
        print m
        m_list.append(m)
        print model
        model_list.append(model)
    elif state == 1:
        print model
        model_list.append(model)
        count -= 1
        if count == 0:
            state = 0
    s = fin.readline()

s = " ".join([str(i) for i in m_list])
mout.write(s)
mout.close()

s = "\n".join([str(i) for i in model_list])
modelout.write(s)
modelout.close()
