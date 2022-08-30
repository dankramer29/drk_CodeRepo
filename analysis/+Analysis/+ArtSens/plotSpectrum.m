function [ha,specPower,normSpecPower] = plotSpectrum(ecog,params,varargin)
%{
        [HA,SPECPOWER,PVALS,STATS,NORMSPECPOWER] =
        PLOTSPECTRUM(ECOG,PARAMS,VARARGIN)

    Computes average power spectrum for ECoG data during real/natural touch
    events.

    1) PLOTSPECTRUM(ECOG):

    2) PLOTSPECTRUM(ECOG,PARAMS):

    3) PLOTSPECTRUM(...,PARAM1,PARAMVALUE1,...):

    4) [HA,SPECPOWER,NORMSPECPOWER] = PLOTSPECTRUM(...):

    %TODO:
    1) Finish documentation

Update:
09/27/2016: Update to check if data if from bipolar reference (MAS).
%}

% input error check
narginchk(1,8);
assert(isa(ecog,'ecogTask')||isa(ecog,'struct'),'First input should be ecogTask object or structure, not %s',class(ecog));

% check if params structure was provided
if nargin == 1 || isempty (params)
    params = struct;
    params.Fs = ecog.eventFs;   % in Hz
    params.fpass = [0 200];     % [minFreqz maxFreq] in Hz
    params.tapers = [5 9];
    params.pad = 0;
    params.err = [1 0.05];
    params.trialave = 1; % average across trials
    params.win = [0.05 0.15];   % size and step size for windowing continuous data
end

% Default values
specWin = [1 1]; % in seconds or corresponding units to agree with frequency units.
normalize = false;
baseline = 'ITI';   % for normalization/standarization
method = 'z-score'; % method to normalize/standarize

% Optional inputs
idx = find(strcmpi(varargin,'specWin'),1);
if ~isempty(idx); specWin = varargin{idx+1}; end
idx = find(strcmpi(varargin,'normalize'),1);
if ~isempty(idx); normalize = varargin{idx+1}; end
idx = find(strcmpi(varargin,'baseline'),1);
if ~isempty(idx); baseline = varargin{idx+1}; end
idx = find(strcmpi(varargin,'method'),1);
if ~isempty(idx); method = varargin{idx+1}; end

if length(specWin(:)) == 1;  specWin = repmat(specWin(:),1,2); end % First value for stimulus window, and second for ITI

% Filter for 60 Hz and 120 Hz (harmonics) noise
bsFilt1 = designfilt('bandstopiir','FilterOrder',2, ...
    'HalfPowerFrequency1',59,'HalfPowerFrequency2',61, ...
    'SampleRate',ecog.eventFs,'DesignMethod','butter');

bsFilt2 = designfilt('bandstopiir','FilterOrder',2,...
    'HalfPowerFrequency1',119,'HalfPowerFrequency2',121,...
    'SampleRate',ecog.eventFs,'DesignMethod','butter');

% check if bipolar reference was done
if ecog.bipolar; chans = ecog.elecPairs;
else chans = ecog.readChan(:);
end

% loop through the event types, channels, and trials
specPower = struct;
normSpecPower = struct;
ha = zeros(length(ecog.evtNames),size(chans,1));
lims = [-80 0]; ylbl = 'Power gain (dB)';

% if normalized specified, check where the baseline should be pulled from
% and pool the data acros the entire session
if normalize
    if strcmpi(baseline,'ITI') % can use the inter-trial interval (default)
        baseline_data = ecog.iti;
    else
        idx = find(strcmp(ecog.evtNames,baseline),1);
        baseline_data = ecog.trialdata(idx);
        ecog.evtNames(idx) = [];
        ecog.trialdata(idx) = [];
        baseline_data = repmat(baseline_data,1,length(ecog.evtNames));
    end
    paramsbase = params;
    paramsbase.trialave = 0;
    base = nan(specWin(2)*ecog.eventFs,sum(cellfun(@length,baseline_data)),size(chans,1));
    c = 1; lims = [-5 10]; ylbl = 'Normalized power';
    for ff = 1:length(ecog.evtNames)
        for tt = 1:length(baseline_data{ff})
            if ecog.bipolar
                temp = baseline_data{ff}(tt).voltage;
            else
                temp = baseline_data{ff}(tt).voltage - repmat(nanmean(baseline_data{ff}(tt).voltage,1),size(baseline_data{ff}(tt).voltage,1),1);
            end
            temp = filtfilt(bsFilt1,temp); % filter raw data
            temp = filtfilt(bsFilt2,temp);
            if size(temp,1) <= specWin(2)*ecog.eventFs
                idx1 = 1; idx2 = size(temp,1);
            else
                idx1 = 1;
                idx2 = specWin(2)*ecog.eventFs;
            end
            base(1:length(idx1:idx2),c,:) = temp(idx1:idx2,:);
            c = c + 1;
        end
    end
end

for ff = 1:length(ecog.evtNames)
    for kk = 1:size(chans,1)
        data = zeros(specWin(1)*ecog.eventFs,length(ecog.trialdata{ff}));
        for tt = 1:length(ecog.trialdata{ff})
            idx1 = 1; % Get indices from beginning of trial
            idx2 = specWin(1)*ecog.eventFs; % up to the specified duration in specWin
            temp = ecog.trialdata{ff}(tt).voltage - repmat(nanmean(ecog.trialdata{ff}(tt).voltage,1),size(ecog.trialdata{ff}(tt).voltage,1),1); % Get data and remove DC offset
            temp = filtfilt(bsFilt1,temp); % filter raw data
            temp = filtfilt(bsFilt2,temp);
            data(:,tt) = temp(idx1:idx2,kk);
        end
        [S,f,Serr] = mtspectrumc(data,params);
        if size(chans,2) > 1; var = ['chan',num2str(chans(kk,1)),'_',num2str(chans(kk,2))];
        else var = ['chan',num2str(chans(kk))];
        end
        specPower(ff).(var) = S;
        if normalize
            temp = squeeze(base(:,:,kk));
            temp = filtfilt(bsFilt1,temp); % filter raw data
            temp = filtfilt(bsFilt2,temp);
            Sbase = mtspectrumc(temp,paramsbase);
            [a,b] = ECoG.getNormValues(Sbase,method);
            S = (S-a)./b; Serr = (Serr - repmat(a',size(Serr,1),1))./repmat(b',size(Serr,1),1);
            powdb = S; errdb = Serr';
            normSpecPower(ff).(var) = S;
        else
            powdb = 10*log10(S); % power to decibels with reference of one
            errdb = 10*log10(Serr');
        end
        
        figure(ff); set(gcf,'Position',[300 250 1100 600]);
        ha(ff,kk) = subplot(1,size(chans,1),kk);
        shadedErrorBar(f,powdb,errdb,0,1,'color',[0. 0.5 1]);
        box off; legend(var);
        if kk == round(size(chans,1)/2)
            xlabel('Frequency (Hz)','fontsize',13);
            title(ecog.evtNames{ff},'fontsize',14)
        end
        if kk == 1; ylabel(ylbl); end
        ylim(lims); xlim(params.fpass);
    end
end

end % END PlotSpectrum function