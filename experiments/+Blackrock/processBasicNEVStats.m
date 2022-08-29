function   [numUnits,channels,units,FiringRate,quality] = processBasicNEVStats(NEV,varargin)

% thresholds on what to return
[varargin,minRate] = util.ProcVarargin(varargin,'minRate',0);
[varargin,minQuality] = util.ProcVarargin(varargin,'minQuality',0);
util.ProcVarargin(varargin);

% if file (not
if ischar(NEV)
    if ~exist(NEV)
        error(sprintf('"%s" Does not exist'))
    end
    
    if strcmp(lower(NEV(end-2:end)),'nev')
        %NEV file
        NEV=openNEV(NEV,'read','nomat','nosave');
    elseif strcmp(lower(NEV(end-2:end)),'mat')
        % GMM sorted object
        tmp=load(NEV);
        NEV=tmp.NEV;
    else
        %not recognizable file type
        error(sprintf('"%s" is not a recogized file type - expecting .nev or .mat'))
    end
    
end


[SpikeData]=Blackrock.NEV2SpikeData(1:96,NEV,1);
DataDurationSec=NEV.MetaTags.DataDurationSec;
% remove invalid data based on inputs

NoiseIDX=[SpikeData{:,3}]==255; NoiseIDX=NoiseIDX(:);
LowFRIDX=(cellfun(@length,SpikeData(:,4))/DataDurationSec)<minRate;LowFRIDX=LowFRIDX(:);
LowQIDX=[SpikeData{:,6}]<minQuality;LowQIDX=LowQIDX(:);


SpikeData([NoiseIDX | LowFRIDX| LowQIDX],:)=[];


NSpikes=cellfun(@length,SpikeData(:,4));

FiringRate=NSpikes/DataDurationSec;
quality=[SpikeData{:,6}];
channels=[SpikeData{:,2}];
units=[SpikeData{:,3}];

numUnits=length(NSpikes);
FiringRate=FiringRate(:);
quality=quality(:);
channels=channels(:);
units=units(:);

