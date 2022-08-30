function [spk, spkRate, spkRateSmooth, tm] = spikeRateGauss(spikeRaw,varargin)
%spikeRate takes spike times and creates a raster vector, a spike rate, and
%a smoothed spike rate with conv, as well as a time vector for plotting
% THIS WORKS, BUT IS NOT WELL SMOOTHED. USE SPIKERATEGAUSS.
% %   INPUT
%         spikeRaw- a vector of the spike times, expects it in ms
%     Output
%         spk- just converts to NaNs and 1s for plotting
%         spkRate- spikes summed over a window
%         spkRateSmooth- smoothed spikes with convolve
%         tm- a time vector for plotting to match spikes
%         
%         can then plot like this:
%         figure
%         plot(tm, spkRateSmooth(:,1))
%         hold on
%         plot(tm, spkRate(:,1))
%         plot(spk(:,1), '.')
% %         
        
[varargin, win] = util.argkeyval('win',varargin, 20);  %window in S that you want to average over
[varargin, width] = util.argkeyval('width', varargin, 100); %width for gaussSmooth_fast, 100 is typical


%make sure data is columns=channels and rows are time
if size(spikeRaw, 1)<size(spikeRaw,2)
    spikeRaw=spikeRaw';
end


spkS=spikeRaw;
spk=double(spikeRaw);
spk(spk==0)=NaN;

if win<10
    win=win*1000; %convert to ms if done in seconds
end

%Gaussian smooth (per function of Frank)
for ch=1:size(spkS,2)
    idx=1;
    for ii=1:win:size(spkS,1)-win
        spkRate(idx, ch)=(nansum(spkS(ii:ii+win, ch))*(1000/win)); %convert to hz
        idx=idx+1;
    end   
end

spkRateSmooth=gaussSmooth_fast(spkS, width);
%create a time vector to plot against the actual spike rates
tm=linspace(1,size(spkS,1),floor(size(spkS,1)/win));


end

