function [obj,spec] = plotSpecgramHeatmap(ecog, blc, params, varargin)
%{
        OBJ = PLOTSPECGRAMHEATMAP(ECOG,PARAMS,VARARGIN)
    Computes and plot the HeatMaps of continuous spectrograms from ECoG
    voltage values. In generates a Heatmap per event and read channels.
    NOTE: Needs CHRONUX toolbox installed.

    1) PLOTSPECGRAMHEATMAPT(ECOG): ECOG is an ecogTask object or structure
    (from ecogTask, st = ecogTask.toStruct;) which has the raw and trial
    parsed voltage, frame and timestamps data per channel, for each event
    type. Event types are indicated in ECOG.EVTNAMES, and channels read in
    ECOG.READCHAN. It calls Chronux function MTSPECGRAMC, and MATLAB's
    built-in HEATMAP object.

    2) PLOTSPECGRAMHEATMAP(ECOG,PARAMS): specifies PARAMS struct,
    following format for CHRONUX toolbox.

    3)
    PLOTSPECGRAMHEATMAP(...,PARAMS1,PARAMSVALUE1,PARAMS2,PARAMSVALUE2,...):
    Optional parameters-values pairs to specify whether power should be
    normalized ('NORMALIZE', default = false), specify windowing size for
    spectrogram ('SPECWIN', default = 1.0 seconds), and baseline for
    normalization ('BASELINE', default = 'ITI'). Units for SPECWIN should
    be adjusted to units of sampling frequency (e.g. in freq in Hz, give
    window in seconds).

    4) OBJ = PLOTSPECGRAMHEATMAP(...): returns cell array with N-by-M
    HeatMap object handles, where N is the total number of 
    event types, specified in ECOG.EVENTNAMES, and M the total of channels, 
    specified in ECOG.CHANNELSREAD.

    See also MTSPECGRAMC.M, HEATMAP.M, CHRONUX.M

Updates:
09/27/2016: Slight modificiation to check if data are from bipolar reference
or regular one (default regular). If data are bipolar, signals do not need
to be detrended. (MAS)
%}

% check for input errors NOT NECESSARY IN THIS
%narginchk(1,10); 
%assert(isa(ecog,'ecogTask')||isa(ecog,'struct'),'Wrong data data for first input, must be ecogTask object or structure, not %',class(ecog));

% Default and optional values
[varargin,specWin] = util.argkeyval('specWin',varargin,[1 1]); % in seconds if all frequencies are in Hz. First value for stimulus window and second for ITI
[varargin,normalize] = util.argkeyval('normalize',varargin, true); %CURRENTLY SET TO NORMALIZE
%Baselin: options are ITI, SplitITI, or some other baseline, set up to not matter
%what you write.  ITI is all ITI among all trials, splitITI is just the iti
%for that type of touch (e.g. iti for only deep touch)
[varargin,baseline] = util.argkeyval('baseline',varargin,'ITI'); 
[varargin,method] = util.argkeyval('method',varargin, 'z-score');
[varargin,ch] = util.argkeyval('ch',varargin,[1 blc.ChannelInfo(end).ChannelNumber]);




if nargin == 1 || isempty(params) % no parameter structure provided
    params = struct;
    params.fpass = [0 200];     % [minFreqz maxFreq] in Hz
    params.tapers = [5 9];
    params.pad = 0;
    params.err = [1 0.05];
    params.trialave = 0;
    params.win = [0.5 0.005];   % size and step size for windowing continuous data
    params.Fs=blc.SamplingRate; %in Hz
    params.bipolar=false; %BIPOLAR HAS NOT BEEN FIXED, DOESN'T WORK AT ALL.
    
end

%find the channels desired
if params.bipolar
    warning('THIS HAS NOT BEEN SET UP, GOOD LUCK!');
else
    ch=(ch(1):ch(2));
end

% check specWin is 1-by-2
if length(specWin(:)) == 1; specWin = repmat(specWin(:),1,2); end

% to save the plots
if params.bipolar; sufdir = 'BIPOLAR-REF'; else sufdir = 'REF'; end
savedir = fullfile(env.get('results'),'ECoG',mfilename);
if exist(savedir,'dir') == 0; mkdir(fullfile(env.get('results'),'ECoG'),mfilename); end
if exist(fullfile(savedir,sufdir),'dir') == 0; mkdir(savedir,sufdir); end
savedir = fullfile(savedir,sufdir);
evts = {'cotton','light','deep'};
sufname = '';

% if normalized specified, check where the baseline should be pulled from
%creates the data from ITI to be used for normalization
if normalize
    sufname = ['norm',baseline];
    if strcmpi(baseline,'ITI') || strcmpi(baseline, 'splitITI') % can use the inter-trial interval (default)
        baseline_data = ecog.iti; %ecog is the output of artsens_proc
    else %set up if your norm isn't the ITI THIS IS THE PLACE TO CREATE A NORMALIZATION OF JUST BEFORE THE TRIAL
        idx = find(strcmp(ecog.evtNames,baseline),1);
        baseline_data = ecog.trialdata(idx);
        ecog.evtNames(idx) = [];
        ecog.trialdata(idx) = [];
        baseline_data = repmat(baseline_data,1,length(ecog.evtNames));
    end
    % will pool the data from all trials across all events (get the ITI during all the session)
    if params.bipolar
        base = nan(specWin(2)*params.Fs,sum(cellfun(@length,baseline_data)),size(ecog.elecPairs,1)); % 3D matrix time-by-trials-by-channelPairs
    else
        base = nan(specWin(2)*params.Fs,sum(cellfun(@length,baseline_data)),length(ch)); % 3D matrix time-by-trials-by-channels
        base_split=cell(length(ecog.evtNames));
    end
    c = 1;
    paramsbase = params;
    paramsbase.trialave = 1;
    if specWin(1) > specWin(2); paramsbase.pad = paramsbase.pad + 1; end
    for ff = 1:length(ecog.evtNames) %ff is the touch type
        for tt = 1:length(baseline_data{ff}) %tt is each trial
            if params.bipolar
                temp = baseline_data{ff}(tt).voltage;
            else %d/c offset if not bipolar, subtract the mean
                temp = baseline_data{ff}(tt).voltage - repmat(mean(baseline_data{ff}(tt).voltage),size(baseline_data{ff}(tt).voltage,1),1);
            end
            if size(temp,1) <= specWin(2)*params.Fs
                idx1 = 1; idx2 = size(temp,1);
            else
                idx1 = 1; idx2 = specWin(2)*params.Fs;
            end
            %creates dataxtrialxchs_desired, filled in one column (trial) at a
            %time, but for all channels desired, temp has all channels.
            if strcmpi(baseline, 'splitITI');
                 %to do just iti for that trial as your baseline
                base_split{ff}(idx1:idx2,c,:)=temp(idx1:idx2, ch(1):ch(2));
            else         
                base(idx1:idx2,c,:) = temp(idx1:idx2, ch(1):ch(2));
            end
            c = c + 1;
        end
    end
end

% loop through the event types
obj = cell(length(ecog.evtNames),length(ch));
spec = struct;

for ff = 1:length(ecog.evtNames)
    if params.bipolar
        specPower = cell(1,size(ecog.elecPairs,1));
    else
        specPower = cell(1,length(ch));
    end
    for kk = 1:length(specPower) %number of channels
        for tt = 1:length(ecog.trialdata{ff}) %trials
            if params.bipolar
                data = ecog.trialdata{ff}(tt).voltage;
            else %take the dc offset off
                data = ecog.trialdata{ff}(tt).voltage - repmat(mean(ecog.trialdata{ff}(tt).voltage),size(ecog.trialdata{ff}(tt).voltage,1),1);
            end
            %EITHER SOMETHING IS WRONG HERE, WHERE IT'S AVERAGING ACROSS
            %TRIALS, OR IT'S FINE BUT IT ENDS UP BEING THE SAME AS WHAT'S
            %NOW IN FREQBANDPOWER
            idx1 = 1;% Select data from beginning of trial
            idx2 = specWin(1)*params.Fs;% to specified duration in specWin
            [S,tspec,f] = mtspecgramc(data(idx1:idx2,:),params.win,params);
            specPower{kk} = cat(3,specPower{kk},S(:,:,kk)); %add the trials on to the third dimension, so it's timexfreqxtrial
        end
        if normalize % use the pooled voltage values to calculate baseline spectrogram
            if strcmpi(baseline, 'splitITI');
                temp=squeeze(base_split{ff}(:,:,kk));
            else
                temp=squeeze(base(:,:,kk)); %take the iti for one channel.
            end
            Sbase = mtspecgramc(temp,paramsbase.win,paramsbase);
            %getting norm values of mean and std from the ITI, through
            %Sbase (via temp which is the iti)
            %a is the mean, b is the std, of timexfreq taken across all
            %trials, the repmat so that they are the size to be applied
            %mathematically to repmat
            [a,b] = ArtSens.getNormValues(Sbase,method,size(specPower{kk},2),size(specPower{kk},3),1); % get numerator and denominator
            specPower{kk} = (specPower{kk} - a)./b; % standarize values, z score, by taking the iti mean/std off the trial data
            powdb = nanmean(specPower{kk},3)';
        else
            powdb = 10*log10(nanmean(specPower{kk},3)'); % change to dB using reference of one.
        end
        tplot = linspace(tspec(1)-params.win(1)/2,tspec(end)+params.win(1)/2,length(tspec));
        tplot = ArtSens.makeColumnLabels(tplot);
        fplot = ArtSens.makeColumnLabels(f,0:15:params.fpass(2),'frequency');
        obj{ff,kk} = HeatMap(powdb,'RowLabels',fplot,'ColumnLabels',tplot,'Symmetric',false,'Colormap','hot','ColumnLabelsRotate',0);
        if params.bipolar
            addTitle(obj{ff,kk},[ecog.evtNames{ff},' chan. ',num2str(ecog.elecPairs(kk,1)),'-',num2str(ecog.elecPairs(kk,2))]);
            chans = [num2str(ecog.elecPairs(kk,1)),'-',num2str(ecog.elecPairs(kk,2))];
        else
            addTitle(obj{ff,kk},[ecog.evtNames{ff},' channel ',num2str(ch(kk))]);
            chans = num2str(ch(kk));
        end
        addXLabel(obj{ff,kk},'Time (ms)','Fontsize',13);
        addYLabel(obj{ff,kk},'Frequency (Hz)','Fontsize',13);
        name = ['chan',chans,'_',evts{ff},'_',sufname];
        %obj{ff,kk}.plot; %this plots it again, not clear why it's
        %necessary
        %Common.plotsave(fullfile(savedir,name));
        %close(gcf);
    end
    spec(ff).power = specPower;
    spec(ff).norm = normalize;
end

end % END of plotSpecgramHeatmap