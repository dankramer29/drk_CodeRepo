import hessianfree as hf
import scipy.io
import matplotlib.pyplot as plt
import numpy as np

#Input & Targets generated by MATLAB
dataDir = 'C:/Users/Frank/Documents/Big Data/frwSimulation/BCI Modeling Results/networkSim'

#Create feedforward net that can reproduce simple fTarg feedback control policy 
ffData = scipy.io.loadmat(dataDir + '/ffData')
inputs = ffData['inputs']
targets = ffData['targets']

inputsVal = inputs[0:2000,:]
targetsVal = targets[0:2000,:]
inputsTrain = inputs[2001:,:]
targetsTrain = targets[2001:,:]

ff = hf.FFNet([128, 30, 30, 2], layers=[hf.nl.Linear(), hf.nl.Logistic(), hf.nl.Logistic(),
                                     hf.nl.Linear()], loss_type=hf.loss_funcs.SquaredError())
ff.run_epochs(inputsTrain, targetsTrain,
                optimizer=hf.opt.HessianFree(CG_iter=200),
                max_epochs=100, plotting=True, test=(inputsVal, targetsVal))
outputs = ff.forward(inputs)

a = {}
a['l1']=outputs[1]
a['l2']=outputs[2]
a['l3']=outputs[3]
a['inputs']=inputs
a['targets']=targets

scipy.io.savemat('C:/Users/Frank/Documents/Big Data/frwSimulation/BCI Modeling Results/networkSim/ffNetResults',a)

plt.figure()
plt.plot(targets[:, 1],color='b')
plt.plot(outputs[3][:, 1],color='r')
plt.show()

#Create RNN that can generate avg control vector time series from "go" signal
rnnData = scipy.io.loadmat(dataDir + '/rnnData')
inputs = rnnData['inputs'].astype(np.float32)
targets = rnnData['targets'].astype(np.float32)

inputsVal = inputs[0:19,:,:]
targetsVal = targets[0:19,:,:]
inputsTrain = inputs[20:,:,:]
targetsTrain = targets[20:,:,:]

rnn = hf.RNNet([3, 50, 2], layers=[hf.nl.Linear(), hf.nl.Logistic(), hf.nl.Linear()])
rnn.run_epochs(inputsTrain, targetsTrain,
                optimizer=hf.opt.HessianFree(CG_iter=100),
                max_epochs=300, plotting=True, test=(inputsVal, targetsVal))
outputs = rnn.forward(inputs)

a = {}
a['l1']=outputs[1]
a['l2']=outputs[2]
a['inputs']=inputs
a['targets']=targets

scipy.io.savemat('C:/Users/Frank/Documents/Big Data/frwSimulation/BCI Modeling Results/networkSim/rnnResults',a)

tmp = outputs[-1]
plt.figure()
plt.plot(targets[160, :, 1],color='b')
plt.plot(tmp[160, :, 1],color='r')
plt.show()

#Create FB RNN that can incoprorate visual feedback but is also recurrent
rnnData = scipy.io.loadmat(dataDir + '/rnnData_fb')
inputs = rnnData['inputs'].astype(np.float32)
targets = rnnData['targets'].astype(np.float32)

inputsVal = inputs[0:19,:,:]
targetsVal = targets[0:19,:,:]
inputsTrain = inputs[20:,:,:]
targetsTrain = targets[20:,:,:]

rnn = hf.RNNet([2, 50, 2], layers=[hf.nl.Linear(), hf.nl.Logistic(), hf.nl.Linear()])
rnn.run_epochs(inputsTrain, targetsTrain,
                optimizer=hf.opt.HessianFree(CG_iter=100),
                max_epochs=300, plotting=True, test=(inputsVal, targetsVal))
outputs = rnn.forward(inputs)

a = {}
a['l1']=outputs[1]
a['l2']=outputs[2]
a['inputs']=inputs
a['targets']=targets

scipy.io.savemat('C:/Users/Frank/Documents/Big Data/frwSimulation/BCI Modeling Results/networkSim/rnnResults_fb',a)

tmp = outputs[-1]
plt.figure()
plt.plot(targets[160, :, 1],color='b')
plt.plot(tmp[160, :, 1],color='r')
plt.show()
