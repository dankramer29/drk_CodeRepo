function [ this, specPower, specgramc, est_pch, filtbandPower, filtbandPowerdB, itiCheckResults, filtITI ] = artsens_proc( blc, varargin )
%Analysis.ArtSens_proc script for running through the altered art_sens functions
%michelle made
%   This is going to be the event names etc with the time stamps to use
%   with blc.
%


%  Varargin
%see below
%     


%MINI layout
% 57    49    41    33    25    17     9     1
% 58    50    42    34    26    18    10     2
% 59    51    43    35    27    19    11     3
% 60    52    44    36    28    20    12     4
% 61    53    45    37    29    21    13     5
% 62    54    46    38    30    22    14     6
% 63    55    47    39    31    23    15     7
% 64    56    48    40    32    24    16     8
%Example
%   [ thisJO2, specPowerJO2,specgramcJO2, elec_pJO2 ] = Analysis.ArtSens.Analysis.ArtSens_proc( blc, 'ch', [1 20], 'itiWin', 1.5, 'prepost', [0.5 2]);
%

[varargin, data]=util.argkeyval('data',varargin,[]);
[varargin, ch]=util.argkeyval('ch',varargin, [1:blc.ChannelInfo(end).ChannelNumber]); %which channels to run

%NOTE if you change the window to smaller (e.g. 0.05, you should change the pad to 2
%and if it's big 0.5, then to 1 or 0)
[varargin, window]=util.argkeyval('window',varargin, [0.2 0.005]); %control the window in the spectrogram 
[varargin, plot_buff]=util.argkeyval('plot_buff',varargin,[0.3 0.5]); %this will dictate how much of the graph before 0 and after end time to show (e.g. time window total (prepost) is 0.5 to 2 and you only care about 0-1.5, give a [0.2 0.2] s buffer so it shows -0.2 to 1.7)
[varargin, pad]=util.argkeyval('pad',varargin,1); %control the pad in the spectrogram
[varargin, frequency]=util.argkeyval('frequency',varargin,[0 125]); %control the frequency min and max
[varargin, itiWin]=util.argkeyval('itiWin',varargin, [1.5]); %how big you want the iti to be.
[varargin, prepost]=util.argkeyval('prepost',varargin, [0.5 2]);%prepost(1) is the amount before time 0 (touch) that you want and prepost(2) is the time after time 0 you want.  This is where to build in your buffer, typically of .5s


[varargin,dB] = util.argkeyval('dB',varargin, true); %turn on or off the 10*log10 adjustment for the normalized

[varargin, gridplot] = util.argkeyval('gridplot',varargin, false); %if you want to plot in a gridlayout
%these only matter if gridplot==true
[varargin, userinput] = util.argkeyval('userinput',varargin, true); %if gridplot==true, and userinput==true, will prompt you to pick the channels you want. if false, then you need to enter them yourself as channels2plot
[varargin, xch2plot] = util.argkeyval('xch2plot',varargin, ch); %if userinput false, then xch2plot takes the input channels or does all by default
[varargin, gridtype] = util.argkeyval('gridtype',varargin, 1); %types of grids, options are mini=1 and 4x5=2 at this time
[varargin, orientation] = util.argkeyval('orientation',varargin, 1); %the orientation on the brain that the tails are pointing
%the orientation on the brain that the tails are pointing, this is done with the idea that you are looking at the grid on a 3d represenation of the brain
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
[varargin, saveplots] = util.argkeyval('saveplots',varargin, true);%gets the channels to plot in the gridmap from the user gui input or hand input from arsens_proc
[varargin, quickrun] = util.argkeyval('quickrun',varargin, true); %make true if you don't want to graph or run through the stats, just to get the numbers output
[varargin, recordingday] = util.argkeyval('recordingday',varargin, 1); 
[varargin, origintime] = util.argkeyval('origintime',varargin, blc.DataStartTime); %make true if you don't want to graph or run through the stats, just to get the numbers output


[varargin, kluge]=util.argkeyval('kluge',varargin, false); %only true if doing SB
util.argempty(varargin); % check all additional inputs have been processed


itiCheckResults=struct;

if length(ch)==2
    ch=ch(1):ch(2);
    disp('channels should be entered as individual channels, or as the first and the last, e.g. ch=[1,2,3,4,9,10,11,14]; or ch=[1 20] which will be represented as ch=[1:20];')
end
if gridplot
    if userinput
        ch2plot=plot.grid_subplot('gridtype', gridtype, 'blc', blc, 'orientation', orientation);
    else
        ch2plot=plot.grid_subplot('gridtype', gridtype, 'blc', blc, 'orientation', orientation, 'xch2plot', xch2plot); %allow manual entering of channels
    end
    checkmemb=ismember(ch2plot, ch);
    assert(nnz(checkmemb)==numel(ch2plot),...
        'channels to plot together are not the same as channels entered, make sure all channels desired in the gridplot are included in the channels being run');

else
    ch2plot=ch;
    
end


%set up the start times
dt=origintime;
dtend=blc.DataEndTime;
if dtend>(dt + day(1))
    
    %inquire which recording day is relevant
    if isempty(recordingday)
        recordingday=inputdlg('total recording >24h, which recording day did this start on? (if unsure, assume first)');
    end 
end


tt=tic;
this=struct;

if isempty(data)
    if ~kluge
    data=blc.read; %based on the grid map
    elseif kluge %if this gets left in, it's for one specific patient, can be deleted
        obj=EDFData('\\striatum\Data\neural\incoming\unsorted\rancho\BROWN_SHAMIKA@ResearchRealTouch\BROWN~ SHAMIK.edf');
        data = getData(obj, [1 5058812], 1:102);
    end
end

% adjust for mv or uv, adjust to mv
unts=blc.ChannelInfo(1).AnalogUnits;
if ~strcmp(unts,'mV')
    data=data/1000;
    fprintf('units not mV, units %s converted to mV by dividing by 1000', unts);
end

[this.evtData,this.evtTimeStamp,this.evtNames] = Analysis.ArtSens.get_event_data(blc, data);

[this.rawVt] = Analysis.ArtSens.parse_RawData(this, data, blc, 'dt', dt, 'recordingday', recordingday);
%breaks them up into iti and touches based on the start and end (not based
%on the amount you want although if you want more than it's going to be, it
%adds that (so if you want 2s after touch and trial is only 1s, it adds 1s
%of iti).  The creating of the same sized windows happens in freqandPower
[this.trialdata, this.iti, this.numTrials, this.End] = Analysis.ArtSens.parse_Trials(this, blc, 'prepost', prepost, 'Fs', blc.SamplingRate, 'dt', dt, 'recordingday', recordingday); 

prms=[];
%looks at the power in certain frequency bands and the heatmaps, currently
%GPU optimized.
 [specPower, specgramc, est_pch, filtbandPower, filtbandPowerdB, filtITI] = Analysis.ArtSens.freqbandPower(blc, this, ch, prms,...
   'window', window, 'pad', pad, 'frequency', frequency, 'specWin', itiWin, 'prepost', prepost, 'dB', dB, 'plot_buff', plot_buff,...
    'gridplot', gridplot, 'gridtype', gridtype, 'orientation', orientation, 'userinput', userinput, 'xch2plot', ch2plot, 'kluge', kluge, 'quickrun', quickrun);


%check the ITI against the first 200 and 300 ms to make sure they aren't
%significantly different using a wilcox rank sum
%[itiCheckResults200, ctctwo]=Analysis.ArtSens.itiCheck(filtITI, specgramc.LightTouch.t, 'ms', 200);
%[itiCheckResults300, ctcthree]=Analysis.ArtSens.itiCheck(filtITI, specgramc.LightTouch.t, 'ms', 300);
% 
% itiCheckResults.two=itiCheckResults200;
% itiCheckResults.channels200=ctctwo;
% itiCheckResults.three=itiCheckResults300;
% itiCheckResults.channels300=ctcthree;

toc(tt)

end

