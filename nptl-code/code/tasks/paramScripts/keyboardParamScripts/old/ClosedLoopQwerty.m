setModelParam('pause', true)
setModelParam('holdTime', 1500)
setModelParam('clickRefractoryPeriod', 1000)
setModelParam('dwellRefractoryPeriod', 1000)

setModelParam('cursorDiameter', 20)
setModelParam('trialTimeout', 10000);
setModelParam('keyboardDims', uint16([240 90 1440 900]));
setModelParam('taskType', uint16(keyboardConstants.TASK_CUED_TEXT));
setModelParam('initialInput', uint16(cursorConstants.INPUT_TYPE_DECODE_V));
setModelParam('inputType', uint16(cursorConstants.INPUT_TYPE_DECODE_V));
setModelParam('showScores', true);
setModelParam('scoreTime', 3000);
setModelParam('recenterOnFail', false);
setModelParam('acquireMethods', uint8(keyboardConstants.ACQUIRE_DWELL));

%% trackpad position to position gain parameters
gain_x = 0.6;
gain_y = gain_x;
setModelParam('gain', [gain_x gain_y]);
setModelParam('mouseOffset', [0 0]);

%setModelParam('workspaceX', double([-960 960]));
%setModelParam('workspaceY', double([-540 540]));
setModelParam('workspaceX', double([-720 720]));
setModelParam('workspaceY', double([-450 450]));


%% neural decode
loadFilterParams;