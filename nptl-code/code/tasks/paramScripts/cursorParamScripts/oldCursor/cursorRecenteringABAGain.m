setModelParam('pause', true)
setModelParam('targetDiameter', 150)

% hold time (aka dwell time)
setModelParam('holdTime', 500)

setModelParam('cursorDiameter', 50)
setModelParam('trialTimeout', 5000);
setModelParam('numTrials', 120);
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 0);
setModelParam('expRandMu', 0); %% this is the trial delay length parameter
setModelParam('expRandMin', 500);
setModelParam('expRandMax', 1500);
setModelParam('expRandBinSize', 100);
setModelParam('failurePenalty', 0);
setModelParam('taskType', uint32(cursorConstants.TASK_CENTER_OUT));
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_DECODE_V));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_DECODE_V));
setModelParam('showScores', true);
setModelParam('trialsPerScore', uint16(32));

setModelParam('recenterOnFail', true);
setModelParam('recenterOnSuccess', false);
setModelParam('recenterDelay',0);
setModelParam('pxOffset',0);
setModelParam('pyOffset',0);
setModelParam('vxOffset',0);
setModelParam('vyOffset',0);

%% trackpad position to position gain parameters
gain_x = 0.6;
gain_y = gain_x;
setModelParam('gain', [gain_x gain_y]);
setModelParam('mouseOffset', [0 0]);


% Change this number to push targets in (smaller) /out (larger)
targetDistanceScale = 3;

 targetIndsMat = int16(zeros([2, double(cursorConstants.MAX_TARGETS)]));

 % Eight target task (uncomment lines below)
 numTargetsInt = uint16(8);
 targetIndsMat(:,1:numTargetsInt)  = targetDistanceScale*double([0    71   100  71   0     -71  -100 -71;
                                               100  71   0    -71  -100  -71  0    71]);

% Four target task (uncomment lines below)
%targetIndsMat = int16(zeros([2, double(cursorConstants.MAX_TARGETS)]));
%targetIndsMat(:,1:numTargetsInt)  = targetDistanceScale*double([0    100  0    -100;
                                              %100  0    -100  0 ]);

setModelParam('numTargets', numTargetsInt);
setModelParam('targetInds', int16(targetIndsMat));

wspX = double([-720 720]);
wspY = double([-540 540]);
setModelParam('workspaceY', wspY);
setModelParam('workspaceX', wspX);


%% neural decode
loadFilterParams;
ngain_x = 1.007;
ngain_y = 1.007;
setModelParam('neuralGain', [ngain_x ngain_y]);
