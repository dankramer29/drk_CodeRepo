setModelParam('pause', true)
setModelParam('targetDiameter', 75)
setModelParam('holdTime', 500)
setModelParam('cursorDiameter', 45)
setModelParam('trialTimeout', 10000);
setModelParam('numTrials', 120);
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 0);
setModelParam('expRandMu', 0); %% this is the trial delay length parameter
setModelParam('expRandMin', 500);
setModelParam('expRandMax', 1500);
setModelParam('expRandBinSize', 100);
setModelParam('failurePenalty', 0);
setModelParam('taskType', uint32(cursorConstants.TASK_CENTER_OUT));
setModelParam('showScores', true);

setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_DECODE_V));
setModelParam('recenterOnFail', true);
setModelParam('recenterOnSuccess', false);
setModelParam('recenterDelay',500);
setModelParam('pxOffset',0);
setModelParam('pyOffset',0);
setModelParam('vxOffset',0);
setModelParam('vyOffset',0);

%% trackpad position to position gain parameters
gain_x = 0.6;
gain_y = 0.6;
setModelParam('gain', [gain_x gain_y]);
setModelParam('mouseOffset', [0 0]);

numTargetsInt = uint16(8);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = int16(zeros([2, double(cursorConstants.MAX_TARGETS)]));
targetIndsMat(:,1:numTargetsInt)  = [0 316 484 316 0 -316 -484 -316; 409 316 0 -316 -409 -316 0 316];

setModelParam('workspaceY', double([-540 540]));
setModelParam('workspaceX', double([-960 960]));

setModelParam('targetInds', int16(targetIndsMat));

%% neural decode
loadFilterParams;
ngain_x = 1.1;
ngain_y = 1.1;
setModelParam('neuralGain', [ngain_x ngain_y]);
