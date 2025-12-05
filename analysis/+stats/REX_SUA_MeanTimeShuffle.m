
% This script will calculate your trial-averaged FRs in a window around
% some tiempoint of interest (StartTimes), from spike times (SpkTimes).

% It also generates a random-derived mean FR baseline distribution by
% calculating FRs at (ntrial) random times, and averaging them, repeating
% this (nboot [e.g. 10000]) times to create a histogram.

% Does some plotting for fun too at the end as an example of how to use the
% ouptuts.

% The way that firing rates are calculated goes as follows:
% 1. Calculate fractional interval firing rates at 1 ms resolution. Fractional interval FRs are basically 1/(the length of the interspike interval that your timepoint is in)
% 2. Calculate FR at any arbitrary time by convolving the fractional interval ms rates with a Gaussian kernel centered at your time of interest

% I don't claim this code to be optimized or fast. Check with a low "nboot"
% first. It relies on some helper functions I wrote a while ago that have
% maximum flexibility - they could probably be modified to be faster.
% Actually I just put in a faster version of the Gaussian code here.

%% Setting parameters
step = 0.01; % The time resolution of your mean firing rate trace (10 ms)
tbefore = 0.25;
tafter = 1; % Setting this up so that we are calculating FRs in a window starting tbefore image onset and ending tafter. tbefore and tafter should be multiples of step
wintimes = ((tbefore-(step/2)):step:(tafter+(step/2)))'; % Times to get FRs, relative to image onset. Shifted so that we have a timepoint right at tbefore, 0 and tafter
npt = length(wintimes);
nboot = 10000; % Number of baseline mean firing rates to calculate
gkern = 0.05; % Width of the Gaussian kernel for calculating firing rates (50 ms)
nstd = 4; % number of standard deviations to calculate the Gaussian kernel out to in each direction
mspad = gkern*nstd + step; % amount to pad time around each start time to ensure FR calculations go right.
alpha = 0.01; % Alpha value for significance testing against random baseline
rng(0); % Set the random seed for repeatability

% Number of units. Requires SpkTimes - a cell array of spike times for each
% unit
nneu = size(SpkTimes,1);

% Number of trials - requires StartTimes, a vector of image onset times
ntrial = length(StartTimes); 

% Figure out the gaussian kernel ahead of time. This assumes gaussian
% kernel will be centered on one of the 1 ms rate times
kernpoints = normpdf((-gkern*nstd):0.001:(gkern*nstd), 0, gkern)';
kernpoints = kernpoints/sum(kernpoints);

%% Setting the baseline window
blstarttime = XX; % First possible time for baseline calculation (maybe first fixation cross start?)
blendtime = XX; % Last possible time for baseline calculation (maybe last fixation cross start?)
% You can also make blstarttime and blendtime any time region - perhaps the
% time when the patient was resting before starting the trial, or only
% times when fixation crosses were showing... whatever you want. Based on
% your question.

%% Get actual FRs. [time x trials x neurons] matrix
rates = nan(npt, ntrial, nneu);

parfor triali = 1:ntrial
    % Define 1 ms resolution bins larger than the window of interest
    msedge = (StartTimes(triali)-tbefore-mspad-0.0005):0.001:(StartTimes(triali)+tafter+mspad+0.0005);
    % Define ms resolution FR times as centers of these bins
    mstimes = msedge(1:end-1)+0.0005;
    
    % Find the times relative to image onset to calculate FRs
    thist = StartTimes(triali)+wintimes;

    % Find the indices of mstimes that correspond to the entries in thist
    msi = nan(npt,1);
    for pti = 1:npt
        [minval,msi(pti)] = min(abs(mstimes-thist(pti)));
        if minval > 0.0005
            error(['Detected too large time offset: ' num2str(minval)]);
        end
    end

    for neui = 1:nneu
        msrates = Spikes2FIR_Arbitrary( SpkTimes{neui}, msedge)';
        rates(:, triali, neui) = KernelSmooth_Aligned(msrates, msi, kernpoints);
    end
end

%% Now get random baseline rates

% Create 1 ms bins across the recording for fractional interval FR
% calculation. This is for the boot draws
blmsedge = ((blstarttime-mspad):0.001:(blendtime+mspad))';
% Define ms FR times as centers of ms bins
blmstime = blmsedge(1:end-1)+0.0005;
% Pick ntrials*nboot times aligned on ms points that are well enough away
% from the start and end edges of blmstime
halfwin = (length(kernpoints)-1)/2;
iboot = randi(length(blmstime)-2*halfwin, ntrial*nboot) + halfwin;

bootrates = nan(nboot, ntrial, nneu);

parfor neui = 1:nneu
    blmsrates = Spikes2FIR_Arbitrary( SpkTimes{neui}, blmsedge)';
    bootrates(:, neui) = KernelSmooth_Aligned(blmsrates, iboot, kernpoints);
end

%% Probably want to save everything at this point so you don't have to recalculate to do plotting, etc!

%% Example significance testing using ALL trials! To do a subset of trials just change tri2do

tri2do = 1:ntrial;

% Mean and std dev firing rates
mFRs = squeeze(mean(rates(:,tri2do,:),2));
sFRs = squeeze(std(rates(:,tri2do,:),0,2));

% 1 Std Dev error shading
errup = mFRs + sFRs;
errdown = mFRs - sFRs;

mBL = squeeze(mean(bootrates(:,1:length(tri2do),:),2));
mmBL = squeeze(median(mBL,1));
highBL = squeeze(prctile(mBL, (1-(alpha/2))*100, 1));
lowBL = squeeze(prctile(mBL, (alpha/2)*100, 1));

% Significance testing
highpoints = nan(npt,nneu);
lowpoints = nan(npt,nneu);
for neui = 1:nneu
    for pti = 1:npt
        highpoints(pti,neui) = sum(mBL(:,neui) > mFRs(pti,neui)) < (nboot*alpha/2);
        lowpoints(pti,neui) = sum(mBL(:,neui) < mFRs(pti,neui)) < (nboot*alpha/2);
    end
end
anysigpoints = highpoints | lowpoints;

% Now plots. Sorry it's going to make a figure for each unit.
for neui = 1:nneu
    figure;
    hold on;
    % Plot error shading
    patch([wintimes; flipud(wintimes)], [errup(:,neui), errdown(:,neui)], 'k', 'FaceAlpha', 0.25);
    yl = get(gcf, ylim);
    % Plot image start time
    plot([0 0], yl, '-y');
    % Plot FR
    plot(wintimes, mFRs(:,neui), '-k', 'LineWidth', 2);
    % Plot BL median, upper and lower pctiles
    plot([wintimmes(0) wintimes(end)], mmBL(neui)*ones(1,2), '-b');
    plot([wintimmes(0) wintimes(end)], highBL(neui)*ones(1,2), '-b');
    plot([wintimmes(0) wintimes(end)], lowBL(neui)*ones(1,2), '-b');
    for pti = 1:npt
        if highpoints(pti,neui)
            plot(wintimes(pti), yl(2), '.r');
        elseif lowpoints(pti,neui)
            plot(wintimes(pti), yl(2), '.c');
        end
    end
end

%% Helper Functions

%% Do fractional interval firing rates, with arbitrary bin sizes and
% allowing multiple spikes inside any bin size. Assumes all bins are
% the same size. Rex Tien Jan 2020

function firates = Spikes2FIR_Arbitrary( spiketimes, binedges)

% eliminate unnecessary spikes

addfrontspike = [];
addbackspike = [];
firstspikei = find(spiketimes < binedges(1),1,'last');
if isempty(firstspikei)
    firstspikei = 1;
    addfrontspike = -Inf;
end
lastspikei = find(spiketimes > binedges(end),1,'first');
if isempty(lastspikei)
    lastspikei = length(spiketimes);
    addbackspike = Inf;
end

if (size(spiketimes(firstspikei:lastspikei),1) > size(spiketimes(firstspikei:lastspikei),2))
    stimes = [addfrontspike; spiketimes(firstspikei:lastspikei); addbackspike];
else
    stimes = [addfrontspike spiketimes(firstspikei:lastspikei) addbackspike];
end

binsize = binedges(2)-binedges(1);

nbin = length(binedges)-1;
intervals = diff(stimes);
nint = length(intervals);
lastinti = 1;

firates = nan(1,nbin);
if isempty(stimes)
    firates = zeros(1,nbin);
else
    for i = 1:nbin
        
        % For each bin, identify which intervals belong to it. First ID which
        % spikes belong to it
        spikesin = (stimes >= binedges(i)) & (stimes < binedges(i+1));
        intsin = spikesin(2:end);
        
        % carry over the last interval from the previous bin (this keeps the
        % first and last interval propagating if there are no more spikes
        intsin(lastinti) = 1;
        
        % also, the next interval is in play if you counted any spikes! But not if you're at the end
        if lastinti < nint && sum(spikesin)>0
            lastinti = find(intsin,1,'last');
            intsin(lastinti+1) = 1;
            lastinti = lastinti + 1;
        end
        
        
        % rates are inverse of the relevant intervals
        rates = 1./intervals(intsin);
        
        % calculate
        if sum(spikesin) == 0
            fracts = 1;
        else
            fracts = nan(sum(intsin),1);
            stimesin = stimes(spikesin);
            fracts(1) = (stimesin(1)-binedges(i))/binsize;
            for j = 1:sum(spikesin)-1
                fracts(j+1) = (stimesin(j+1)-stimesin(j))/binsize;
            end
            fracts(end) = (binedges(i+1)-stimesin(end))/binsize;
        end
        
        firates(i) = sum(fracts.*rates);
        if isnan(firates(i))
            ERRRRRORRRRRR
        end
    end
end
end



%% Let's do Kernel smoothing assuming that the query timepoints will fall
% on (or very close to) timepoints in xin. 

% Expects index values for which timepoints in xin to use for yout calculation.
% Expects a pre-calculated kernel that is centered at 0.

function yout = KernelSmooth_Aligned(yin, iout, kernel)

% yin is the unfiltered raw signal sampled at xin
% iout is the timestamps of the desired output (given as indices of yin)
% kernel is the kernel to convolve with. Must sum to 1. Must be in the same resolution as yin. Must be a column vector

halfwin = (length(kernel)-1)/2;

% Just do a little input checking
if any(isnan(yin))
    error('NaNs in the input');
end
if min(iout) <= halfwin
    error('Smallest index is too close to start');
end
if max(iout) >= size(yin,1)-halfwin
    error('Largest index is too close to end');
end
if size(kernel,2) > 1
    error('Kernel must be a column');
end

nout = length(iout);

ny = size(yin,2);

yout = nan(nout,ny);

for i = 1:nout
    yout(i,:) = yin((iout-halfwin):(iout+halfwin))*kernel;
end
end