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
%         tm- a time vector for plotting to match spikes for binned spikes
%         (smoothed spikes is still in native time)
%         
%         can then plot like this:
%         figure
%         plot(tm, spkRateSmooth(:,1))
%         hold on
%         plot(tm, spkRate(:,1))
%         plot(spk(:,1), '.')
% %         
        
[varargin, win] = util.argkeyval('win',varargin, 20);  %window in ms that you want to average over
[varargin, width] = util.argkeyval('width', varargin, 100); %width for gaussSmooth_fast, 100 is typical
[varargin, sm_win] = util.argkeyval('sm_win', varargin, 100); %window for smoothing below, 100 seems about rights
[varargin, spkSm] = util.argkeyval('spkSm', varargin, 1); %choose which smoothing to do, the gaussian kernel works and is in hz (and at 100 is much more fine grained), the gaussSmooth makes the y axis not in hz. 


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

% % another way to do it, just for verification
% binSize = 0.001;       % 1 ms bin
% winSize = 0.020;       % 20 ms window
% 
% 
% 
% % Convolve with a 20 ms boxcar to get instantaneous rate
% winBins = round(winSize / binSize);  % number of bins in window
% kernel = ones(1, winBins);
% 
% % Moving sum of spikes in the past 20 ms
% smoothedCounts = conv(spkS, kernel, 'same');
% 
% % Convert to instantaneous rate in Hz
% instRate = smoothedCounts / winSize; % spikes / 20 ms = spikes/sec

switch spkSm
    case 1
        sigma = sm_win / 4;

        % Build the Gaussian kernel (±3 sigma on each side)
        t = -3*sigma : 3*sigma;
        kernel = exp(-(t.^2) / (2*sigma^2));
        kernel = kernel / sum(kernel);   % normalize kernel

        % Convolve with centered Gaussian kernel
        smoothed = conv(spkS, kernel, 'same');

        % Convert from spikes/ms to spikes/s = Hz
        spkRateSmooth = smoothed * 1000;
        
    case 2
        %this works but has an odd y axis (100 sp/s = 0.02) and it's too confusing
        %to fix
        spkRateSmoothT=gaussSmooth_fast(spkS, width);
end
%create a time vector to plot against the actual spike rates
tm=linspace(1,size(spkS,1),floor(size(spkS,1)/win));

%plot(spkRateSmooth)


end

