function [trialdata,iti,numTrials,trialEnd] = parse_Trials(this, blc, varargin)
% parseTrials- an application of michelle's function to make an iti to work with the freqbandPower
% Breaks the trials up into the components within each phase, i.e. the data and the iti

%get the specWin which is the window you are taking for each trial
[varargin, prepost]=util.argkeyval('prepost',varargin, [1 1]); %prepost(1) is the time prior to the touch and prepost(2) is the time after the touch
[varargin, Fs]=util.argkeyval('Fs',varargin, 2000);
[varargin, recordingday] = util.argkeyval('recordingday',varargin,1);
[varargin, dt] = util.argkeyval('dt',varargin, blc.OriginTime);
[varargin, peritime] = util.argkeyval('peritime', varargin, [1 1]); %for the trial starts and the trial ends, get peritime(1) before and peritime(2) after in seconds (converted below) 



%this has both voltage and the data, vt is the problem one other than
%rawvt which is now in this.rawvt

trialdata = cell(1,length(this.evtData));
trialEnd =  cell(1,length(this.evtData));
iti = cell(size(trialdata));
numTrials=[];

peritime=peritime*Fs; %convert peritime

for kk = 1:length(this.evtData) %kk is the different trials
    trialSt = struct; itiSt = struct; trialE=struct;
    
    % get indices of trial start and finishing
    trStart = find(strcmp(this.evtData{kk},'XX')); %will get the rows for the time stamps of all the starts XX and stops ZZ
    trEnd = find(strcmp(this.evtData{kk},'ZZ'));
    
    % check all "starts" have an "end"
    if length(trStart) ~= length(trEnd)
        a = trStart - trStart(1);
        b = trEnd - trStart(1);
        if length(trStart) > length(trEnd)
            c = [];
            for nn = 1:length(a)-1
                if ~any(b > a(nn) & b < a(nn+1))
                    c = [c,nn];
                end
            end
            trStart(c) = [];
        end
    end
    prev = 1;
    %Correct for the two ways the timestamps are made so you don't cut off
    %2 seconds.  Standard from Natus is 2 spaces
    if size(this.evtTimeStamp{kk}{trStart(1)},2)==14 || size(this.evtTimeStamp{kk}{trStart(1)},2)==12
        endspot=12;
    else
        warning('the timestamps in the _Events file need to either have 2 spaces after them or no spaces')
        endspot=12;
    end
    
    for nn = 1:length(trStart) % loop through the touches XX/ZZ
        %convert time stamps to rows
        [idx1]=Analysis.ArtSens.dt_diff(this.evtTimeStamp{kk}{trStart(nn)}(1:endspot), dt, Fs, 'recordingday', recordingday); %idx is now the row, the endspot has to do with spaces after the numbers
        [idx2]=Analysis.ArtSens.dt_diff(this.evtTimeStamp{kk}{trEnd(nn)}(1:endspot), dt, Fs, 'recordingday', recordingday);
        if isempty(idx1) && nn == 1; idx1 = 1; end % case where voltage data started with original "X" marker and not "XX" from video
        idxst=idx1; idxend=idx2; %save the xx and zzs
        if idx1==idx2
            idx2=idx1+sf; %add a second if the times end up being the same
            warning('the start and the end are the same time, consider checking the original file');
        end
        
        % get "in-between" times for ITI
        if nn > 1
            idx = round(prev:idx1-1); %gets from start to the first XX
            itiSt(nn-1).voltage = this.rawVt{kk}(idx,:); %ITI
        end
        prev = idx2+1+round(Fs*.3); %add 300ms to the ITI to make it not immediately after the offset of touch
        if ~isempty(idx1) && ~isempty(idx2)
            %if a trial is shorter than the desired amount, add a little
            %into the iti.  This will get fixed with your prepost so that
            %the data you care about is displayed and the extra won't
            %affect the analysis (meaning take 2s but only care about 1.5)
            td=idx2-idx1; %idx1 is at time 0 of touch onset right now
            if td<prepost(2)*Fs
                idx2=idx2+prepost(2)*Fs-td; %adds into the iti for that trials
                trlngth=td/Fs;
                disp(sprintf('trial isnt %d seconds long for trial %s trial %d, it is %d long', prepost(2), this.evtNames{kk},  nn, trlngth))
            end
            idxst=idx1;
            idxend=idx2;
            idx1=idx1-prepost(1)*Fs; %start the trial times prepost(1) before time 0
            if idx1<1 %make sure it doesn't start before the trial
                idx1=1;
            end
            if idx2>size(this.rawVt{kk},1)
                idx2=size(this.rawVt{kk},1);                
            end
            if idxend+peritime(2)>size(this.rawVt{kk},1)
                idxend=size(this.rawVt{kk},1)-peritime(2);                
            end
            trialSt(nn).voltage = this.rawVt{kk}(round(idx1:idx2),:); %Trial
            %% get the peri peri ends of trials, so around xx and zz  
            trialE(nn).end = this.rawVt{kk}(round((idxend-peritime(1):idxend+peritime(2))),:);
        end
    end
    trialEnd{kk}=trialE;
    trialdata{kk} = trialSt;
    iti{kk} = itiSt;
    numTrials(kk)=length(trStart);
end

end % END of parseTrials function