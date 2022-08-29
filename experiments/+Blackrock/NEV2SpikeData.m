function [SpikeData, FeatureDescription,FeatureInfo,FeatureInfoOrig]=NEV2SpikeData(SpikeInfo,NEV,useSortedUnits)

% [BinnedSpikes, FeatureDescription,FeatureInfo]=NEV2BinnedFeatures(SpikeInfo,NEV,useSortedUnits)
%  Part of the BlackRockUtilities Package
%  Converts NEV files into a binned time series.  If SpikeInfo,NEV
%  are input as cell arrays of length 2, this program will interpret the
%  inputs as
% INPUTS :
%           SpikeInfo  -    Either
%                                 1) A column vector of ElectrodeIDs to process
%                                 2) Column vectors of EletrodeIDs and
%                                       UnitIDs
%                                 3) SNR file
%           NEV           - NEV data structure or NEV file name
%           useSortedUnits - Specify whether to create a feature for each
%                            defined unit on a particular electrode (or to collapse across
%                            all threshold crossings on a single
%                            electrode.)

if nargin<2
    error('NEV2BinnedFeatures needs at least 3 arguements')
end

if nargin<3
    % default to creating a sepreate feature for each defined unit.
    % Otherwise, collapses all units on an electrode to a single feature
    useSortedUnits=1;
end

% check for multiple NSPs
InputAsCells=[iscell(SpikeInfo) iscell(NEV)];

% if one arguement is a cell, than all must be - verify
if any(InputAsCells) && ~all(InputAsCells)
    error('if one arguement is a cell, than all must be')
end

if iscell(NEV) & length(NEV)>1, % Multiple NSPs
    
    
    % if NEV file specified as string, read in the NEV file
    if ischar(NEV{1}),
        NEV1 = openNEV(NEV{1},'read','nomat','nosave');
        if isempty(NEV1); error('Invalid name for NEV file 1 : %s',NEV{1} ); end
    else
        NEV1=NEV{1};
    end
    if ischar(NEV{2}),
        NEV2 = openNEV(NEV{2},'read','nomat','nosave');
        if isempty(NEV2); error('Invalid name for NEV file 2 : %s',NEV{2} ); end
    else
        NEV2=NEV{2};
    end
    
    PedestalINDX=1; % First Pedestal
    [SpikeData1, FeatureDescription1,FeatureInfo1,FeatureInfoOrig1]=returnedBinnedSpikes(SpikeInfo{1},NEV1,useSortedUnits,PedestalINDX);
    
    PedestalINDX=2; % Second Pedestal
    [SpikeData2, FeatureDescription2,FeatureInfo2,FeatureInfoOrig2]=returnedBinnedSpikes(SpikeInfo{2},NEV2,useSortedUnits,PedestalINDX);
    
    
    SpikeData=[SpikeData1;SpikeData2];
    FeatureDescription=[FeatureDescription1,FeatureDescription2];
    FeatureInfo=[FeatureInfo1;FeatureInfo2];
    FeatureInfoOrig=[FeatureInfoOrig1;FeatureInfoOrig2];
else % only one NSP
    if iscell(NEV)
        NEV=NEV{1};SpikeInfo=SpikeInfo{1};
    end
    if ischar(NEV),
        NEV1 = openNEV(NEV,'read','nomat','nosave');
        if isempty(NEV1); error('Invalid name for NEV file : %s',NEV ); end
    else
        NEV1=NEV;
    end
    
    PedestalINDX=1;
    [SpikeData,FeatureDescription,FeatureInfo,FeatureInfoOrig]=returnedBinnedSpikes(SpikeInfo,NEV1,useSortedUnits,PedestalINDX);
end


function [SpikeData,FeatureDescription,FeatureInfo,FeatureInfoOrig]=returnedBinnedSpikes(SpikeInfo,NEV,useSortedUnits,PedestalINDX)
refDate=[2013 01 01 0 0 0]; % this is the reference date.  The number of days after this is appended to the spike info stuff

% Convert SpikeInfo into ElctrodeIDs and UnitIDs
if ischar(SpikeInfo); % SpikeInfo provided as SNR file
    SpikeInfo=Blackrock.SNRFile2FeatureList(SpikeInfo);
    ElectrodeIDs=SpikeInfo(:,1);
    UnitIDs=SpikeInfo(:,2);
    FeatureInfoOrig=SpikeInfo;
else
    FeatureInfoOrig=[];
    [nY,nX]=size(SpikeInfo);
    if nX==1||nY==1; % Only ElectrodeIDs specified
        ElectrodeIDs=ascol(SpikeInfo);
        nX=1; nY=length(ElectrodeIDs);
        UnitIDs=[];
        
    else % ElectrodeIDs and UnitIDs specified
        ElectrodeIDs=SpikeInfo(:,1);
        UnitIDs=SpikeInfo(:,2);
        
    end
end

[uniqueElectrodes]=unique(ElectrodeIDs);

if ~isempty(UnitIDs)
    
    for i=1:length(uniqueElectrodes)
        indxs=find(uniqueElectrodes(i)==ElectrodeIDs);
        AllUnitIDs{i}=UnitIDs(indxs);
    end
end

indx=0;

for i = 1:length(uniqueElectrodes)
    % disp(num2str(spikeChannels(:,i)));
    
    % search for spikes on this channel.
    curElec_SpikeINDXs = find(NEV.Data.Spikes.Electrode == uniqueElectrodes(i,1));
    curElecID=uniqueElectrodes(i,1);
    %          if curElecID==66 && isempty(curElec_SpikeINDXs), keyboard, end
    if ~isempty(curElec_SpikeINDXs)
        
        % spikes = nev.Data.Spikes.TimeStamp(curElec_SpikeINDXs);
        elecSpikeTimes = NEV.Data.Spikes.TimeStamp(curElec_SpikeINDXs);
        elecUnits = NEV.Data.Spikes.Unit(curElec_SpikeINDXs);
        elecWaveForms = NEV.Data.Spikes.Waveform(:,curElec_SpikeINDXs);
        
        if ~isempty(UnitIDs)
            curElectrodeUnitIDs=AllUnitIDs{i}';
        else
            curElectrodeUnitIDs = unique(elecUnits);
        end
        
        
        %         if length(unique(elecUnits))>1
        %         keyboard
        %         end
        
        
        %% bin spike times
        % this bins it by the resolution of the behavioral data, however the bins
        % could be widened to e.g. 100 ms for a cruder estimate of firing rate.
        if useSortedUnits
            
       
            for curUnit=curElectrodeUnitIDs
                indx=indx+1;
           
                
                
                FeatureInfo(indx,:)=[curElecID curUnit PedestalINDX];
                
                curUnitInds = find(elecUnits == curUnit);
                
                
                
                SpikeData{indx,1} = PedestalINDX;
                SpikeData{indx,2} = curElecID;
                SpikeData{indx,3} = curUnit;
                SpikeData{indx,4} = elecSpikeTimes(curUnitInds);
                SpikeData{indx,5} = elecWaveForms(:,curUnitInds);
                
                if isfield(NEV.Data.Spikes,'Quality')
                    try
                        Quality=NEV.Data.Spikes.Quality{curElecID}(curUnit);
                        SpikeData{indx,6}=Quality;
                    catch
                        %                         warning('Missing Quality - e:%d u:%d',curElecID,curUnitIDX)
                        SpikeData{indx,6}=nan;
                    end
                end
                
                if isfield(NEV.Data.Spikes,'UnitType')
                    try
                        Quality=NEV.Data.Spikes.UnitType{curElecID}(curUnit);
                        SpikeData{indx,8}=Quality;
                    catch
                        %                         warning('Missing Quality - e:%d u:%d',curElecID,curUnitIDX)
                        SpikeData{indx,8}=nan;
                    end
                end
                
                tmp=NEV.MetaTags.DateTimeRaw;
                SpikeData{indx,7} = etime([tmp([1 2 4]) 0 0 0],refDate)/60/60/24;
                
                
                FeatureDescription(indx)=Blackrock.makeFeatureDescriptions(NEV.ElectrodesInfo(curElecID), 'event', PedestalINDX,curUnit);
            end
        else
            
        
            curUnitIDX=0;
            for curUnit=curElectrodeUnitIDs
                indx=indx+1;
                curUnitIDX=curUnitIDX+1;
                
                
                FeatureInfo(indx,:)=[curElecID curUnit PedestalINDX];
                
                curUnitInds = find(elecUnits == curUnit);
                                
                SpikeData{indx,1} = PedestalINDX;
                SpikeData{indx,2} = curElecID;
                SpikeData{indx,3} = curUnit;
                SpikeData{indx,4} = elecSpikeTimes(curUnitInds);
                SpikeData{indx,5} = elecWaveForms(:,curUnitInds);
                SpikeData{indx,6}=nan;
                tmp=NEV.MetaTags.DateTimeRaw;
                SpikeData{indx,7} = etime([tmp([1 2 4]) 0 0 0],refDate)/60/60/24;
                
                FeatureDescription(indx)=Blackrock.makeFeatureDescriptions(NEV.ElectrodesInfo(curElecID), 'event', PedestalINDX,0);
            end
            
        end
        %         ChannelID{indx}=NEV.MetaTags.ChannelID(i);
    else
        if useSortedUnits && ~isempty(UnitIDs)
            curElectrodeUnitIDs=AllUnitIDs{i}';
            for curUnit=curElectrodeUnitIDs
                indx=indx+1;
                
                SpikeData{indx,1} = PedestalINDX;
                SpikeData{indx,2} = curElecID;
                SpikeData{indx,3} = curElectrodeUnitIDs;
                SpikeData{indx,4} = [];
                SpikeData{indx,5} = [];
                SpikeData{indx,6}=nan;
                tmp=NEV.MetaTags.DateTimeRaw;
                SpikeData{indx,7} = etime([tmp([1 2 4]) 0 0 0],refDate)/60/60/24;
                
                FeatureInfo(indx,:)=[curElecID curUnit PedestalINDX];
                FeatureDescription(indx)= Blackrock.makeFeatureDescriptions(NEV.ElectrodesInfo(i), 'event', PedestalINDX,curUnit);
            end
            
        else
            indx=indx+1;
            
            SpikeData{indx,1} = PedestalINDX;
            SpikeData{indx,2} = curElecID;
            SpikeData{indx,3} = uint8(255);
            SpikeData{indx,4} = [];
            SpikeData{indx,5} = [];
            SpikeData{indx,6}=nan; % Quality
            tmp=NEV.MetaTags.DateTimeRaw;
            SpikeData{indx,7} = etime([tmp([1 2 4]) 0 0 0],refDate)/60/60/24;
            SpikeData{indx,8}=nan; % UnitType
            
            FeatureInfo(indx,:)=[curElecID 0 PedestalINDX];
            FeatureDescription(indx)= Blackrock.makeFeatureDescriptions(NEV.ElectrodesInfo(i), 'event', PedestalINDX,0);
        end
    end
end

if any(cellfun(@length,SpikeData(:,3))>1);
    error('Unexpected number of units')
end

function y = ascol(x)
% ASCOL - Orient a matrix as a column
% function y = ascol(x)
% This is a functional form of x(:).  Useful when you can't use that notation.
% E.g., y = x(:,1:5), but as a vector.

y = x(:);

function y = asrow(x)
% ASCOL - Orient a matrix as a row
% function y = asrow(x)
% This is a functional form of x(:).'.  Useful when you can't use that notation.
% E.g., y = x(:,1:5), but as a vector.

y = x(:).';

