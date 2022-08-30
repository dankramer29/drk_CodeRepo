function [pcaProc] = pcaSpkBand(spkSmoothed, bandPower, lbls)
%function to fit in procDataX(CO, GT, HeadM, etc)
%   gets a pca and analyzes the peaks

%Inputs
% spkSmoothed- spike smoothed data using Analysis.BasicDataProc.spikeRate output
% bandPower- classic or other band, smoothed power analysis using Analysis.BasicDataProc.dataPrep output
% lbls- typically can input fields(bandPower)

%Outputs 
%     Per Trial
%     PCA of spikes in the time (rows) and by the first 25 PCs (only
%     returns rows-1 PCs)
%       Peaks for the time period in this order Max Start, Max, Min start, Min
%       Then same for the different bands, across all channels
%     Averaged across all trials
%       PCA of the spikes across all trials
%       PCA of the bands across all trials



for nn=1:length(lbls)
    for ii=1:size(bandPower,2)
        [~, spikeTemp(:, :, ii)]=pca(spkSmoothed{ii}); %time x pca/ch x trial, only returns 25 PCAs however, despite 96 channels due to some math thing where it is time bins-1 number of pcs.
        if nn==1
            pcaProc(ii).spikeSmooth=spikeTemp(:, :, ii);
            pcaProc(ii).(strcat('spikeSmooth', 'Peaks'))=Analysis.BasicDataProc.specChange(spikeTemp(:,:,ii)); %find the peaks
        end
        [~, bandTemp(:,:,ii)]=pca(squeeze(bandPower{ii}(:,nn,:))); %time x pca/ch x trial
        pcaProc(ii).(lbls{nn})=bandTemp(:,:,ii);
        pcaProc(ii).(strcat(lbls{nn}, 'Peaks'))=Analysis.BasicDataProc.specChange(bandTemp(:,:,ii)); %find the peaks
    end
    
    pcaProc(1).(strcat(lbls{nn}, 'TrialMean'))=nanmean(bandTemp,3); %mean across all trials
    pcaProc(1).(strcat(lbls{nn}, 'SE'))=nanstd(bandTemp, [], 3)/sqrt(size(bandTemp,3));
    if nn==length(lbls)
        pcaProc(1).(strcat('spikeSmooth', 'TrialMean'))=nanmean(spikeTemp,3);
        pcaProc(1).(strcat('spikeSmooth', 'TrialSE'))=nanstd(spikeTemp, [], 3)/sqrt(size(spikeTemp,3));
    end    
end


end

