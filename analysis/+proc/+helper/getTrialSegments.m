function [tr_data,tr_time] = getTrialSegments(data,time,task,varargin)
[varargin,bufferpre] = util.argkeyval('bufferpre',varargin,0);
[varargin,bufferpost] = util.argkeyval('bufferpost',varargin,0);
[varargin,absolute_time] = util.argflag('absolute_time',varargin,false);
[varargin,dim] = util.argkeyval('dim',varargin,find(size(data)==length(time),1,'first'));
assert(dim<=ndims(data),'dim input must be less than or equal to number of dimensions in the data');
util.argempty(varargin);

% divide into trials
trtime = task.trialTimes;
trst = trtime(:,1)-bufferpre;
trlen = min(trtime(:,2))+bufferpre+bufferpost;
tr_data = cell(1,task.numTrials);
tr_time = cell(1,task.numTrials);
for kk=1:task.numTrials
    idx = time>=trst(kk) & time<=(trst(kk)+trlen);
    tr_time{kk} = time(idx);
    
    % relative timing
    if ~absolute_time
        tr_time{kk} = tr_time{kk} - tr_time{kk}(1) - bufferpre + time(1);
    end
    
    % subselect
    if ndims(data)==2 %#ok<ISMAT>
        if dim==1
            tr_data{kk} = data(idx,:);
        elseif dim==2
            tr_data{kk} = data(:,idx);
        end
    elseif ndims(data)==3
        if dim==1
            tr_data{kk} = data(idx,:,:);
        elseif dim==2
            tr_data{kk} = data(:,idx,:);
        elseif dim==3
            tr_data{kk} = data(:,:,idx);
        end
    elseif ndims(data)==4
        if dim==1
            tr_data{kk} = data(idx,:,:,:);
        elseif dim==2
            tr_data{kk} = data(:,idx,:,:);
        elseif dim==3
            tr_data{kk} = data(:,:,idx,:);
        elseif dim==4
            tr_data{kk} = data(:,:,:,idx);
        end
    else
        error('no support for %d dimensions of data',ndims(data));
    end
end
num_samples = min(cellfun(@(x)size(x,1),tr_data));
tr_data = cellfun(@(x)x(1:num_samples,:,:),tr_data,'UniformOutput',false);
tr_data = cat(ndims(data)+1,tr_data{:});
tr_time = cellfun(@(x)x(1:num_samples),tr_time,'UniformOutput',false);
tr_time = nanmean(cat(1,tr_time{:}));