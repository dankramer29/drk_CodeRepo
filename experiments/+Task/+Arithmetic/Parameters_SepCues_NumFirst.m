function Parameters_SepCues_NumFirst(obj)
% This parameter set evaluates response speed for answers to mathematical
% operators set in quadrants of the screen.
%
% Type in the number spoken by the subject for normal trials, then press
% "Enter" to record the response. 
%
% For catch trials, type in "c", then press "Enter".
%
% If the subject does not know the answer, type in "x" and press "Enter".

% define numbers first
obj.user.operators = {@plus,@minus,@times,@rdivide}; % operators to test
obj.user.numbers = 0:9; % numbers to use in operations
obj.user.answers = 0:9; % how big the answers can be
obj.user.cuemodality = {'symbol','audio'}; % cue modalities 'symbol','text','audio'
obj.user.cuestyle = 'separate'; % cue presentation style
obj.user.nummodality = {'char'}; % number modalities
obj.user.numposition = {'left','right'}; % number positions
obj.user.opposition = 'center'; % operator position
obj.user.catch = {'none','num1','num2','op'}; % catch trials

% control number of trials (one entry for each balance-condition option)
obj.user.balance = {'cuemodality'}'; % 'response', 'answer'
obj.user.numTrialsPerBalanceCondition = 20; % number of trials for each balance condition
obj.user.numCatchTrials = [8 4 4 4];
obj.user.catchTrialSelectMode = 'percomb';

% phases
obj.phaseDefinitions{1} = {@Task.Common.PhaseITI,...
    'Name','ITI',...
    'durationTimeout',2.0};
obj.phaseDefinitions{2} = {@Task.Arithmetic.PhaseCueNumbers,...
    'Name','CueNumbers',...
    'durationTimeout',1.0};
obj.phaseDefinitions{3} = {@Task.Common.PhaseDelay,...
    'Name','Delay1',...
    'drawFixationPoint',false,...
    'durationTimeout',2.0};
obj.phaseDefinitions{4} = {@Task.Arithmetic.PhaseCueOperator,...
    'Name','CueOperator',...
    'durationTimeout',1.0};
obj.phaseDefinitions{5} = {@Task.Common.PhaseDelay,...
    'Name','Delay2',...
    'drawFixationPoint',false,...
    'durationTimeout',2.0};
obj.phaseDefinitions{6} = {@Task.Arithmetic.PhaseRespond,...
    'Name','Respond',...
    'durationTimeout',1000.0};

% load default settings
Task.Arithmetic.DefaultSettings_Common(obj);