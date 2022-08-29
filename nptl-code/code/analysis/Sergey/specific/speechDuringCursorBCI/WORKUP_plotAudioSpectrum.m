% Look at audio data.
% based on WORKUP_visualizeAcoustic.m
%
% Sergey Stavisky, March 14 2019
clear


saveFiguresDir = [FiguresRootNPTL '/speechDuringBCI/acoustic/600ms/'];
if ~isdir( saveFiguresDir )
    mkdir( saveFiguresDir )
end



%% Dataset 


% t5.2017.12.17 Stand-alone words
% participant = 't5';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17-words_noRaw.mat';


% t5.2017.12.17 words during BCI
% this was the R struct that was constructed LIKE the stand-alone one
participant = 't5';
Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17-wordsDuringBCI.mat'; 



%%
includeLabels = labelLists( Rfile ); % lookup;

%% Analysis Parameters



% When audible speaking started (based on hand-annotated audio data)
params.alignEvent = 'handResponseEvent';
params.startEvent = 'handResponseEvent - 0.125'; % ends up being -100 
params.endEvent = 'handResponseEvent + 0.625'; % ends up beign 600


% Audio processing
% Note: I don't do the HPF that I do in addVOiceOnsetTime since that's for one particular
% dataset wich some weird DC offsets; it fixes that but disorts the audio, and here I want
% a raw view of the audio.
params.hpfAudioPreprocess = false;
params.filterFunctionHandle = @filtfilt;
params.filterName = 'boxcar_5ms';


% Spectrogram properties
params.segmentLength = 0.050; % in seconds
% params.segmentOverlap = 0.045; % in seconds
params.segmentOverlap = 0.049; % in seconds

% params.NFFT = 256; %how many FFT bins to divide it into
params.NFFT = 320; %how many FFT bins to divide it into



result.params = params;
result.params.Rfile = Rfile;


% Spectrogram plotting options 
% (doesn't affect results that could be saved)
spectrogramFreqMinMax = [100 10000];

%% Load the data
in = load( Rfile );
R = in.R;
clear('in')
datasetName = regexprep( pathToLastFilesep(Rfile,1), {'.mat', 'R_'}, '');
% exclude some trials?
if isfield( params, 'excludeTrials' ) && ~isempty( params.excludeTrials )
    excludeInds =  find( ismember( [R.trialNumber], params.excludeTrials ) .* ismember( [R.blockNumber], params.excludeTrialsBlocknum ) );
    fprintf('Excluding trials %s from blocks %s (%i trials)\n', ...
        mat2str( params.excludeTrials ), mat2str( params.excludeTrialsBlocknum ), numel( excludeInds ) );
    R(excludeInds) = [];
end

    

%% Annotate the data
% Scan for whether event labels files exist for these blocks. 
% Accept trials with wrong response to cue, if it was one of the included responses

uniqueLabels = includeLabels( ismember( includeLabels, unique( {R.label} ) ) ); % throws out any includeLabels not actually present but keeps order
blocksPresent = unique( [R.blockNumber] );
% Restrict to trials of the labels we care about
R = R(ismember(  {R.label}, uniqueLabels ));
fprintf('Sounds from %i trials across %i blocks with % i labels: %s\n', numel( R ), numel( blocksPresent ), ...
    numel( uniqueLabels ), CellsWithStringsToOneString( uniqueLabels ) );
% report trial counts for each condition
for iLabel = 1 : numel( uniqueLabels )
    fprintf(' %s: %i trials\n', uniqueLabels{iLabel}, nnz( arrayfun( @(x) strcmp( x.label, uniqueLabels{iLabel} ), R ) ) )
end
result.uniqueLabels = uniqueLabels;
result.blocksPresent = blocksPresent;
result.params = params;
allLabels = {R.label};


% Determine the critical alignment points
% NOTE: Done differently depending on whether this is words standalone or words during BCI
if isempty( strfind( Rfile, 'wordsDuringBCI' ) ) %#ok<STREMP>
    % note I choose to do this for each block, since this will better address ambient
    % noise/speaker/mic position changes over the day, and perhaps reaction times too (for the
    % silence speech time estimation)
    if any( cell2mat( strfind( params.alignEvent, 'vot' ) ) )
        fprintf('VOT alignment required, will add those now...\n')
        alignMode = 'VOTdetection';
    else
        alignMode = 'handLabels';
    end
    uniqueBlocks = unique( [R.blockNumber] );
    Rnew = [];
    for blockNum = uniqueBlocks
        myTrials = [R.blockNumber] == blockNum;
        Rnew = [Rnew;  speechEventAlignment( R(myTrials), Rfile, 'alignMode', alignMode )];
    end
    R = Rnew;
    clear( 'Rnew' );
else
    nonsilentIdx = ~arrayfun( @(x) strcmp( x.label, 'silence' ), R );
    RT = [R(nonsilentIdx).timeSpeechStart] - [R(nonsilentIdx).timeCueStart];    
    for iTrial = 1 : numel( R )
        R(iTrial).handPreResponseBeep = R(iTrial).timeCueStart; % go cue
        if strcmp( R(iTrial).label, 'silence' )
            R(iTrial).handResponseEvent = R(iTrial).timeCueStart + median( RT ); % median RT
        else
            R(iTrial).handResponseEvent = R(iTrial).timeSpeechStart; % AO was hand marked
        end
    end
end


%% Generate Acoustic feature
audioFs = R(1).audio.rate;
filterStruct = filterNameLookup( params.filterName, audioFs);
filterStruct.filterFunction = params.filterFunctionHandle;
    
% Take absolute value of audio signal, since I want amplitude
for iTrial = 1 : numel( R )
    R(iTrial).audioAbs = R(iTrial).audio;
    
    if params.hpfAudioPreprocess
        R(iTrial).audioAbs.dat = filtfilt( hpfObj, double( R(iTrial).audioAbs.dat ) );
    end
    R(iTrial).audioAbs.dat = single( abs( R(iTrial).audioAbs.dat ) ); %keep reasonable memory usage
end

R = AddFilteredFeature( R, 'audioFiltered', 'sourceSignal', 'audioAbs', ...
    'filterStruct', filterStruct, 'outputRate', audioFs );
R = rmfield( R, 'audioAbs' ); % remove unnecessary absolute value to save memory

%% Get Trial-Average Acoustic Feature
% I'm going to create a cell with each trial's trial-averaged mean/std/se,
% firing rate in the plot window.
% Here I also get a single average rate for each channel per trial.
for iLabel = 1 : numel( uniqueLabels )
    myLabel = uniqueLabels{iLabel};
    myTrialInds = strcmp( allLabels, uniqueLabels{iLabel} );

    % DEV
    try
    result.(myLabel) = rmfield( result.(myLabel) , 'ps' );
    catch
    end %/DEV
    
    % AUDIO AMPLITUDE
    jenga =  AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', 'audioFiltered', ...
          'startEvent', params.startEvent, 'alignEvent', params.alignEvent, 'endEvent', params.endEvent  );
    % Audio amplitude
    result.(myLabel).singleTrial = jenga.dat;
    result.(myLabel).t = jenga.t;
    result.(myLabel).audioMean = squeeze( mean( jenga.dat, 1 ) );
    result.(myLabel).numTrials = jenga.numTrials;
    
    
    % SPECTROGRAM
    jenga =  TrimToSolidJenga( AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', 'audio', ...
          'startEvent', params.startEvent, 'alignEvent', params.alignEvent, 'endEvent', params.endEvent  ) );
    segmentlen = params.segmentLength*audioFs;
    noverlap = params.segmentOverlap*audioFs;
    NFFT = params.NFFT;
    
    for iTrial = 1 : jenga.numTrials
        [s,w,t,ps] = spectrogram(jenga.dat(iTrial,:),segmentlen,noverlap,NFFT,audioFs,'yaxis','power');
        result.(myLabel).ps(iTrial,:,:) = reshape( ps, 1, size(ps,1), size(ps,2) ); % trial x frequency x timebin
    end
    % convert these faux-timestamps into actual time relative to jenga alignment
    t = t + jenga.t(1);
    
    % save spectogram details (just once is fine, but it'll end up repeated )
    result.spectrogram.s = s;
    result.spectrogram.w = w;
    result.spectrogram.t = t;    
end




%% Prep for plotting
% Define the specific colormap
colors = [];
legendLabels = {};
for iLabel = 1 : numel( uniqueLabels )
   colors(iLabel,1:3) = speechColors( uniqueLabels{iLabel} ); 
   legendLabels{iLabel} = sprintf('%s (n=%i)', uniqueLabels{iLabel}, result.(uniqueLabels{iLabel}).numTrials );
end


%% Plot Spectrograms
figh = figure;
figh.Color = 'w';
% keep track of each axis' natural limits, then later
% unify these so all plots have same clim
limitExtrema = [inf -inf];
for iLabel = 1 : numel( uniqueLabels )
    myLabel = uniqueLabels{iLabel}

    axh(iLabel) = subplot( numel( uniqueLabels ), 1, iLabel );
    % trial-average for this label
    myPowerSpectrum = squeeze( mean( result.(myLabel).ps, 1 ) );
    % restrict to frequencies of interest
    keepTheseWind = (result.spectrogram.w >= spectrogramFreqMinMax(1) ) & (result.spectrogram.w <= spectrogramFreqMinMax(2) );
    myPowerSpectrum = myPowerSpectrum(keepTheseWind,:);
    myW = result.spectrogram.w(keepTheseWind)/1000; % express in kHz
%     figure; spectrogram(jenga.dat(1,:),segmentlen,noverlap,NFFT,audioFs,'yaxis', 'psd');
    imh = imagesc( result.spectrogram.t, myW, log10( abs( myPowerSpectrum ) ).*10 ); %.*10 expresses it in decibel, /1000 for kHz
%     colorbar; % units are Power (dB)
    axh(iLabel).YDir = 'normal';
    axh(iLabel).YAxis.Color = colors(iLabel,:);
    axh(iLabel).TickDir = 'out';
    colormap( flipud( gray ) ) 
    myClim = axh(iLabel).CLim;
    limitExtrema(1) = min( [limitExtrema(1) myClim(1)] );
    limitExtrema(2) = max( [limitExtrema(2) myClim(2)] );
end
for i = 1 : numel( axh )
    axh(i).CLim = limitExtrema;
    % line at t = 0
    line( axh(i), [ 0 0], limitExtrema, 'Color', 'r' )
end
linkaxes( axh )

titlestr = sprintf( 'Spectrogram %s %s', datasetName, params.alignEvent );
figh.Name = titlestr;
ExportFig( figh, [saveFiguresDir titlestr] );


%% Plot Acoustic Envelope

figh = figure;
figh.Color = 'w';
titlestr = sprintf('audio %s', datasetName);
figh.Name = titlestr;
axh = axes; hold on;
xlabel(['Time ' params.alignEvent ' (s)']);
for iLabel = 1 : numel( uniqueLabels )
% for iLabel = 10  % sh only

    myLabel = uniqueLabels{iLabel};
    myTrialInds = strcmp( allLabels, uniqueLabels{iLabel} );

    % PLOT IT
    myX = result.(myLabel).t;
    myY = result.(myLabel).audioMean; % mean
%     myY = result.(myLabel).singleTrial;

    plot( myX, myY, 'Color', colors(iLabel,:), ...
        'LineWidth', 1 );
    
end
% vertical axis at t=0
line([0 0], axh.YLim, 'Color', [.5 .5 .5], 'LineWidth', 0.5)

% PRETTIFY
% make horizontal axis nice
xlim([myX(1), myX(end)])
% make vertical axis nice

set( axh, 'TickDir', 'out' )

% add legend
MakeDumbLegend( legendLabels, 'Color', colors );
