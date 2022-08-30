function [specPower, specgramc, est_pch, bandsfilt, bandsfiltdB, filtITI] = freqbandPower(blc, ecog, ch, params, varargin)
%{
    FREQBANDPOWER(BLC,TASK, PARAMS,VARARGIN)
This is now being changed to match a blc format

Need this: blc=BLc.Reader(blcfile);

    Separate data per frequency bands and compare, if specified, against
    a baseline.

    Example: 
        [ thisJO2, specPowerJO2 ] = Analysis.ArtSens.artsens_proc( blcJO2, 'ch', [1 10]);
    
    Where ECOG is an ECOGTASK object which has the parsed raw data of each
    trial and ITIs.

    If no other input is given, defaults PARAMS are used, plots are drawn
    for each event type (stimulus type) for all channels, and saved under
    new folder.

    Additional inputs:
        specPower = freqbanPower(ecog,[],PARAM1,VAL1,PARAM2,VAL2...)
    
    Optional pair-value inputs can be given to specify whether the output
    should be normalized ('normalize',true/false. Default = false), which
    baseline to use for normalization ('baseline',str. Default = 'ITI'),
    specify stimulus window to analyze for the data and the baseline 
    ('specWin',[secs secs]. Default = [1 1]), which normalization method to
    use ('method',z-score/minmax/robust1/robust2. Default = 'z-score'), and
    whether to plot or not the spectrums ('plotTF',true/false. Default =
    true). 
    
    Example of additional inputs:
        specPower =
        freqbandPower(ecog,[],'normalize',true,'mehtod','robust1');

 Varargin
    gridplot=   do you want to plot the heatmaps or something else next
    to each other in the manner they are laid out on the actual grid

    gridttype=  options are mini=1 and twenty (4x5)=2 right now
    
    orientation=    the way it's laying on the brain, two numbers [x
    y],x: 1=left 2=right, y: tails pointing: 1=inferior, 2=posterior,
    3=superior, 4=anterior
 

    NOTE: You need to run the ECOGTASK object first to get ECOG object.
    

    ALSO CHECK: ecogTask.m, plotsave.m, shadedErrorBar.m,
    Analysis.ArtSens.getNormValues.m, mtspecgramc.m (from Chronux) 


%}


%WILL NEED TO EITHER FIX THIS WITH ANOTHER || STATEMENT OR IF THEN
%assert(isa(ecog,'ArtSens.ecogTask')||isa(ecog,'struct'),'First input should be ArtSens.ecogTask object or structure, not %s',class(ecog));


% Default and optional inputs values

[varargin,normalize] = util.argkeyval('normalize',varargin,true);
[varargin,baseline] = util.argkeyval('baseline',varargin,'ITI');
[varargin,itiWin] = util.argkeyval('specWin',varargin,1.5); % in seconds, ITI window specWin(2) 
[varargin,prepost] = util.argkeyval('prepost',varargin,[0.5 2]); %the size of the pre (before touch) and post (after touch) lengths in seconds, this includes a buffer to help the windows keep real data (for instance only care about 0-1.5)
[varargin,method] = util.argkeyval('method',varargin,'z-score');  % for normalization
[varargin, plotTF] = util.argkeyval('plotTF',varargin,true);
%[varargin,ch] = util.argkeyval('ch',varargin,[1:blc.ChannelInfo(end).ChannelNumber]); %check what channels are desired
[varargin, window]=util.argkeyval('window',varargin,[0.2 0.005]); %control the window in the spectrogram
[varargin, plot_buff]=util.argkeyval('plot_buff',varargin,[-0.1 1.6]); %this will dictate how much of the graph before 0 and after to show (e.g. time window total (prepost) is 0.5 to 2 and you only care about 0-1.5, give a [0.1 1.6] s buffer so it shows -0.1 to 1.6)
[varargin, pad]=util.argkeyval('pad',varargin,1); %control the pad in the spectrogram
[varargin, frequency]=util.argkeyval('frequency',varargin,[0 200]); %control the frequency min and max
[varargin,dB] = util.argkeyval('dB',varargin, true); %turn on or off the 10*log10 adjustment for the normalized


lim = [-80 -40]; ylbl = 'Power (dB)';

[varargin, gridplot] = util.argkeyval('gridplot',varargin, true); %if you want to plot in a gridlayout
[varargin, gridtype] = util.argkeyval('gridtype',varargin, 1); %types of grids, options are mini=1 and 4x5=2 at this time
[varargin, orientation] = util.argkeyval('orientation',varargin, 1); %the orientation on the brain that the tails are pointing, this is done with the idea that you are looking at the grid on a 3d represenation of the brain
%Minigrid Adtech 8x8
%Orientation 1 L inferior pointing tails or R inferior pointing tails
%Orientation 2 L posterior pointing tails or R anterior pointing tails
%Orientation 3 L anterior pointing tails or R posterior pointing tails
%Orientation 4 L or R superior pointing tails
%4x5 integra
%Orientation 1  R or L inferior pointing tails
%Orientation 2 R posterior pointing tails or L anterior pointing tails
%Orientation 3 L posterior pointing tails or R anterior pointing tails
%Orientation 4 L sup pointing tails or R sup pointing tails
[varargin, userinput] = util.argkeyval('userinput',varargin, false); %if gridplot==true, and userinput==true, will prompt you to pick the channels you want. if false, then you need to enter them yourself as channels2plot
%[varargin, xch2plot] = util.argkeyval('xch2plot',varargin, ch);%if userinput false, then xchs2plot takes the input channels or does all by default
[varargin, xch2plot] = util.argkeyval('xch2plot',varargin, ch);%gets the channels to plot in the gridmap from the user gui input or hand input from arsens_proc

[varargin, quickrun] = util.argkeyval('quickrun',varargin, false); %make true if you don't want to graph or run through the stats, just to get the numbers output

[varargin, saveplots] = util.argkeyval('saveplots',varargin, true);%gets the channels to plot in the gridmap from the user gui input or hand input from arsens_proc
[varargin, kluge] = util.argkeyval('kluge',varargin, false);%gets the channels to plot in the gridmap from the user gui input or hand input from arsens_proc



util.argempty(varargin); % check all additional inputs have been processed

filtITI=[];

% check if params structure was provided
if nargin == 1 || isempty (params)
    params = struct;
    params.Fs = blc.SamplingRate;   % in Hz
    params.fpass = frequency;     % [minFreqz maxFreq] in Hz
    params.tapers = [5 9]; %second number is 2x the first -1, and the tapers is how many ffts you do.
    params.pad = pad;
    %params.err = [1 0.05];
    params.err=0;
    params.trialave = 0; % average across trials
    params.win = window;   % size and step size for windowing continuous data
    params.bipolar=false;
    params.readChan=[1 blc.ChannelInfo(end).ChannelNumber];    
end

freqbands = [8 15;15 30;30 50;50 params.fpass(2)]; % [min max] values of frequency bands to compute
bandlbl = {'Alpha','Beta','Gamma', 'HighGamma'}; % alpha = 8:15, delta = 0.1-4, theta = 4-8, beta = 15-30, gamma = 30-50 high gamma 50+

%%
%set up colors
C=linspecer(36);

%adjust plot buffers
plot_buff(1,1)=-prepost(1,1)+window(1,1)/2 +plot_buff(1,1);
plot_buff(1,2)=prepost(1,2)+window(1,1)/2-plot_buff(1,2);
%%

% Filter for 60 Hz noise and 120 Hz
bsFilt1 = designfilt('bandstopiir','FilterOrder',2, ...
    'HalfPowerFrequency1',59,'HalfPowerFrequency2',61, ...
    'SampleRate',params.Fs,'DesignMethod','butter');

bsFilt2 = designfilt('bandstopiir','FilterOrder',2, ...
    'HalfPowerFrequency1',119,'HalfPowerFrequency2',121, ...
    'SampleRate',params.Fs,'DesignMethod','butter');

bandfilters=struct;
for jj=1:length(bandlbl)
bandfilters.(bandlbl{jj})=designfilt('bandpassiir',...
           'DesignMethod','butter',...
           'FilterOrder',8,...
           'HalfPowerFrequency1',freqbands(jj,1),...
           'HalfPowerFrequency2',freqbands(jj,2),...
           'SampleRate',params.Fs);
end


% Default values
if params.bipolar
    %THIS NEEDS TO BE FIXED IN THE FUTURE, NEED TO LOOK AT THE ECOG OBJECT
    %FROM MICHELLE TO SEE WHAT SHE WAS DOING WITH THIS
    ch = params.elecPairs;
    refdir = 'BIPOLAR-REF';
else
    ch = ch;
    refdir = 'REF';
end



%% NORMALIZED
% if normalized specified, check where the baseline should be pulled from
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ITI
if normalize
    paramsbase = params;
    sufname = ['norm',baseline];
    ylbl = 'Normalized power';
    
    if strcmpi(baseline,'ITI') % can use the inter-trial interval (default)
        baseline_data = ecog.iti;
        limfun = @(x)x-1;
    else %this is if you change what you want as your baseline to something else, unlikely to change unless i compare to a baseline prior to start of trial
        idx = find(strcmp(ecog.evtNames,baseline),1);
        baseline_data = ecog.trialdata(idx);
        ecog.evtNames(idx) = [];
        ecog.trialdata(idx) = [];
        baseline_data = repmat(baseline_data,1,length(ecog.evtNames));
    end
    %%
    %samplesxtouches total among all three typesxchannels, cycles through
    %the touches
    %ALL OF THIS ITIWIN STUFF IS CHECKED, IT WORKS
    base = nan(itiWin*params.Fs,sum(cellfun(@length,baseline_data)),size(ch,1), 'single', 'gpuArray');
    
    c = 1;   
    for ff = 1:length(baseline_data) %iti for each touch type
        for tt = 1:length(baseline_data{ff}) %touches within the type
            if params.bipolar
                temp = baseline_data{ff}(tt).voltage;
            else
                %subtract the mean of the iti to offset DC voltage
                %temp is then the iti for ff touch type at tt touch trial
                temp = baseline_data{ff}(tt).voltage - repmat(nanmean(baseline_data{ff}(tt).voltage,1),size(baseline_data{ff}(tt).voltage,1),1);
            end
            %if the length of an iti is short, just add the extra on
            %there with flip. This should be rare as the lengths are going to be
            %altered
            if length(temp)<params.Fs*itiWin
                extra=params.Fs*itiWin-length(temp);
                temp=vertcat(temp, flipud(temp(end-extra:end,:)));
            end
            temp = filtfilt(bsFilt1,temp); % filter raw data for 60 and 120
            temp = filtfilt(bsFilt2,temp);
            if size(temp,1) <= itiWin*params.Fs
                idx1 = 1; idx2 = size(temp,1);
            else
                idx1 = 1;
                idx2 = itiWin*params.Fs;
            end
            %create base, a 3d matrix with temp, which is the filtered data
            %with the subtracted iti mean taken off. it's
            %time x alltrialsamongalltouchtypes x ch.  That c keeps it so
            %it integrates all the trails, even other touches
            %base(1:length(idx1:idx2),c,:) = temp(idx1:idx2,ch(1):ch(end));
            %run the filters and get power, it's channel, touch type, freq band, trial
           
            for kk=1:size(ch,2)
                base(1:length(idx1:idx2),c,kk) = temp(idx1:idx2,ch(kk));
            end
            c = c + 1;
        end
    end
end

%%
% Initialize output variables
specPower = struct;
est_pch = struct;
specgramc=struct;
bandsfilt=struct;
bandsfiltdB=struct;

tmp=struct;
%establsih names for the struct
for ff=1:length(ecog.evtNames)
    if strcmpi(ecog.evtNames{ff}, 'SOFT TOUCH'); touch{ff}='SoftTouch';
    elseif strcmpi(ecog.evtNames{ff}, 'LIGHT TOUCH'); touch{ff}='LightTouch';
    elseif strcmpi(ecog.evtNames{ff}, 'DEEP TOUCH'); touch{ff}='DeepTouch';
    else; touch{ff}=ecog.evtNames{ff}(1:3);
    end
end
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%TRIALS
for ff = 1:length(ecog.evtNames) % loop through event type (touch type)
    
    st = struct; % struct will have a row per channel, with the freqbands as fields
    for kk = 1:size(ch,2) % loop through specified channels
        data_temp = zeros((prepost(1)+prepost(2))*params.Fs,length(ecog.trialdata{ff}), 'single', 'gpuArray'); % memory pre-allocation
        data_tempEnd = zeros(length(ecog.End{ff}(1).end),length(ecog.End{ff}), 'single', 'gpuArray'); % memory pre-allocation
        for tt = 1:length(ecog.trialdata{ff}) % trials of touch
            %NOTE: here temp is from prepost(1) before time 0 to end of the
            %trial (so XX-prepost(1) to ZZ)
            if params.bipolar
                temp = ecog.trialdata{ff}(tt).voltage; %regular pre and post the start of the trial
                tempEnd = ecog.End{ff}(tt).end; %separately do the end of the trial
            else
                %temp has the data (minus the d/c voltage if not bipolar)
                temp = ecog.trialdata{ff}(tt).voltage - repmat(nanmean(ecog.trialdata{ff}(tt).voltage),size(ecog.trialdata{ff}(tt).voltage,1),1); % Get data and remove DC voltage
                tempEnd = ecog.End{ff}(tt).end - repmat(nanmean(ecog.End{ff}(tt).end),size(ecog.End{ff}(tt).end,1),1); % Get data and remove DC voltage from the zz end

            end
            
            temp = filtfilt(bsFilt1,temp); % filter raw data for 60 hz noise
            temp = filtfilt(bsFilt2,temp); %filter for 120 hz noise
            tempEnd = filtfilt(bsFilt1,tempEnd); % filter raw data for 60 hz noise
            tempEnd = filtfilt(bsFilt2,tempEnd); %filter for 120 hz noise
            
            idx1 = 1; % Get indices centered at start of trial, in parsetrials, the trial length already includes the time before 0 set at prepost(1) (-0.5s from xx)
            idx2 = (prepost(1)+prepost(2))*params.Fs; % of specified duration prepost, so should start prepost(1) before the trial to prepost(2) after (+2s from xx)
            %at the very end of the trial, if there isn't
            %prepost(2)*params.FS, it stops at that point, will mirror that
            %last part, shouldn't be much and it's all a buffer for
            %specgram anyway
            
            if idx2>length(temp)
                extra=idx2-length(temp);
                temp=vertcat(temp, flipud(temp(end-extra:end,:)));
            end
            %add to the beginning for a ramp up
            tempF=vertcat(flipud(temp(1:params.Fs,:)), temp);
            tempFEnd=vertcat(flipud(tempEnd(1:params.Fs,:)), tempEnd);
            %  THE FILTERED POWER OVER THE BAND
            %run the filters and get power, it's channel, touch type, freq band, trial
            for jj=1:length(bandlbl)
                tempfiltered=[]; tempfilteredEnd=[];
                tempfiltered=(filtfilt(bandfilters.(bandlbl{jj}), tempF)).^2;
                tempfilteredEnd=(filtfilt(bandfilters.(bandlbl{jj}), tempFEnd)).^2;

                %remove the ramp up
                tmp.(bandlbl{jj})=tempfiltered(params.Fs+1:end,:);
                tmpEnd.(bandlbl{jj})=tempfilteredEnd(params.Fs+1:end,:);

                for rr=1:length(ch)
                    %this will be the non z scored version and wont be
                    %output at this time.  it was run, but the between
                    %subject voltages were very very different, so being z
                    %scored to fix that.
                    bandsfilt(rr).(touch{ff}).(bandlbl{jj})(:,tt)  = tmp.(bandlbl{jj})(idx1:idx2,ch(rr));
                    bandsfiltdB(rr).(touch{ff}).(bandlbl{jj})(:,tt)  = 10*log10(tmp.(bandlbl{jj})(idx1:idx2,ch(rr)));
                    %now has filtered bands centered at the ends
                    bandsfiltEnd(rr).(touch{ff}).(bandlbl{jj})(:,tt)  = tmpEnd.(bandlbl{jj})(:,ch(rr));
                    bandsfiltdBEnd(rr).(touch{ff}).(bandlbl{jj})(:,tt)  = 10*log10(tmpEnd.(bandlbl{jj})(:,ch(rr)));
                    
                end
            end
            %MAKE THEM ALL THE SAME SIZE HERE (as opposed to different
            %sizes depending on the trials.  Still contains the -prepost(1)
            %amount
            data_temp(:,tt) = temp(idx1:idx2, ch(kk)); %take the data to that window for each channel specified in kk.
            data_tempEnd(:,tt) = tempEnd(:, ch(kk)); %get the end centered data
        end
        if params.err==0
            %  THE SPECTROGRAMS
            [S,tspec,f] = chronux_gpu.ct.mtspecgramc(data_temp,params.win,params); % S (time-by-frequency)
            [SEnd,tspecEnd,fEnd] = chronux_gpu.ct.mtspecgramc(data_tempEnd,params.win,params); % S (time-by-frequency)

            %
            tspec=gather(tspec);
            f=gather(f);
            tspecEnd=gather(tspecEnd);
            fEnd=gather(fEnd);
        else
            [S,tspec,f] = chronux_gpu.ct.mtspecgramc(data_temp,params.win,params); % S (time-by-frequency)
            [SEnd,tspecEnd,fEnd] = chronux_gpu.ct.mtspecgramc(data_tempEnd,params.win,params); % S (time-by-frequency) for the ends

            
            tspec=gather(tspec);
            f=gather(f);
            tspecEnd=gather(tspecEnd);
            fEnd=gather(fEnd);
        end
        if normalize
            %FILTERED POWER
            %time x alltrialsamongalltouchtypes x ch.  That c keeps it so
            %it integrates all the trails, even other touches
            %base(1:length(idx1:idx2),c,:) = temp(idx1:idx2,ch(1):ch(end));
            %run the filters and get power, it's channel, touch type, freq band, trial
            tempB=[];
            tempB = double(gather(squeeze(base(:,:,kk))));
            % add a mirrored end to cut off the ramp up for the filters
            tempBn=vertcat(flipud(tempB(1:params.Fs,:)), tempB);
            
            for jj=1:length(bandlbl)
                matsz=size(bandsfilt(rr).(touch{ff}).(bandlbl{jj}),1);
                matszEnd=size(bandsfiltEnd(rr).(touch{ff}).(bandlbl{jj}),1);
                if size(tempBn,1) < matsz
                    extra=matsz-size(tempBn,1);
                    tempBn=vertcat(tempBn, flipud(tempBn(end-extra:end-1,:)));
                end
                
                tmpBpre=filtfilt(bandfilters.(bandlbl{jj}), tempBn).^2; %non dB
                tmpB=tmpBpre(params.Fs+1:end,:); %cuts off the ramp up, so now back to normal size
                %if any values are 0, it screws the whole thing up, change
                %them to a low value.
                tmpB(tmpB==0)=0.00001;
                tmpBdB=10*log10(tmpB); %dB
                %a is mean b is std, make one value for the whole iti so
                %that random fluctuations across time are washed out
                Ao=nanmean(nanmean(tmpB,2)); Bo=nanmean(nanstd(tmpB,[],2));
                A=repmat(Ao,matsz,size(bandsfilt(rr).(touch{ff}).(bandlbl{jj}),2));
                Aend=repmat(Ao,matszEnd,size(bandsfiltEnd(rr).(touch{ff}).(bandlbl{jj}),2));
                B=repmat(Bo,matsz,size(bandsfilt(rr).(touch{ff}).(bandlbl{jj}),2));
                Bend=repmat(Bo,matszEnd,size(bandsfiltEnd(rr).(touch{ff}).(bandlbl{jj}),2));
                AdBo=nanmean(nanmean(tmpBdB,2)); BdBo=nanmean(nanstd(tmpBdB,[],2));
                AdB=repmat(AdBo,matsz,size(bandsfilt(rr).(touch{ff}).(bandlbl{jj}),2));
                AdBend=repmat(AdBo,matszEnd,size(bandsfiltEnd(rr).(touch{ff}).(bandlbl{jj}),2));
                BdB=repmat(BdBo,matsz,size(bandsfilt(rr).(touch{ff}).(bandlbl{jj}),2));
                BdBend=repmat(BdBo,matszEnd,size(bandsfiltEnd(rr).(touch{ff}).(bandlbl{jj}),2));

                %here kk is the channel you want, doesn't need to be ch(kk)
                %because bandsfilt is already only those channels
                bandsfilt(kk).(touch{ff}).(bandlbl{jj})=(bandsfilt(kk).(touch{ff}).(bandlbl{jj})-A)./B;
                bandsfiltdB(kk).(touch{ff}).(bandlbl{jj})=(bandsfiltdB(kk).(touch{ff}).(bandlbl{jj})-AdB)./BdB;
                bandsfiltEnd(kk).(touch{ff}).(bandlbl{jj})=(bandsfiltEnd(kk).(touch{ff}).(bandlbl{jj})-Aend)./Bend;
                bandsfiltdBEnd(kk).(touch{ff}).(bandlbl{jj})=(bandsfiltdBEnd(kk).(touch{ff}).(bandlbl{jj})-AdBend)./BdBend;
                
            end
            %%FFT the ITI
            Sbase = chronux_gpu.ct.mtspecgramc(tempB,paramsbase.win,paramsbase); % Sbase (time-by-frequency)
            
            if dB %currently only happening in 'normalize', outside of that, it is being done later
                S=10*log10(S);
                SEnd=10*log10(SEnd);

                Sbase=10*log10(Sbase);
            end
            filtITI{kk}=Sbase; %store the non averaged iti
            S=gpuArray(S);
            SEnd=gpuArray(SEnd);
            Sbase=gpuArray(Sbase);
            SBaseEnd=gpuArray(Sbase(1:size(SEnd,1),:,:));
            %make the iti uniform across frequency bands, meaning at a
            %frequency bin, the value will be the same for all of the time
            Sbase=repmat(nanmean(Sbase,1),size(S,1),1);
            if ~quickrun
                %alpha set at 0.00024 for 0.05/(60*3+20)
                [ mnd1, mnd2, ~, ~, sigclust, rlab ] = stats.cluster_permutation_Ttest_gpu3d( S, Sbase, 'alph', 0.00024 );
                est_pch.starts.(touch{ff}){kk}.clust_p=sigclust; %load the cluster
                [ mnd1End, mnd2End, ~, ~, sigclustEnd, rlabEnd ] = stats.cluster_permutation_Ttest_gpu3d( SEnd, Sbase, 'alph', 0.00024 );
                est_pch.ends.(touch{ff}){kk}.clust_p=sigclustEnd; %load the cluster
            elseif quickrun
                mnd1=nanmean(S,3);
                mnd1End=nanmean(SEnd,3);
                mnd2=nanmean(Sbase,3);
                
            end

            %a is mean b is std
            [a,b] = Analysis.ArtSens.getNormValues(Sbase,method,size(S,2),1,1); % get numerator and denominator, this averages and std the Sbase across trials now, already averaged over time
            S = mnd1; %now averaged over trial
            SEnd = mnd1End;
            Sbase = mnd2; %now averaged over trial and time, so it's uniform for a given frequency
            S = (S-a)./b; % normalize/standarize values, subtract the mean and divide by the std
            SEnd = (SEnd-a)./b;
            S = gather(S);
            SEnd = gather(SEnd);
            Sbase = gather(Sbase);
        end
        %%
        idx=1;
        if ~quickrun
            figtitle=[' Channel ', blc.ChannelInfo(ch(kk)).Label, ' Spectrogram ', blc.SourceBasename, ' ', ecog.evtNames{ff}];
            figure('Name', figtitle, 'Position', [400 100 800 800]) %x bottom left, y bottom left, x width, y height
            lims=zeros(length(freqbands),4); subgca=[];
        end
        %get the averaged frequency bands
        for bb = 1:size(freqbands,1)
            idx = f >= freqbands(bb,1) & f < freqbands(bb,2); % find index which correspond to frequency band
            st(kk).(bandlbl{bb}) = nanmean(S(:,idx),2);
            if params.err~=0
                st(kk).(bandlbl{bb}) = cat(2,st(kk).(bandlbl{bb}),nanmean(Serr(:,:,idx),3)'); % make the second column the average of the error
            end
            if plotTF && ~isempty(st(kk).(bandlbl{bb})) && all(~isnan(st(kk).(bandlbl{bb})(:)))
                if ~quickrun
                subplot(size(freqbands,1),1,bb)
                end
                
                %%
                if normalize || dB
                    pwdb = nanmean(S(:,idx),2);
                    lims(bb,1)=max(pwdb);
                    lims(bb,2)=min(pwdb);
                    
                    serr_mean=std(S(:, idx),[],2); %take the serr along the rows, because the rows are the different values in that time bin among the frequencies in that band.
                    lims(bb,3)=max(serr_mean+pwdb);
                    lims(bb,4)=min(pwdb-serr_mean);
                elseif ~dB %if ~db then this hasn't already been done
                    pwdb = 10*log10(nanmean(S(:,idx),2));
                    serr_mean=10*log10(std(S(:, idx),[],2)); %take the serr along the rows, because the rows are the different values in that time bin among the frequencies in that band.
                    
                end
                %to set up the x axis, this gives the time bins
                %converted.  The last part of line two moves the data
                %up by half the window because the bins, by default,
                %mark the middle (meaning if it's a 0.2 second window,
                %the bin is centered at 0.1, this corrects it to 0)
                tplot = linspace(floor((tspec(1)-params.win(1)/2)*1000),ceil((tspec(end)+params.win(1)/2)*1000),length(tspec));
                %if the window is the same size or bigger than the amount
                %you are starting before 0, adjust everything to 0.
                if params.win(1)>=prepost(1)
                    time_corr =prepost(1);
                    plot_buff(1)=0;
                else
                    %this shifts everything over to make it so less is
                    %before 0.  VERIFIED 4/19/18
                    time_corr=params.win(1);
                end
                %this ends up with the window going from -0.3 to 2.2 (or 0
                %to 2.5)
                tplot=tplot/1000-prepost(1)+time_corr;
                if ~quickrun
                    H=shadedErrorBar(tplot,real(pwdb),real(serr_mean),'lineprops', {'-r', 'markerfacecolor', C(1,:)});
                    H.mainLine.LineWidth=4;
                    title(bandlbl{bb})
                    box off;
                    subgca(bb)=gca;
                    xlim([plot_buff(1) plot_buff(2)]); %only show the plot buffer pre and buffer post
                    
                    %set up labels
                    if  bb==round(size(freqbands,1)/2)
                        if normalize
                            ylabel('Normalized Power')
                        else
                            ylabel('Power (dB)')
                        end
                    elseif bb==size(freqbands,1)
                        xlabel('Time (ms)')
                    end
                    if bb == 1; suptitle([ecog.evtNames{ff},'. Chan ',blc.ChannelInfo(ch(kk)).Label]); end
                    
                    ylnew = [min(lims(:,4)) max(lims(:,3))];
                    set(subgca, 'Ylim', ylnew)
                end
                
            end
        end
        
        
        %%
        
        %plot the actual data
        heatpow=S';
        heatpowEnd=SEnd';
        heatpowSB=Sbase';
        %load in each S to make other graphs later
        specgramc.starts.(touch{ff}).(blc.ChannelInfo(ch(kk)).Label)=heatpow;
        specgramc.ends.(touch{ff}).(blc.ChannelInfo(ch(kk)).Label)=heatpowEnd;
        %%
        if ~quickrun %exclude if you want a quick run through without graphs
            %%
            %plot the touch onset
            figtitle=['Touch Onset Channel ', blc.ChannelInfo(ch(kk)).Label, ' Heatmap ', blc.SourceBasename, ' ', ecog.evtNames{ff}];
            figure('Name', figtitle, 'Position', [5 150 1200 750]) %x bottom left, y bottom left, x width, y height
            subplot(3,2, [1 2 3 4])
            
            im=imagesc(tplot,f, heatpow); axis xy;
            ax=gca;
            xlim([plot_buff(1) plot_buff(2)]); %only show the plot buffer pre and buffer post
            title(['Touch Onset Normalized Power ', ecog.evtNames{ff},' channel ',blc.ChannelInfo(ch(kk)).Label])
            xlabel('Time (s)','Fontsize',13);
            ylabel('Frequency (Hz)','Fontsize',13);
            colorbar;
            colormap(inferno(100));
            
            %plot the corrected p values, 1 is significant 0 is not
            subplot(3,2,5)
            %for color schemes
            %temp_p=double(sigclustDB');
            %temp_p(temp_p==0)=0.6;
            %temp_p(temp_p==1)=0.18;
            %temp_p(1,1)=0; temp_p(1,2)=1;
            im=imagesc(tplot, f, rlab); axis xy;
            ax=gca;
            xlim([plot_buff(1) plot_buff(2)]); %only show the plot buffer pre and buffer post
            title(['Pvalues Bonferroni ', ecog.evtNames{ff},' channel ',blc.ChannelInfo(ch(kk)).Label])
            xlabel('Time (s)','Fontsize',13);
            ylabel('Frequency (Hz)','Fontsize',13);
            ax.YTick=(0:20:frequency(2));
            
            
            %plot the sig clust
            subplot(3,2,6)
            temp_p=double(sigclust');
            %temp_p(temp_p==0)=0.6;
            %temp_p(temp_p==1)=0.18;
            %temp_p(1,1)=0; temp_p(1,2)=1;
            im=imagesc(tplot, f, temp_p); axis xy;
            ax=gca;
            xlim([plot_buff(1) plot_buff(2)]); %only show the plot buffer pre and buffer post
            title(['Pvalues Cluster Permutation ', ecog.evtNames{ff},' channel ',blc.ChannelInfo(ch(kk)).Label])
            xlabel('Time (s)','Fontsize',13);
            ylabel('Frequency (Hz)','Fontsize',13);
            ax.YTick=(0:20:frequency(2));
            
            %%
            %plot the Ends, touch offset
            figtitle=['Touch Offset Channel ', blc.ChannelInfo(ch(kk)).Label, ' Heatmap ', blc.SourceBasename, ' ', ecog.evtNames{ff}];
            figure('Name', figtitle, 'Position', [5 150 1200 750]) %x bottom left, y bottom left, x width, y height
            subplot(3,2, [1 2 3 4])
            
            im=imagesc(tplotEnd,fEnd, heatpowEnd); axis xy;
            ax=gca;
            title(['Touch Offset Normalized Power ', ecog.evtNames{ff},' channel ',blc.ChannelInfo(ch(kk)).Label])
            xlabel('Time (s)','Fontsize',13);
            ylabel('Frequency (Hz)','Fontsize',13);
            colorbar;
            colormap(inferno(100));
            
            %plot the corrected p values, 1 is significant 0 is not
            subplot(3,2,5)
            %for color schemes
            %temp_p=double(sigclustDB');
            %temp_p(temp_p==0)=0.6;
            %temp_p(temp_p==1)=0.18;
            %temp_p(1,1)=0; temp_p(1,2)=1;
            im=imagesc(tplotEnd, fEnd, rlabEnd); axis xy;
            ax=gca;
            
            title(['Pvalues Bonferroni ', ecog.evtNames{ff},' channel ',blc.ChannelInfo(ch(kk)).Label])
            xlabel('Time (s)','Fontsize',13);
            ylabel('Frequency (Hz)','Fontsize',13);
            ax.YTick=(0:20:frequency(2));
            
            
            %plot the sig clust
            subplot(3,2,6)
            temp_pEnd=double(sigclustEnd');
            %temp_p(temp_p==0)=0.6;
            %temp_p(temp_p==1)=0.18;
            %temp_p(1,1)=0; temp_p(1,2)=1;
            im=imagesc(tplotEnd, fEnd, temp_pEnd); axis xy;
            ax=gca;
            
            title(['Pvalues Cluster Permutation ', ecog.evtNames{ff},' channel ',blc.ChannelInfo(ch(kk)).Label])
            xlabel('Time (s)','Fontsize',13);
            ylabel('Frequency (Hz)','Fontsize',13);
            ax.YTick=(0:20:frequency(2));
            
            %%
            %plot the iti for the first touch so you can look at it and
            %make sure it doesn't look weird
            if ff==1 %print the ITI the first time IF MAKING A LOCAL ITI, THEN CAN DO THIS FOR EACH ONE IF NECESSARY
                figtitle=[' Channel ', blc.ChannelInfo(ch(kk)).Label, ' ITI Heatmap ', blc.SourceBasename, ' ', ecog.evtNames{ff}];
                figure('Name', figtitle, 'Position', [5 150 1200 750]) %x bottom left, y bottom left, x width, y height
                
                im=imagesc(tplot,f, heatpowSB); axis xy;
                ax=gca;
                xlim([plot_buff(1) plot_buff(2)]); %only show the plot buffer pre and buffer post
                title(['ITI ', ecog.evtNames{ff},' channel ', blc.ChannelInfo(ch(kk)).Label])
                xlabel('Time (s)','Fontsize',13);
                ylabel('Frequency (Hz)','Fontsize',13);
                ax.YTick=(0:20:frequency(2));
                colorbar;
                colormap(inferno(100));
            end
            
            %est_pch.(nmes{ff}){kk}=est_p; %load the estimated p values for each channel
            
            if saveplots
                if ~kluge
                    plt.save_currfig('SavePath', blc)
                elseif kluge %for one specific patient, can delete after
                    filespot='\\striatum\Data\neural\incoming\unsorted\rancho\BROWN_SHAMIKA@ResearchRealTouch';
                    plt.save_currfig('SavePath', filespot)
                end
                
            end
            
            
        end
        
        
        
    end
    
    specgramc.(touch{ff}).win=window;%include the window so you know what was run
    specPower.(touch{ff}) = st;  %load the mean of the S
    
    %add the t and f so you can make these graphs later.
    specgramc.(touch{ff}).t=tplot;
    specgramc.(touch{ff}).f=f;
    
    %%
    if ~quickrun
        if gridplot
            figtitle=['Power across the grid ',  blc.SourceBasename, ' ', ecog.evtNames{ff}];
            figure('Name', figtitle, 'units', 'normalized', 'outerposition', [0 0 1 1]) %x bottom left, y bottom left, x width, y height
            [rw,cl]=size(xch2plot);
            ch2plot_order=xch2plot'; %needs to be flipped in order to go in the same order as the subplot
            %"normalize" the colors next to each other, it excludes outliers
            %(anything over 2sd from the mean)
            for ii=1:rw*cl
                mx(ii)=max(max(specgramc.(touch{ff}).(blc.ChannelInfo(ch2plot_order(ii)).Label)));
                mn(ii)=min(min(specgramc.(touch{ff}).(blc.ChannelInfo(ch2plot_order(ii)).Label)));
            end
            
            mx(isoutlier(mx))=[];
            mn(isoutlier(mn))=[];
            mxT=max(mx); mnT=min(mn);
            for ii=1:rw*cl
                
                subplot(rw,cl, ii);
                %im=imagesc(tplot,f, heatpow); axis xy;
                im=imagesc(tplot,f, specgramc.(touch{ff}).(blc.ChannelInfo(ch2plot_order(ii)).Label)); axis xy;
                ax=gca;
                caxis([mnT mxT])
                ax.Position(3)=0.19;
                ax.Position(1)=ax.Position(1)-0.03;
                xlim([plot_buff(1) plot_buff(2)]); %only show the plot buffer pre and buffer post
                title([' Channel ', blc.ChannelInfo(ch2plot_order(ii)).Label])
                colorbar;
                colormap(inferno(100));
                
            end
            if saveplots
                if ~kluge
                    plt.save_currfig('SavePath', blc)
                elseif kluge %for one specific patient, can delete after
                    filespot='\\striatum\Data\neural\incoming\unsorted\rancho\BROWN_SHAMIKA@ResearchRealTouch';
                    plt.save_currfig('SavePath', filespot)
                end
                
            end
        end
    end
end
specPower.win=window;



end % END