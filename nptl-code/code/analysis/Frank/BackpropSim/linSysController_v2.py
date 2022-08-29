#inputs: RNN start state, system start state, input sequence (target position), desired state sequence (target position)
#use batch input mode to session.run()
#have multiple trials (target switches) ?

#to add: noisy output and input, pixel-formatted input, delayed feedback, multiple targets, output trial data for MATLAB analysis

import tensorflow as tf
import numpy
import matplotlib.pyplot as plt
sess = tf.InteractiveSession()

nUnits = 50
nSysState = 4
nControl = 2
nSteps = 100
nInput = 2
dt = 0.05
delaySteps = 0

initial = tf.truncated_normal([nUnits, nUnits], stddev=0.1)
W = tf.Variable(initial)

initial = numpy.random.normal(0,0.1,[nControl, nUnits])
for i in range(nControl):
    initial[i,:] = initial[i,:] / numpy.linalg.norm(initial[i,:])
    initial[i,:] = initial[i,:] / numpy.sqrt(nUnits)
U = tf.Variable(initial, dtype=tf.float32, trainable=False)

initial = tf.truncated_normal([nUnits, nSysState], stddev=0.1)
I = tf.Variable(initial)

initial = tf.truncated_normal([nUnits, nInput], stddev=0.1)
Iseq = tf.Variable(initial)

initial = tf.truncated_normal([nUnits, 1], stddev=0.1)
biases = tf.Variable(initial)

A = tf.constant([[1, 0, dt, 0], [0, 1, 0, dt], [0, 0, 0.96, 0], [0, 0, 0, 0.96]])
B = tf.constant([[0, 0],[0, 0],[0.04, 0],[0, 0.04]])

startNetState = tf.placeholder(tf.float32, shape=[nUnits, 1])
startSysState = tf.placeholder(tf.float32, shape=[nSysState, 1])
inSeq = tf.placeholder(tf.float32, shape=[nInput, nSteps, 1])
targSeq = tf.placeholder(tf.float32, shape=[nInput, nSteps, 1])

#unfold RNN + linear system in time
netStates = [startNetState]
sysStates = [startSysState]
controlOut = []
for i in range(nSteps):
    feedbackStateIdx = i - delaySteps
    if feedbackStateIdx < 0:
        feedbackStateIdx = 0
        
    netStates.append(netStates[i]*0.60 + 0.40*tf.tanh(biases + tf.matmul(W, netStates[i]) + tf.matmul(Iseq, inSeq[:,i,:]) + tf.matmul(I, sysStates[feedbackStateIdx])))
    controlOut.append(tf.matmul(U, netStates[i]))
    sysStates.append(tf.matmul(A, sysStates[i]) + tf.matmul(B, controlOut[-1]))
    tf.add_to_collection('PosErr',tf.square(sysStates[-1][0:2]-targSeq[:,i,:]))

totalErr = tf.reduce_sum(tf.add_n(tf.get_collection('PosErr'), name='total_err'))

learnRate = tf.Variable(1.0, trainable=False)
tvars = tf.trainable_variables()
grads, _ = tf.clip_by_global_norm(tf.gradients(totalErr, tvars), 1)
optimizer = tf.train.GradientDescentOptimizer(learnRate)
train_op = optimizer.apply_gradients(zip(grads, tvars),
    global_step=tf.contrib.framework.get_or_create_global_step())
new_lr = tf.placeholder(tf.float32, shape=[], name="new_learning_rate")
lr_update = tf.assign(learnRate, new_lr)

sess.run(tf.global_variables_initializer())
initNet = numpy.zeros([nUnits, 1]) 
trainSteps = 5000

for i in range(trainSteps):
    #learn rate
    lr = 1 - i/trainSteps
    
    #random start state and target
    initSys = numpy.random.normal(0,1,[4,1])
    randTarg = numpy.random.normal(0,1,[2,1])
    randTargSeq = numpy.reshape(numpy.tile(randTarg, [1,nSteps]),[2,nSteps,1])
    
    #descend gradient
    ao, to, te = sess.run([lr_update, train_op, totalErr], feed_dict={new_lr: lr, startNetState: initNet, startSysState: initSys, inSeq: randTargSeq, targSeq: randTargSeq})

    if i%10 == 0:
        print("step %d, training accuracy %g"%(i, te))

#plot trajectory        
randTarg = numpy.random.normal(0,1,[2,1])
randTargSeq = numpy.reshape(numpy.tile(randTarg, [1,nSteps]),[2,nSteps,1])
    
sysTraj, controlTraj, netTraj = sess.run([sysStates, controlOut, netStates], feed_dict={new_lr: lr, startNetState: initNet, startSysState: initSys, inSeq: randTargSeq, targSeq: randTargSeq})
sysTraj = numpy.hstack(sysTraj)
controlTraj = numpy.hstack(controlTraj)
netTraj = numpy.hstack(netTraj)

plt.plot(sysTraj[0,:], sysTraj[1,:])
plt.plot(randTarg[0],randTarg[1], 'o')
plt.ylabel('some numbers')
plt.show()

plt.plot(sysTraj.transpose())
plt.show()

plt.plot(controlTraj.transpose())
plt.show()

plt.plot(netTraj.transpose())
plt.show()

fWriter = tf.summary.FileWriter('C:/Users/Frank/Documents/PythonScripts/linSys/tboard/', sess.graph)

