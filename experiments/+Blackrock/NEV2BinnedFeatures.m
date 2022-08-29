function [BinnedSpikes,FeatureDescription,FeatureInfo,FeatureInfoOrig]=NEV2BinnedFeatures(SpikeInfo,NEV,cbTime,useSortedUnits)

% [BinnedSpikes, FeatureDescription,FeatureInfo]=NEV2BinnedFeatures(SpikeInfo,NEV,cbTime,useSortedUnits)
%  Part of the BlackRockUtilities Package
%  Converts NEV files into a binned time series.  If SpikeInfo,NEV,cbTime
%  are input as cell arrays of length 2, this program will interpret the
%  inputs as
% INPUTS :
%           SpikeInfo  -    Either
%                                 1) A column vector of ElectrodeIDs to process
%                                 2) Column vectors of EletrodeIDs and
%                                       UnitIDs
%                                 3) SNR file
%           NEV           - NEV data structure or NEV file name
%           cbTime        - specifies the edges into which the spike time
%                           are binned
%           useSortedUnits - Specify whether to create a feature for each
%                            defined unit on a particular electrode (or to collapse across
%                            all threshold crossings on a single
%                            electrode.)
%
% note that the last bin counts the number of occurences of a spike at the
% very last specified edge, not in between two edges (see help histc).

if nargin<3
    error('NEV2BinnedFeatures needs at least 3 arguements')
end

if nargin<4
    % default to creating a sepreate feature for each defined unit.
    % Otherwise, collapses all units on an electrode to a single feature
    useSortedUnits=1;
end

% check for multiple NSPs
InputAsCells=[iscell(SpikeInfo) iscell(NEV) iscell(cbTime)];

% if one arguement is a cell, than all must be - verify
if any(InputAsCells) && ~all(InputAsCells)
    error('if one arguement is a cell, than all must be')
end

if iscell(NEV), % Multiple NSPs
    
    %     check the size of cbTimes to make sure they are of the same length -
    %     otherwise we will fail to combine the data from the two NSPs into a
    %     single Feature vector
    if length(cbTime{1})~=length(cbTime{2});
        error('Length of cbTimes for the two arrays must be the same')
    end
    
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
    [BinnedSpikes1, FeatureDescription1,FeatureInfo1,FeatureInfoOrig1]=returnedBinnedSpikes(SpikeInfo{1},NEV1,cbTime{1},useSortedUnits,PedestalINDX);
    BinnedSpikes1=cell2mat(BinnedSpikes1');
    PedestalINDX=2; % Second Pedestal
    [BinnedSpikes2, FeatureDescription2,FeatureInfo2,FeatureInfoOrig2]=returnedBinnedSpikes(SpikeInfo{2},NEV2,cbTime{2},useSortedUnits,PedestalINDX);
    BinnedSpikes2=cell2mat(BinnedSpikes2');
    
    BinnedSpikes=[BinnedSpikes1;BinnedSpikes2];
    FeatureDescription=[FeatureDescription1,FeatureDescription2];
    FeatureInfo=[FeatureInfo1;FeatureInfo2];
    FeatureInfoOrig=[FeatureInfoOrig1;FeatureInfoOrig2];
else % only one NSP
    if ischar(NEV),
        NEV1 = openNEV(NEV,'read','nomat','nosave');
        if isempty(NEV1); error('Invalid name for NEV file : %s',NEV ); end
    else
        NEV1=NEV;
    end
    
    PedestalINDX=1;
    [BinnedSpikes, FeatureDescription,FeatureInfo,FeatureInfoOrig]=returnedBinnedSpikes(SpikeInfo,NEV1,cbTime,useSortedUnits,PedestalINDX);
    BinnedSpikes=cell2mat(BinnedSpikes');
end


function [BinnedSpikes, FeatureDescription,FeatureInfo,FeatureInfoOrig]=returnedBinnedSpikes(SpikeInfo,NEV,cbTime,useSortedUnits,PedestalINDX)

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
        %nX=1; nY=length(ElectrodeIDs);
        UnitIDs=[];
        
    else % ElectrodeIDs and UnitIDs specified
        ElectrodeIDs=SpikeInfo(:,1);
        UnitIDs=SpikeInfo(:,2);
        
    end
end

[uniqueElectrodes]=unique(ElectrodeIDs);

if ~isempty(UnitIDs)
    
    for i=1:length(uniqueElectrodes)
        AllUnitIDs{i}=UnitIDs(uniqueElectrodes(i)==ElectrodeIDs);
    end
end

indx=0;

for i = 1:length(uniqueElectrodes)
    % disp(num2str(spikeChannels(:,i)));
   
    % search for spikes on this channel.
    curElec_SpikeINDXs = NEV.Data.Spikes.Electrode == uniqueElectrodes(i,1);
    curElecID=uniqueElectrodes(i,1);
    

    
    if nnz(curElec_SpikeINDXs)>0
        
        % spikes = nev.Data.Spikes.TimeStamp(curElec_SpikeINDXs);
        elecSpikeTimes = NEV.Data.Spikes.TimeStamp(curElec_SpikeINDXs);
        elecUnits = NEV.Data.Spikes.Unit(curElec_SpikeINDXs);
        if ~isempty(UnitIDs)
            curElectrodeUnitIDs=AllUnitIDs{i}';
        else
            curElectrodeUnitIDs = unique(elecUnits);
        end
        
        
        
        
        %% bin spike times
        % this bins it by the resolution of the behavioral data, however the bins
        % could be widened to e.g. 100 ms for a cruder estimate of firing rate.
        if useSortedUnits
            for curUnit=curElectrodeUnitIDs
                indx=indx+1;
                
                FeatureInfo(indx,:)=[curElecID curUnit PedestalINDX];
                unitSpikes = elecSpikeTimes(elecUnits == curUnit);
                
                [binned,~] = histc(unitSpikes,cbTime);
                BinnedSpikes{indx}=binned(:)';
                
                FeatureDescription(indx)=Blackrock.makeFeatureDescriptions(NEV.ElectrodesInfo(curElecID), 'event', PedestalINDX,curUnit);
            end
        else
            indx=indx+1;
            FeatureInfo(indx,:)=[curElecID 0 PedestalINDX];
            [binned,~] = histc(elecSpikeTimes,cbTime);
            BinnedSpikes{indx}=binned(:)';
            
            FeatureDescription(indx)=Blackrock.makeFeatureDescriptions(NEV.ElectrodesInfo(curElecID), 'event', PedestalINDX,0);
        end
        %         ChannelID{indx}=NEV.MetaTags.ChannelID(i);
    else
        if useSortedUnits && ~isempty(UnitIDs)
            curElectrodeUnitIDs=AllUnitIDs{i}';
            for curUnit=curElectrodeUnitIDs
                indx=indx+1;
                BinnedSpikes{indx}=0*cbTime(:)';
                FeatureInfo(indx,:)=[curElecID curUnit PedestalINDX];
                FeatureDescription(indx)= Blackrock.makeFeatureDescriptions(NEV.ElectrodesInfo(i), 'event', PedestalINDX,curUnit);
            end
            
        else
            indx=indx+1;
            BinnedSpikes{indx}=0*cbTime(:)';
            FeatureInfo(indx,:)=[curElecID 0 PedestalINDX];
            FeatureDescription(indx)= Blackrock.makeFeatureDescriptions(NEV.ElectrodesInfo(i), 'event', PedestalINDX,0);
        end
    end
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

