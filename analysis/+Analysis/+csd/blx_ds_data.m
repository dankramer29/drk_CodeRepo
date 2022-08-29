function [ ds_ecogf, dsrt ] = blx_ds_data( ecog, blc, varargin )


%blx_ds_data Downsample the raw data from the output of blc.read
%   Gives an output of the downsampled raw data.  Uses an antialiasing
%   filter and comb filter at 60 Hz.

%   Basic use 
%       blc=BL.BLcReader('file name');
%       ecog=blc.read('time', [st end], 'channels', ch1:chend);  %can change the time or the channesl
%       [ ds_ecog, dsrt ] = csd.blx_ds_data( ecog, blc, 'newfs', [400], 'fltr', [60]);

%       blc=BL.BLcReader('DJOKOVIC~ AIDA_7c3230db-7a93-49bc-9acd-540626c64310.eeg.blc');
%       ecog=blc.read('channels', 14:18); 
%       [ ds_ecog, dsrt ] = csd.blx_ds_data( ecog, blc, 'newfs', [400], 'fltr', [60]);
%       

%

%{
CURRENTLY WORKS 6/21. HAS SET UP FOR NOT DOWNSAMPLING IF THE NEW RATE IS
TOO CLOSE TO THE OLD (ROUNDS TO 1) AND NO ANTIALIASING FILTER IN THAT CASE
%   Inputs:
        %ecog                    %cell array of n-by-k where n is the time
        start to finish, which is selected in making the ecog file

        %blc                     %the blc object handle, so it will contain
        the sampling rate

        %varargin (can come from params in blx_csd):
        
            %newfs                   % new frequency that you want the data to
            be sampled at, so 400 will give you 400Hz downsample rate, allowing
            for looking up to 200Hz

            %fltr                    % what you want to filter out, automatic is
            60 Hz
        
        	
    Output
        ds_ecog- will give a cell array of downsampled bytes in the first
        cell and downsampled 
%}



%%

%check if downsaple rate is entered
idx = find(strcmpi(varargin,'newfs'),1);
if ~isempty(idx)
    newfs = varargin{idx+1};
    varargin(idx:idx+1) = [];
else
    newfs=blc.SamplingRate;
end



%check if comb filter is entered, but default is 60 Hz
idx = find(strcmpi(varargin,'fltr'),1);
if ~isempty(idx)
    fltr = varargin{idx+1};
    varargin(idx:idx+1) = [];
else
    fltr=60;
end

%%
%set up the flag filter and the sampling rate as well as the new sampling
%rate
fs=blc.SamplingRate;
%create the new sampling rate.  In the case that the new desired sampling rate is not
%divisible evenly into the old (e.g. 2200/400), it will round it and use
%that new close sampling rate.  Also, if the rates are too close (e.g.
%500/400), will warn that it won't be used and the old rate is to be used.
fs2fs = round(fs/newfs);
dsrt = newfs;
%%

fltr=600/fltr;
%%
%set up the comb filter
ds_ecog=zeros(size(ecog));
ds_ecogf=zeros(size(ecog,1)/fs2fs,size(ecog,2));
%{
ds_frames=[];
ds_frames=ecog.vtFrames;
ds_TS=[];
ds_TS=ecog.vtTimeStamps;
%}
%%
d = fdesign.comb('notch','L,BW,GBW,Nsh',fltr,5,-4,4,600);
Hd=design(d);
%%

flagFilter = true;
if fs2fs==1
    flagFilter=false;
    warning(['sampling rates too similar, new sampling rate = old sampling rate, dsrt=' num2str(fs)]);
    dsrt=fs;
    
end
%%
if flagFilter
    filtobj = designfilt('lowpassiir',...
        'DesignMethod','butter',...
        'FilterOrder',8,...
        'HalfPowerFrequency',0.8*newfs/2,...
        'SampleRate', fs);
end
%%
% run the anti-aliasing filter
if flagFilter
    
    for kk=1:size(ecog,2)
        %the comb filter is filter, and the antialiasing is filtfilt
        ecog(:,kk) = filtfilt(filtobj,filter(Hd,ecog(:,kk)));
    end
  
    %the round/2 below is to start in the middle of the first few values to
    %better represent that "region" (as subsampling is just an arbitrary
    %value that represents that "region")
    ds_ecogf = ecog(round(fs2fs/2):fs2fs:end,:);
else
    
    ds_ecogf = ecog(round(fs2fs/2):fs2fs:end,:);
end




end




