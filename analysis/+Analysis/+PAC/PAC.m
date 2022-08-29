function [mn_z, plt_angle] = PAC(data, varargin)
%Pac Basic fxn for phase amplitude coupling, based on Samie 2017
%   Basic start for time-resolved pac
%   Based on Samiee, Soheila, and Sylvain Baillet (2017). Time-resolved
%   phase-amplitude coupling in neural oscillations. NeuroImage, 59,
%   270-279.
%   Basic formula Envelope_fastoscillation*e^i*phase_slowoscillation


%things to do
% 1) get an average across the different radian spots, so you can plot one mean/ch
% 2) get a spectrogram
% 3) find the troughs


%Example:
%     [z]=Analysis.DelayedReach.LFP.PAC(sample_d);
[varargin, params] = util.argkeyval('params',varargin,[]); %parameters for spectrogram
[varargin, fs] = util.argkeyval('fs',varargin,2000); %sampling rate
[varargin, high_freq] = util.argkeyval('high_freq',varargin,[65 150]); %high frequency amplitude component
[varargin, low_freq] = util.argkeyval('low_freq',varargin,[15 30]); %low frequency phase component
[varargin, spect_freq] = util.argkeyval('spect_freq',varargin,[0 200]); %range for your spectrogram frequency
[varargin, window] = util.argkeyval('window',varargin,[0.2, 0.005]); %window for spectrogram
[varargin, channels] = util.argkeyval('channels',varargin,(1:size(data,2))); %if you want to specify only certain channels, can also do (4,5,8)
[varargin, needsfilter] = util.argkeyval('needsfilter',varargin,1); %option to comb filter the data

util.argempty(varargin); % check all additional inputs have been processed

z=zeros(size(data,1), size(data,2));
modi=[];


%set up parameters for the spectrogram
if nargin == 1 || isempty (params)
    params = struct;
    params.Fs = fs;   % in Hz
    params.fpass = spect_freq;     % [minFreqz maxFreq] in Hz
    params.tapers = [5 9]; %second number is 2x the first -1, and the tapers is how many ffts you do.
    params.pad = 1;
    %params.err = [1 0.05];
    params.err=0;
    params.trialave = 0; % average across trials
    params.win = window;   % size and step size for windowing continuous data
    params.bipolar=false;
    %params.readChan=[1 blc.ChannelInfo(end).ChannelNumber];    %don't
    %think I need this one
end

%cut channels not being used
data_ch=data(:,channels);


%option
if needsfilter
%notch filter
% Filter for 60 Hz noise and 120 Hz and 180 Hz
bsFilt1 = designfilt('bandstopiir','FilterOrder',2, ...
    'HalfPowerFrequency1',59,'HalfPowerFrequency2',61, ...
    'SampleRate',fs,'DesignMethod','butter');

bsFilt2 = designfilt('bandstopiir','FilterOrder',2, ...
    'HalfPowerFrequency1',119,'HalfPowerFrequency2',121, ...
    'SampleRate',fs,'DesignMethod','butter');

bsFilt3 = designfilt('bandstopiir','FilterOrder',2, ...
    'HalfPowerFrequency1',179,'HalfPowerFrequency2',181, ...
    'SampleRate',fs,'DesignMethod','butter');

data_ch = filtfilt(bsFilt1,data_ch); % filter raw data
data_ch = filtfilt(bsFilt2,data_ch);
data_ch = filtfilt(bsFilt3,data_ch);
end


%filter high freq
bandfilter_hf=designfilt('bandpassiir',...
           'DesignMethod','butter',...
           'FilterOrder',8,...
           'HalfPowerFrequency1',high_freq(1,1),...
           'HalfPowerFrequency2',high_freq(1,2),...
           'SampleRate',fs);

hf_bp_data=filtfilt(bandfilter_hf, data_ch);

%envelope
env_hf=abs(hilbert(hf_bp_data)); %it's possible you need to ' this signal

%filter low freq
bandfilter_lf=designfilt('bandpassiir',...
           'DesignMethod','butter',...
           'FilterOrder',8,...
           'HalfPowerFrequency1',low_freq(1,1),...
           'HalfPowerFrequency2',low_freq(1,2),...
           'SampleRate',fs);

lf_bp_data=filtfilt(bandfilter_lf, data_ch);

      
%angles
angle_lf=angle(hilbert(lf_bp_data));

%find the troughs and peaks
trghs=find(angle_lf > -pi+0.01); %returns the row that has that trough
pks=find(angle_lf  < pi+0.01); 


%run a series of bandpass filters to look at phase coupling in a spectrogram presentation

%NORMALIZE AND Z SCORE


%mod index (z)
z=env_hf.*exp(1i*angle_lf);

mxv=ceil(max(env_hf));

%Sort the values of env_hf based on the phase angle
%split values for 32 equal spaces for rank ordering
pisplit=pi/16;
pis=-pi:pisplit:pi-pisplit; 
sp_volt=linspace(0, 7); %100 spaced points
for ii=1:size(z,2) %channels
    idx=1;
    for jj=-pi:pisplit:pi-pisplit %go through each bin
        angle_hist(idx)=nnz(find(angle_lf(:,ii)>=jj  & angle_lf(:,ii)<=jj+pisplit));        
        temp=env_hf(find(angle_lf(:,ii)>=jj  & angle_lf(:,ii)<=jj+pisplit), ii); %get all env_hf amplitudes for each beta phase bin
        
        modi.cat_Ahg{ii}{idx}=temp; %ii=channels, idx=categories
        
        fitv=gamfit(temp); %get the gammafit parameters for that bin
        A=fitv(1); %alpha
        B=fitv(2); %beta
        idx2=1;
        for kk=0:mxv/100:mxv-mxv/100
            tmp(idx2,1)=nnz(temp>kk & temp<=kk+mxv/100); %take the frequency at each amp bin within each angle bin
            idx2=idx2+1;
        end
        
        modi.freqAmp{ii}{idx}=tmp;
        gamPdfAll(:,idx)=gampdf(sp_volt,A,B)'; %now create a gamma curve based on A, B, it's divorced from the data at this point
        modi.freqPDF{ii}{idx}=gamPdfAll;
        modi.plt_angle{ii}(idx,1)=jj+pisplit/2;
        idx=idx+1;
    end
    set(0, 'DefaultAxesFontSize', 22);
    figure
    plot(angle_hist, '.'); %show that it looks about uniform
    ylim([0 max(angle_hist)]);
     
    %run a chi2 test for a 'uniform' distribution
    bins=-pi:pisplit:pi; %32 bins, is the edges
    n=sum(angle_hist); %angle_hist is the observations, n is the number of observations
    expCounts=n/32*ones(32,1); %gives you the expected value for chi squared
    [modi.phaseA_stats{ii}(1,1), modi.phaseA_stats{ii}(1,2)]=chi2gof(angle_lf, 'Expected', expCounts, 'Edges', bins); %return the decision from chisquared
    figure
    polarplot3d(gamPdfAll, 'PolarGrid', {mxv 32}); %creates a polar plot
    colorbar;
    set(gca, 'View', [-0, 7]) %a pretty good view
end



figure
plot(plt_angle, abs(mn_z));
figure
plot(angle_lf, abs(z));
figure
plot(real(z), imag(z), '.');
xlabel('real'); ylabel('imaginary');
%plotting


%need angle(z), need to show it's a normal distribtion, this is the
%polar plot stuff of canolty, meaning plot histogram of angle(z) and it
%should look flat as an eyeball.  then need to make that polar plot with
%the heat map.












end