setModelParam('pause', true);
setModelParam('targetDiameter', 100);
setModelParam('holdTime', 500);
setModelParam('cursorDiameter', 45);
setModelParam('trialTimeout', 10000);
setModelParam('numTrials', 96);
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 0);
setModelParam('expRandMu', 0); %% this is the trial delay length parameter
setModelParam('expRandMin', 500);
setModelParam('expRandMax', 1500);
setModelParam('expRandBinSize', 100);
setModelParam('failurePenalty', 0);
setModelParam('taskType', uint32(cursorConstants.TASK_CENTER_OUT));
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_DECODE_V));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_NONE));
setModelParam('showScores', false);
setModelParam('trialsPerScore', uint16(48));
setModelParam('recenterOnFail', true);
setModelParam('recenterOnSuccess', false);

setModelParam('maxTaskTime',1000*60*4);

%% click-related parameters
setModelParam('clickPercentage', 1);
setModelParam('clickHoldTime', uint16(30));
setModelParam('clickSource', uint16(clickConstants.CLICK_TYPE_NEURAL));
setModelParam('stopOnClick', false);
setModelParam('stopOffTarget', false);
setModelParam('hmmClickSpeedMax', 0.35);

% enable error assist
setModelParam('errorAssistR', 0.2);
setModelParam('errorAssistTheta', 0.05);


%% trackpad position to position gain parameters
%gain_x = 1.5;
%gain_y = gain_x;
%setModelParam('gain', [gain_x gain_y]);
%setModelParam('mouseOffset', [0 0]);

numTargetsInt = uint16(8);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = int16(zeros([2, double(cursorConstants.MAX_TARGETS)]));
targetIndsMat(:,1:numTargetsInt)  = [0 316 484 316 0 -316 -484 -316; 409 316 0 -316 -409 -316 0 316];

setModelParam('workspaceY', double([-539 539]));
setModelParam('workspaceX', double([-960 960]));


setModelParam('targetInds', int16(targetIndsMat));

%% neural decode
loadFilterParams;
%% neural click
loadDiscreteFilterParams;

%% update HMM threshold
updateHMMThreshold(0.9, 1); % open loop training params, prompt for block for recalc of likelihoods

startContinuousMeansTracking(true, true);
%startDiscreteMeansTracking(false, false);

thirtySecondPause();
unpauseExpt


