%COPIED VERSION TO SIT IN THE EMBEDDED FOLDERS 

%Programmed by Adriano Tort, CBD, BU, 2008
% 
% Phase-amplitude cross-frequency coupling measure:
%
% [MI,MeanAmp]=ModIndex_v2(Phase, Amp, position)
%
% Inputs:
% Phase = phase time series, so the point on the phase at each time point
% in the data
% Amp = amplitude time series, the envelope amplitude at each time point in
% the data
% position = phase bins (left boundary)
%
% Outputs:
% MI = modulation index (see Tort et al PNAS 2008, 2009 and J Neurophysiol 2010)
% MeanAmp = amplitude distribution over phase bins (non-normalized)
 
function [MI,MeanAmp]=ModIndex_v2(Phase, Amp, position)

nbin=length(position);  % we are breaking 0-360o in 18 bins, ie, each bin has 20o
winsize = 2*pi/nbin;
 
% now we compute the mean amplitude in each phase:
 
MeanAmp=zeros(1,nbin); 
for j=1:nbin
    I = find(Phase <  position(j)+winsize & Phase >=  position(j)); %find all of rows that are the phases in the this (and then the next, and the next) bin
    MeanAmp(j)=mean(Amp(I)); %get the mean amplitude of those rows
end
 
% so note that the center of each bin (for plotting purposes) is
% position+winsize/2
 
% at this point you might want to plot the result to see if there's any
% amplitude modulation
%  figure
%  set(gca, 'FontSize', 22)
%  bar(10:20:720,[MeanAmp,MeanAmp])
%  xlim([0 720])

% and next you quantify the amount of amp modulation by means of a
% normalized entropy index:
%(this gives the same result as the formula below, but is easier to look at):
%MeanAmpSum=(MeanAmp/sum(MeanAmp));
%lognbin=log(nbin);
%negsumlog=-sum(MeanAmpSum.*log(MeanAmpSum));
%MIt=(lognbin-(negsumlog))/lognbin;


MI=(log(nbin)-(-sum((MeanAmp/sum(MeanAmp)).*log((MeanAmp/sum(MeanAmp))))))/log(nbin);


end
