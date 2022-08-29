#hyperparameters to search:
#dropout, L2 weight regularization
#learning rate schedule
#number of units
#magnitude of weight initialization
#smoothing on input features
#number of time-steps per series

#objects of specific inquiry:
#number of factors on input layer, pre-solved input layer restricted to subsets of 4-component model
#training over multiple datasets & subjects; variable input layer, input layer + context key, retrain whole model
#stacking multiple recurrent layers
#vanilla vs. GRU vs. LSTM

#compare to:
#linear velocity decoder with exponential smoothing & fixed delay
#VKF with fixed delay
#Weiner filter velocity decoder
#Magnitude decoder

#need to add:
#dataset stitching, with different weights and context key for each dataset
#support for different RNN cell types and stacking
#mask of time steps to include in error computation
#dynamic unrolling: use dynamic_rnn with a custom cell, or lower-level while_loop / scan?
#test static vs. dynamic performance

#each dataset can be saved as .mat
#input from command line is a list of datasets, hyperparameters, and folders


import scipy.io
import matplotlib.pyplot as plt
import numpy as np
import tensorflow as tf
import argparse
from customRnnCells import ContextGRUCell, ContextRNNCell, ContextLSTMCell, initializeWeights, makelambda

#parse inputs
parser = argparse.ArgumentParser(description='RNN decoder with multi-dataset training')
parser.add_argument('--datasets', metavar='datasets', type=str, nargs='+',
                    help='a list of dataset numbers to include in training')
parser.add_argument('--datasetDir', metavar='datasetDir', type=str, nargs=1,
                    help='dataset directory')
parser.add_argument('--outputDir', metavar='outputDir', type=str, nargs=1,
                    help='output directory')

hyperParams = [['rnnType', str],
               ['nLayers', int],
               ['nDecFactors', int],
               ['L2Reg', float],
               ['learnRateStart',float],
               ['nSteps',int],
               ['initWeightScale',float],
               ['useInputProj',bool],
               ['nDecUnits',int]]
for i in range(len(hyperParams)):
    parser.add_argument('--'+hyperParams[i][0], metavar=hyperParams[i][0], type=hyperParams[i][1], nargs=1)

args = parser.parse_args(['--datasets','t5.2016.09.28','t8.2015.11.19','t9.2016.08.11','t10.2016.08.24','--datasetDir','/Users/frankwillett/Data/Derived/rnnDecoding/rawFeatures/Fold1',
                          '--outputDir','/Users/frankwillett/Data/Derived/gruTestOut','--rnnType','RNN',
                          '--nLayers','1','--nDecFactors','10','--L2Reg','10','--learnRateStart','0.01','--nSteps','20000',
                          '--initWeightScale','1.0','--nDecUnits','50','--useInputProj','True'])

#Input & Targets generated by MATLAB
dataDir = '/Users/frankwillett/Data/Derived/gruTest'
inputs = []
targets = []
inputsVal = []
targetsVal = []
inputsFinal = []
targetsFinal = []

for datasetName in args.datasets:
    rnnData = scipy.io.loadmat(args.datasetDir[0] + '/' + datasetName + '.mat')
    inputs.append(rnnData['inputs'].astype(np.float32))
    targets.append(rnnData['targets'].astype(np.float32))
    inputsVal.append(rnnData['inputsVal'].astype(np.float32))
    targetsVal.append(rnnData['targetsVal'].astype(np.float32))
    inputsFinal.append(rnnData['inputsFinal'].astype(np.float32))
    targetsFinal.append(rnnData['targetsFinal'].astype(np.float32))

nDatasets = len(inputs)
nInputs = inputs[0].shape[2]
nSteps = inputs[0].shape[1]
nTargets = targets[0].shape[2]
batchSize = 32
useInputProj = True
rnnType = 'GRU'

if rnnType=='LSTM':
    rnnCell = ContextLSTMCell
elif rnnType=='GRU':
    rnnCell = ContextGRUCell
elif rnnType=='RNN':
    rnnCell = ContextRNNCell
    
#Start tensorflow
sess = tf.Session()

#these placeholders must be configured for each new batch
batchInputs = tf.placeholder(tf.float32, shape=[batchSize, nSteps, nInputs])
batchTargets = tf.placeholder(tf.float32, shape=[batchSize, nSteps, nTargets])
startDecState = tf.placeholder(tf.float32, shape=[args.nDecUnits[0], batchSize])
errorMask = tf.placeholder(tf.float32, shape=[batchSize, nSteps])
datasetIdx = tf.placeholder(tf.int32, shape=[])

#instantiate a decoder GRU network
#reset_bias = 1.0, update_bias = -1.0
decLayers = []
for i in range(args.nLayers[0]):
    if i==0:
        nLayerInputs = args.nDecFactors[0]
    else:
        nLayerInputs = args.nDecUnits[0]
         
    newLayer = rnnCell(args.nDecUnits[0], nLayerInputs, 'RNN_layer'+str(i), datasetIdx, numContexts=nDatasets, reset_bias=1.0, update_bias=-1.0, weight_scale=1.0,
                   clip_value=np.inf)
    decLayers.append(newLayer)

if args.useInputProj[0]:
    projW = []
    projB = []
    for i in range(nDatasets):
        with tf.variable_scope('ProjLayer'):
            projW.append(tf.get_variable("W_"+str(i), dtype=tf.float32, 
                    initializer=initializeWeights([nInputs, args.nDecFactors[0] ], 1.0), trainable=True))
            projB.append(tf.get_variable("b_"+str(i), [1, args.nDecFactors[0]], dtype=tf.float32, 
                    initializer=tf.zeros_initializer, trainable=True))
        
    #project dynamically
    predW = []
    predB = []
    for i in range(nDatasets):   
        predW.append((tf.equal(datasetIdx, tf.constant(i)), makelambda(projW[i])))
        predB.append((tf.equal(datasetIdx, tf.constant(i)), makelambda(projB[i])))
    activeProjW = tf.case(predW, default=makelambda(projW[0]))    
    activeProjB = tf.case(predB, default=makelambda(projB[0]))    
    
    projectedInput = tf.matmul(batchInputs, tf.tile(tf.expand_dims(activeProjW,0),[batchSize, 1, 1])) + activeProjB
else:
    projectedInput = batchInputs
      
#unfold RNN in time
if args.nLayers[0]==1:
    cellToUse = decLayers[0]
else:
    cellToUse = tf.nn.rnn_cell.MultiRNNCell(decLayers)
    
decStates, lastState = tf.nn.dynamic_rnn(
    cell = cellToUse,
    dtype = tf.float32,
    inputs = projectedInput,
)
        
#readout the target
W_o = tf.get_variable("W_o", dtype=tf.float32, 
                initializer=initializeWeights([args.nDecUnits[0], nTargets ], 1.0), trainable=True)
b_o = tf.get_variable("b_o", [1, nTargets], dtype=tf.float32, 
                initializer=tf.zeros_initializer, trainable=True)
decOutput = tf.matmul(decStates, tf.tile(tf.expand_dims(W_o,0),[batchSize, 1, 1])) + b_o

#error function
err = tf.multiply(tf.reduce_sum(tf.square(batchTargets - decOutput),2), errorMask)
totalErr = tf.sqrt(tf.reduce_mean(err))

trainErrSummary = tf.summary.scalar('train_RMSE', totalErr)
testErrSummary = tf.summary.scalar('test_RMSE', totalErr)

#add l2 cost
l2vars = []
if useInputProj:
    l2vars.append(activeProjW)
l2vars.append(W_o)  
for i in range(nLayers):
    l2vars.extend(decLayers[i]._weightVariables)
  
l2cost = tf.constant(0.0)
total_params = 0
for i in range(len(l2vars)):
  shape = l2vars[i].get_shape().as_list()
  total_params += np.prod(shape)
  l2cost += tf.nn.l2_loss(l2vars[i])
l2cost = l2cost / total_params
l2cost = l2cost * 10
l2costSummary = tf.summary.scalar('l2cost', l2cost)

#total cost
totalCost = l2cost + totalErr

#prepare gradients and optimizer
tvars = tf.get_collection(tf.GraphKeys.TRAINABLE_VARIABLES)
learnRate = tf.Variable(1.0, trainable=False)

grads = tf.gradients(totalCost, tvars)
grads, grad_global_norm = tf.clip_by_global_norm(grads, 200)
opt = tf.train.AdamOptimizer(learnRate, beta1=0.9, beta2=0.999,
                             epsilon=1e-01)
train_op = opt.apply_gradients(
    zip(grads, tvars), global_step=tf.contrib.framework.get_or_create_global_step())
    
new_lr = tf.placeholder(tf.float32, shape=[], name="new_learning_rate")
lr_update = tf.assign(learnRate, new_lr)

#prepare tensorboard
writer = tf.summary.FileWriter("/Users/frankwillett/Data/Derived/gruTest")

#prepare to save the model
saver = tf.train.Saver()
lve = np.inf

#How many parameters does this model have?
total_params = 0
for i in range(len(tvars)):
  shape = tvars[i].get_shape().as_list()
  nParams = np.prod(shape)
  print(tvars[i].name + ': ' + str(nParams))
  total_params += nParams
print("Total model parameters: ", total_params)

sess.run(tf.global_variables_initializer())

#train RNN one batch at a time
nBatches = 2000
prevStartStates = np.zeros([nDecUnits, batchSize])
eMask = np.concatenate((np.zeros([batchSize, 100]), np.ones([batchSize, nSteps-100])), 1)

for i in range(nBatches):
    #learn rate
    lr = 0.01*(1 - i/float(nBatches))
    
    #prepare to insert inputs and targets from randomly selected trials
    trlIdx = np.random.choice(nTrials, batchSize)
    
    #random start state and target
    inputSeq = inputs[trlIdx,:,:]
    targSeq = targets[trlIdx,:,:]
    
    #descend gradient
    ao, to, te, trainSummary, l2Summ = sess.run([lr_update, train_op, totalErr, trainErrSummary, l2costSummary], 
                                        feed_dict={new_lr: lr, startDecState: prevStartStates, batchInputs: inputSeq, 
                                                   batchTargets: targSeq, datasetIdx: 0, errorMask: eMask})

    #log progress
    writer.add_summary(trainSummary, i)
    writer.add_summary(l2Summ, i)
    
    #track validation accuracy on a random validation batch
    valIdx = np.random.choice(nValTrials, batchSize)
    inputSeq = inputsVal[valIdx,:,:]
    targSeq = targetsVal[valIdx,:,:]
    te, testSummary = sess.run([totalErr, testErrSummary], feed_dict={new_lr: lr, startDecState: prevStartStates, batchInputs: inputSeq, batchTargets: targSeq, 
                               datasetIdx: 0, errorMask: eMask})
    writer.add_summary(testSummary, i)
    
    #save whenever validation error is at its lowest point so far
    if te < lve:
        lve = te
        saver.save(sess, '/Users/frankwillett/Data/Derived/gruTest/model.ckpt', global_step=i, write_meta_graph=False)
    
    #validation plot every once in a while
    if i%100 == 0:
        print("step %d"%(i))
        
        inputSeq = inputsVal[range(batchSize),:,:]
        targSeq = targetsVal[range(batchSize),:,:]
        do, inf = sess.run([decOutput, projectedInput], feed_dict={new_lr: lr, startDecState: prevStartStates, batchInputs: inputSeq, batchTargets: targSeq,
                               datasetIdx: 0, errorMask: eMask})
        do = np.stack(do)
        inf = np.stack(inf)
        
        plt.figure()
        for x in range(3):
            plt.subplot(3,2,x*2+1)
            plt.plot(targetsVal[x,:,0])
            plt.plot(do[x,:,0])
            
            plt.subplot(3,2,x*2+2)
            plt.plot(targetsVal[x,:,1])
            plt.plot(do[x,:,1])
        plt.show()

#load the best performing variables
ckpt = tf.train.get_checkpoint_state('/Users/frankwillett/Data/Derived/gruTest/')
saver.restore(sess, ckpt.model_checkpoint_path)

#apply to inputsFinal and return
finalIdx = np.array(range(batchSize))
outputs = []
inFac = []
zList = []
rList = []
dsList = []
while True:
    finalIdx = finalIdx[finalIdx<inputsFinal.shape[0]]
    if len(finalIdx)==0:
        break
    if len(finalIdx)<batchSize:
        finalIdx = np.concatenate((finalIdx, np.zeros([batchSize-len(finalIdx)])+finalIdx[-1])).astype(np.int32)
    inputSeq = np.transpose(inputsFinal[finalIdx,:,:], (2,1,0))
    targSeq = np.transpose(targetsFinal[finalIdx,:,:], (2,1,0))

    do, infc, ds, zg, rg = sess.run([decOutputs, inputFactors, decStates, zGates, rGates], feed_dict={new_lr: lr, startDecState: prevStartStates, batchInputs: inputSeq, batchTargets: targSeq})
    outputs.append(np.stack(do))
    inFac.append(np.stack(infc))
    dsList.append(np.stack(ds))
    zList.append(np.stack(zg))
    rList.append(np.stack(rg))
    finalIdx = finalIdx+batchSize

inputSeq = np.transpose(inputsFinal[range(batchSize),:,:], (2,1,0))
targSeq = np.transpose(targetsFinal[range(batchSize),:,:], (2,1,0))
do = sess.run(decOutputs, feed_dict={new_lr: lr, startDecState: prevStartStates, batchInputs: inputSeq, batchTargets: targSeq})
do = np.stack(do)

plt.figure()
for x in range(3):
    plt.subplot(3,2,x*2+1)
    plt.plot(targetsFinal[x,:,0])
    plt.plot(do[:,0,x])
    
    plt.subplot(3,2,x*2+2)
    plt.plot(targetsFinal[x,:,1])
    plt.plot(do[:,1,x])
plt.show()

outputsFinal = np.concatenate(outputs,2)
outputsFinal = outputsFinal[:,:,range(inputsFinal.shape[0])]
outputsFinal = np.transpose(outputsFinal, [2, 0, 1])

inFacFinal = np.concatenate(inFac,2)
inFacFinal = inFacFinal[:,:,range(inputsFinal.shape[0])]
inFacFinal = np.transpose(inFacFinal, [2, 0, 1])

dsFinal = np.concatenate(dsList,2)
dsFinal = dsFinal[:,:,range(inputsFinal.shape[0])]
dsFinal = np.transpose(dsFinal, [2, 0, 1])

zFinal = np.concatenate(zList,2)
zFinal = zFinal[:,:,range(inputsFinal.shape[0])]
zFinal = np.transpose(zFinal, [2, 0, 1])

rFinal = np.concatenate(rList,2)
rFinal = rFinal[:,:,range(inputsFinal.shape[0])]
rFinal = np.transpose(rFinal, [2, 0, 1])
                
a = {}
a['targetsFinal']=targetsFinal
a['outputsFinal']=outputsFinal
a['inFacFinal']=inFacFinal
a['dsFinal']=dsFinal
a['zFinal']=zFinal
a['rFinal']=rFinal
scipy.io.savemat('/Users/frankwillett/Data/Derived/gruTest/gruResults',a)