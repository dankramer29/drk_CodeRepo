function Parameters(obj)
% This parameter set balances cue types first, then response types
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

% define numbers first
obj.user.numbers = 6:9;

% control number of trials (one entry for each balance-condition option)
obj.user.balance = 'cue'; % 'response' 'number' 'cue'
obj.user.numTrialsPerBalanceCondition = 10; % number of trials for each balance condition

% cue
% obj.user.cue_types{1} = {'sound','mandarin'};
% obj.user.cue_args{1} = {};
% obj.user.cue_types{2} = {'character','mandarin'};
% obj.user.cue_args{2} = {};
obj.user.cue_types{1} = {'shape','ovalframe'};
obj.user.cue_args{1} = {};

% response
obj.user.rsp_types{1} = {'language','english'};
obj.user.rsp_args{1} = {};

% miscellaneous settings
obj.user.fontSize = 160; % font size of the operation string
obj.user.fontFamily = 'Courier'; % font of the operation string
obj.user.fontColor = 150*[0.5 0.5 0.5]; % color of the operation string

% load default settings
Task.NumberLanguage.DefaultSettings(obj);