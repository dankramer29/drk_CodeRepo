function params = createTrialParams(user)

% values calculated to assist in balancing trials
numTrials = user.numTrialsPerBalanceCondition;

% distribute cue types, response types, and numbers
% at the moment the only thing that causes any difference is the 'all',
% which will generate a lot of trials; number, cue and response all result
% in the same output.
dsp = repmat(user.numberDisplay(:)',numTrials,1);
grp = repmat(user.numberGroup(:)',numTrials,1);
dsp = dsp(:)';
grp = grp(:)';
switch lower(user.balance)
    case 'all'
    case 'display'
        idx = randperm(length(grp),length(dsp));
        grp = grp(idx);
    case 'group'
        idx = randperm(length(dsp),length(grp));
        dsp = dsp(idx);
    otherwise
        error('Unknown balance option ''%s''',user.balance);
end
[dsp,grp] = ndgrid(dsp,grp);
numberDisplay = dsp(:)';
numberGroup = grp(:)';
numTrialsTotal = length(numberDisplay);
catchTrials = zeros(1,numTrialsTotal);

% add catch trials
if user.catchTrialFraction>0
    numCatch = round(user.catchTrialFraction*numTrialsTotal);
    tmpCatch = ones(1,numCatch);
    dsp_idx = randi(length(user.numberDisplay),[1 numCatch]);
    tmpDisplay = user.numberDisplay(dsp_idx);
    grp_idx = randi(length(user.numberGroup),[1 numCatch]);
    tmpGroup = user.numberGroup(grp_idx);
    
    catchTrials = [catchTrials tmpCatch];
    numberDisplay = [numberDisplay tmpDisplay];
    numberGroup = [numberGroup tmpGroup];
    
    numTrialsTotal = numTrialsTotal + numCatch;
end

% randomize trials
randIdx = randperm(numTrialsTotal);
catchTrials = catchTrials(randIdx);
numberDisplay = numberDisplay(randIdx);
numberGroup = numberGroup(randIdx);

% calculate correct response and catch numbers
responses = cell(1,numTrialsTotal);
catchNum = cell(1,numTrialsTotal);
for kk=1:numTrialsTotal
    if numberDisplay(kk)==numberGroup(kk) && ~catchTrials(kk)
        responses{kk} = 'yes';
    else
        responses{kk} = 'no';
    end
    catchNum{kk} = user.numberDisplay(randi(length(user.numberDisplay),[1 numberGroup(kk)]));
end

% add in position/size/color
[position,sz,color] = Task.NumberGroups.getCharacterPositionSizeColor(user,numberGroup);
catchTrials = arrayfun(@(x)x,catchTrials,'UniformOutput',false);

% create array of structs (cell arrays args dealt across array)
params = struct(...
    'numberDisplay',arrayfun(@(x)x,numberDisplay,'UniformOutput',false),...
    'numberGroup',arrayfun(@(x)x,numberGroup,'UniformOutput',false),...
    'catchNum',catchNum,...
    'catch',catchTrials,...
    'response',responses,...
    'position',position,...
    'size',sz,...
    'color',color);