function params = createTrialParams(user,limits,gMap,new_paramtr)
numGap = 4;
elecMat = cell(1,user.numBlockRep);
for iter = 1:user.numBlockRep
    if numel(user.electrodeLabels) > user.numParam
        elecMat{iter} = randpermCond(numel(user.electrodeLabels),user.numParam,numGap);
    else
        elecMat{iter} = randperm(numel(user.electrodeLabels));
    end
end
user.elecNum = reshape(cell2mat(elecMat),[],1);
% assign parameters
electrodeID = arrayfun(@(x)user.electrodeID{x},user.elecNum,'un',0);
electrodeNumber = arrayfun(@(x)user.electrodeNumbers(x),user.elecNum,'un',0);
electrodeLabel = arrayfun(@(x)user.electrodeLabels{x},user.elecNum,'un',0);
stimFrequency = arrayfun(@(x)user.stimFrequencies(x),user.freqID,'un',0);
stimAmplitude = arrayfun(@(x)user.stimAmplitudes(x),user.amplID,'un',0);
stimPolarity = arrayfun(@(x)user.stimPolarities(x),user.polID,'un',0);
% stimPulse = arrayfun(@(x)user.stimPulses(x),pulsID,'un',0);
stimPulseWidth = arrayfun(@(x)user.stimPulseWidths(x),user.pwID,'un',0);
stimInterphase = arrayfun(@(x)user.stimInterphases(x),user.iphID,'un',0);
stimDuration = arrayfun(@(x)user.stimDurations(x),user.durID,'un',0);
stimPulse = num2cell(round(cell2mat(stimFrequency).*cell2mat(stimDuration)));

% set up catch trials
% add in enough extra trials to cover the desired number of catch trials
% Right now there are no catch trials -- if you need to include x% of catch
% trials, modify value of obj.user.numCatchTrials as x/100 in parameter
% file

numCatchTrials = ceil(user.numCatchTrials*length(user.elecNum));
numTrialsTotal = length(user.elecNum) + numCatchTrials;
catchID = Task.Common.addCatchTrials(user.whetherToBalance,numTrialsTotal,numCatchTrials,user.catchTrialSelectMode);
tmpElectrodeID = arrayfun(@(x)nan,1:numTrialsTotal,'un',0);
tmpElectrodeID(~catchID) = electrodeID;
tmpElectrodeNumber = arrayfun(@(x)nan,1:numTrialsTotal,'un',0);
tmpElectrodeNumber(~catchID) = electrodeNumber;
tmpElectrodeLabel = arrayfun(@(x)nan,1:numTrialsTotal,'un',0);
tmpElectrodeLabel(~catchID) = electrodeLabel;
tmpStimFrequency = arrayfun(@(x)nan,1:numTrialsTotal,'un',0);
tmpStimFrequency(~catchID) = stimFrequency;
tmpStimAmplitude = arrayfun(@(x)nan,1:numTrialsTotal,'un',0);
tmpStimAmplitude(~catchID) = stimAmplitude;
tmpStimPolarity = arrayfun(@(x)nan,1:numTrialsTotal,'un',0);
tmpStimPolarity(~catchID) = stimPolarity;
tmpStimPulse = arrayfun(@(x)nan,1:numTrialsTotal,'un',0);
tmpStimPulse(~catchID) = stimPulse;
tmpStimPulseWidth = arrayfun(@(x)nan,1:numTrialsTotal,'un',0);
tmpStimPulseWidth(~catchID) = stimPulseWidth;
tmpStimInterphase = arrayfun(@(x)nan,1:numTrialsTotal,'un',0);
tmpStimInterphase(~catchID) = stimInterphase;
tmpStimDuration = arrayfun(@(x)nan,1:numTrialsTotal,'un',0);
tmpStimDuration(~catchID) = stimDuration;
if strcmpi(env.get('type'),'PRODUCTION')
    sa = cellfun(@(x)calcSurfaceArea(gMap,x),tmpElectrodeLabel,'un',0);
    tmpChargeDensity = cellfun(@(x,y,z) x*y/((1000*1000)*z),tmpStimAmplitude,tmpStimPulseWidth,sa,'un',0);
else
    tmpChargeDensity = arrayfun(@(x)x,randi(limits(6),size(tmpStimDuration)),'un',0);
end
catchTrial = arrayfun(@(x)x,catchID,'un',0);

% checking for any framework that did not run its course 
flag_found = false;
lastFrameworkFile = env.get('lastFrameworkFile');

if ~isempty(lastFrameworkFile) && exist(lastFrameworkFile,'file')==2 
    tmp = load(lastFrameworkFile);
    old_paramtr = tmp.Task.params.parameterFcn(find(tmp.Task.params.parameterFcn == '_',1,'last')+1:end);
    if tmp.Task.nTrials<length(tmp.Task.TrialParams) && strcmp(old_paramtr,new_paramtr)
        resp = input('Enter "y" to start from Trial 1 or "n" to start from the terminated trial of previous task : ','s');
        if tmp.Task.nTrials ==0 || strcmpi(resp,'y') 
            params = tmp.Task.TrialParams(1:end);
        else
            params = tmp.Task.TrialParams(tmp.Task.nTrials:end);
        end
        flag_found = true;
    end
end

if ~flag_found
    % create array of structs (cell arrays args dealt across array)
    params = struct(...
        'electrodeNumber',tmpElectrodeNumber(:)',...
        'electrodeID',tmpElectrodeID(:)',...
        'electrodeLabel',tmpElectrodeLabel(:)',...
        'stimFrequency',tmpStimFrequency(:)',...
        'stimAmplitude',tmpStimAmplitude(:)',...
        'stimPolarity',tmpStimPolarity(:)',...
        'stimPulse',tmpStimPulse(:)',...
        'stimPulseWidth',tmpStimPulseWidth(:)',...
        'stimInterphase',tmpStimInterphase(:)',...
        'stimDuration',tmpStimDuration(:)',...
        'chargeDensity',tmpChargeDensity(:)',...
        'catch',catchTrial(:)');
end
params = validate(params,limits);
end

function permMatCond = randpermCond(numElec,numParam,elecGap)
permMat(1,:) = randperm(numElec);
firstIndices =1:elecGap;
lastIndices = numElec-elecGap+1:numElec;
for iter2 = 2:numParam
    temp = randperm(numElec);
    if all(temp == permMat(iter2-1,:))
        temp = randperm(numElec);
    end
    overlapOld = ismember(permMat(iter2-1,numElec-elecGap+1:numElec),temp(1:elecGap));
    overlapNew = ismember(temp(1:elecGap),permMat(iter2-1,numElec-elecGap+1:numElec));
    if any(overlapOld)
        oldPos = lastIndices(overlapOld);
        newPos = firstIndices(overlapNew);
        newPos2 = [];
        for numSwap = numel(newPos):-1:1
            if oldPos(numel(newPos)-numSwap+1)-numElec >0
                continue; %retain
            else
                newPos2 = [newPos2;newPos(numel(newPos)-numSwap+1)];
            end
            % pick them, shift rest of the array, add them to the end of the array
            shiftVars = temp(newPos2);
            shiftIdx = setdiff(1:numElec,newPos2);
            temp(1:numel(shiftIdx))= temp(shiftIdx);
            temp(numel(shiftIdx)+1:numElec)= shiftVars;
        end
    end
    permMat(iter2,:) = temp;
    permMatCond = reshape(permMat',[],1);
end
end

function params = validate(params,limits)
% VALIDATE Verify parameters are within allowed protocol limits
%
%   VALIDATE(THIS,CMD)
%   Checks that parameters initialized on stimulator are
%   within protocol limits.

stimamp = [params.stimAmplitude];
stimpw = [params.stimPulseWidth];
stimfreq = [params.stimFrequency];
stimdur = [params.stimDuration];

ip_logical = [params.stimInterphase] >= limits(1);
amp_logical = stimamp >= limits(2);
pw_logical = stimpw >= limits(3);
f_logical = stimfreq >= limits(4);
dur_logical = stimdur >= limits(5);
cd_logical = [params.chargeDensity] >= limits(6);
cpp = (stimamp/1000) .* stimpw / 1000;
cpp_allEl = cpp .* arrayfun(@(x)numel(x.electrodeNumber),params);
cpp_logical = cpp_allEl >= limits(7);
% calculate single electrode max injection rate
% Charge Rate = charge per phase * 2 phases * Freq * 10 sec
cr = 2 * cpp .* stimfreq .* stimdur;
cr_logical = cr >= limits(8)*1e3;
dlt_row = ip_logical | amp_logical | pw_logical | f_logical | dur_logical | cd_logical | cpp_logical | cr_logical;
params(dlt_row)= [];

end % END function validate

function surfaceArea = calcSurfaceArea(gridMap,elId)
% To calculate the surface area of the stimulating electrode
gridID = gridMap.ChannelInfo.GridID(strcmp(gridMap.ChannelInfo.Label,elId));
gMapSpecs = gridMap.GridInfo.Custom{gridMap.GridInfo.GridID == gridID};
surfaceArea = pi*str2double(gMapSpecs.ElectrodeDiameter)/10*str2double(gMapSpecs.ElectrodeWidth)/10;
end

