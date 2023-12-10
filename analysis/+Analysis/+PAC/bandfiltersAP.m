function [bandfilterAmp, bandfilterPhase, bandfilterP, bandfilterS, bandfilterC] = bandfiltersAP(fs, varargin)
%bandfiltersAP creates a series of band filters with options to do it once,
%or do it for two different sets of bands as in Phase Amplitude Coupling

%NOTE: this is IIR, and for phase stuff, UCSF uses FIR, so use eegfiltFIR.m,
%however, need long

%   inputs
%    AmpFreq_BandWidth= only one frequency bandwidth is required, rest are optional.  Default is 4 hz bands
%    Amp is the higher frequency bands, phase is the lower
%    fs= sampling frequency
%
%
%     outputs
%     bandfiltersA= the first set of band filters
%     bandfiltersP= optional set of band filters
%     bandfiltersS= optional set of band filters

%     bandfilterC= optional set of classic bands, to run do this:                 [~, ~, ~, bandfilterBroad]=Analysis.PAC.bandfiltersAP(Freq_BandWidth, fs, 'AmpFreqVectorRun', false, 'PhaseFreq', false, 'SubBand', false, 'ClassicBand', true); %create the band filters
%create the band filters
[varargin, nerdcoPACFilter] = util.argkeyval('nerdcoPACFilter',varargin, true);  % to run the bandfilters for nerdcoPAC WILL NEED TO ADJUST THE NEXT OPTION SO CAN DO BOTH.
[varargin, AmpFreqVectorRun] = util.argkeyval('AmpFreqVectorRun',varargin, false);  % to run the AmpFreqVector turn false if you just want the classic bands and make classic band true

%     bandfilterC= optional set of classic bands, to run do this:         [~, ~, ~, bandfilterBroad]=Analysis.PAC.bandfiltersAP(2, fs, 'ClassicBand', true); %create the band filters
[varargin, filterOverlap] = util.argkeyval('filterOverlap',varargin, 0);  % step the filter through. Different than the band widths of the filters, i.e. if 1, will have lots of overlap.

[varargin, AmpFreq_BandWidth] = util.argkeyval('AmpFreq_BandWidth',varargin, 2);  % amplitude frequency band width to create the bandwidths around
[varargin, MaxAmpFreq] = util.argkeyval('MaxAmpFreq',varargin, 100);  % maximum Amplitude frequency for your bands, amplitude being the higher frequency bands
[varargin, MinAmpFreq] = util.argkeyval('MinAmpFreq',varargin, 10);  % minimium Amplitude frequency for your bands
%%
[varargin, PhaseFreq] = util.argkeyval('PhaseFreq',varargin, false);  % run separate phase filtering for the phases in PAC, if the filters are not for PAC and used the same for both phase and amp, don't need it.
[varargin, PhaseFreq_BandWidth] = util.argkeyval('PhaseFreq_BandWidth',varargin, 10);  % phase frequency band width
[varargin, MaxPhaseFreq] = util.argkeyval('MaxPhaseFreq',varargin, 30);  % maximum phase frequency to run PAC to
[varargin, MinPhaseFreq] = util.argkeyval('MinPhaseFreq',varargin, 1);  % maximum phase frequency to run PAC to
%%
[varargin, SubBand] = util.argkeyval('SubBand',varargin, false);  % the narrow beta range changes plotted
[varargin, SubBandRange] = util.argkeyval('SubBandRange',varargin, [15 17 24 26]);  % the narrow subband ranges

[varargin, doClassicBand] = util.argkeyval('doClassicBand',varargin, true);  % create the classic bands (delta 1-4 theta 4-8 alpha 8-13 beta 13-30 gamma 30-50 high gamma 50 to 200)
[varargin, classicBandRange] = util.argkeyval('classicBandRange',varargin, [1 4; 4 8; 8 13; 13 30; 30 50; 50 200]);  % create the classic bands (delta 1-4 theta 4-8 alpha 8-13 beta 13-30 gamma 30-50 high gamma 50 to 200, but can be adjustable)

[varargin, SubBand] = util.argkeyval('SubBand',varargin, true);  % the narrow beta range changes plotted
[varargin, SubBandRange] = util.argkeyval('SubBandRange',varargin, [15 17 24 26]);  % the narrow subband ranges


%%
util.argempty(varargin); % check all additional inputs have been processed

bandfilterAmp= struct;
bandfilterPhase = struct;
bandfilterA= struct;
bandfilterP= struct;
bandfilterS= struct;
bandfilterC= struct;



%% filters for nerdcoPAC
if nerdcoPACFilter
    AmpFreqVector = [MinAmpFreq:AmpFreq_BandWidth:MaxAmpFreq]; %can start with 10:4:200
    lbl = cell(1);
    for ii=1:length(AmpFreqVector)-1
       Af1 = AmpFreqVector(ii)-filterOverlap;
        Af2 = AmpFreqVector(ii+1);
        if Af1 <= 0
            Af1 = 1;
        end
        if Af2 <= 0
            Af2 = 1;
        end
        lbl{1} = strcat('filter', num2str(Af1), 'to', num2str(Af2));
        bandfilterAmp.(lbl{1})=designfilt('bandpassfir','FilterOrder',100,'CutoffFrequency1',Af1,'CutoffFrequency2',Af2, 'SampleRate',fs);
    end

    if PhaseFreq
        PhaseFreqVector = [MinPhaseFreq:PhaseFreq_BandWidth:MaxPhaseFreq]; %low freq
        lbl = cell(1);
        for ii=1:length(PhaseFreqVector)-1
            Af1 = PhaseFreqVector(ii)-filterOverlap;
            Af2 = PhaseFreqVector(ii+1);
            if Af1 <= 0
                continue
            end
            lbl{1} = strcat('filter', num2str(Af1), 'to', num2str(Af2));
            bandfilterPhase.(lbl{1})=designfilt('bandpassfir','FilterOrder',100,'CutoffFrequency1',Af1,'CutoffFrequency2',Af2, 'SampleRate',fs);
        end
    end
end
%%
if AmpFreqVectorRun
    AmpFreqVector = [MinAmpFreq:AmpFreq_BandWidth:MaxAmpFreq]; %can start with 10:4:200
    lbl = cell(1);
    for ii=1:length(AmpFreqVector)
        Af1 = AmpFreqVector(ii)-AmpFreq_BandWidth/2;
        Af2 = AmpFreqVector(ii)+AmpFreq_BandWidth/2;
        if Af1 <= 0
            Af1 = 1;
        end
        if Af2 <= 0
            Af2 = 1;
        end
        lbl{1} = strcat('filter', num2str(Af1), 'to', num2str(Af2));
        bandfilterA.(lbl{1})=designfilt('bandpassiir',...
            'DesignMethod','butter',...
            'FilterOrder',8,...
            'HalfPowerFrequency1',Af1,...
            'HalfPowerFrequency2',Af2,...
            'SampleRate',fs);
    end
%THIS IS THE EXACT SAME SET OF FILTERS, PROBABLY WANTED TO DO A
%BANDFILTERB? CAN REEVALUATE LATER
    AmpFreqVector = [MinAmpFreq:AmpFreq_BandWidth:MaxAmpFreq]; %can start with 10:4:200
    lbl = cell(1);
    for ii=1:length(AmpFreqVector)
        Af1 = AmpFreqVector(ii)-AmpFreq_BandWidth/2;
        Af2 = AmpFreqVector(ii)+AmpFreq_BandWidth/2;
        if Af1 <= 0
            Af1 = 1;
        end
        if Af2 <= 0
            Af2 = 1;
        end
        lbl{1} = strcat('filter', num2str(Af1), 'to', num2str(Af2));
        bandfilterA.(lbl{1})=designfilt('bandpassiir',...
            'DesignMethod','butter',...
            'FilterOrder',8,...
            'HalfPowerFrequency1',Af1,...
            'HalfPowerFrequency2',Af2,...
            'SampleRate',fs);
    end
end

%% if running a second set of band filters
if PhaseFreq
    PhaseFreqVector = [MinPhaseFreq:PhaseFreq_BandWidth:MaxPhaseFreq];

    for jj=1:length(PhaseFreqVector)
        Pf1 = PhaseFreqVector(jj) - PhaseFreq_BandWidth/2;
        Pf2 = PhaseFreqVector(jj) + PhaseFreq_BandWidth/2;
        if Pf1 <= 0
            Pf1 = 1;
        end
        if Pf2 <= 0
            Pf2 = 1;
        end
        lbl{1} = strcat('filter', num2str(Pf1), 'to', num2str(Pf2));
        bandfilterP.(lbl{1})=designfilt('bandpassiir',...
            'DesignMethod','butter',...
            'FilterOrder',8,...
            'HalfPowerFrequency1',Pf1,...
            'HalfPowerFrequency2',Pf2,...
            'SampleRate',fs);
    end
end

if SubBand
    for kk=1:length(SubBandRange)/2
        Pf1 = SubBandRange(kk*2-1);
        Pf2 = SubBandRange(kk*2);
        lbl{1} = strcat('filter', num2str(Pf1), 'to', num2str(Pf2));
        bandfilterS.(lbl{1})=designfilt('bandpassiir',...
            'DesignMethod','butter',...
            'FilterOrder',8,...
            'HalfPowerFrequency1',Pf1,...
            'HalfPowerFrequency2',Pf2,...
            'SampleRate',fs);
    end
end

if doClassicBand
    for kk=1:size(classicBandRange, 1)
        Pf1 = classicBandRange(kk, 1);
        Pf2 = classicBandRange(kk, 2);
        lbl{1} = strcat('filter', num2str(Pf1), 'to', num2str(Pf2));
        bandfilterC.(lbl{1})=designfilt('bandpassiir',...
            'DesignMethod','butter',...
            'FilterOrder',8,...
            'HalfPowerFrequency1',Pf1,...
            'HalfPowerFrequency2',Pf2,...
            'SampleRate',fs);
    end
end

