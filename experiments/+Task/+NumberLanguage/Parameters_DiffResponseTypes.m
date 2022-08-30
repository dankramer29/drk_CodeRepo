function Parameters_DiffResponseTypes(obj)
% This parameter set uses a single cue type but multiple response types.
%
% To see a list of cue types, run 
%
%   >> list = Task.NumberLanguage.getCueData.
%
% To see a list of subtypes for a particular cue type, run
%
%   >> list = Task.NumberLanguage.getCueData(TYPE)
%
% Likewise for response types and subtypes:
%
%   >> list = Task.NumberLanguage.getResponseData
%   >> list = Task.NumberLanguage.getResponseData(TYPE)

% which numbers to exercise
obj.user.numbers = 1:4;

% control number of trials (one entry for each balance-condition option)
obj.user.balance = 'response'; % 'response' 'number' 'cue'
obj.user.numTrialsPerBalanceCondition = 8; % number of trials for each balance condition

% cue
obj.user.cue_types{1} = {'shape','square'};
obj.user.cue_args{1} = {'green'};

% response
obj.user.rsp_types{1} = {'language','english'};
obj.user.rsp_args{1} = {};
obj.user.rsp_types{2} = {'language','spanish'};
obj.user.rsp_args{2} = {};

% miscellaneous settings
obj.user.fontSize = 160; % font size of the operation string
obj.user.fontFamily = 'Courier'; % font of the operation string
obj.user.fontColor = 150*[0.5 0.5 0.5]; % color of the operation string

% load default settings
Task.NumberLanguage.DefaultSettings(obj);