function [spk, spkRate, spkRateSmooth, tm, win] = spikeRate(spikeRaw,varargin)
%spikeRate takes spike times and creates a raster vector, a spike rate, and
%a smoothed spike rate with conv, as well as a time vector for plotting
% %   INPUT
%         spikeRaw- a vector of the spike times, expects it in ms meaning
%         each row is a ms.
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
%         plot(spk(:,1)*40, '.')
% 
% USING THIS ONE
% %         
        
[varargin, win] = util.argkeyval('win',varargin, 0.05);  %window in S that you want to average over
[varargin, convWin] = util.argkeyval('convWin',varargin, 10);  %window to convolve over, which is just how often to smooth, don't want too big
[varargin, gaus] = util.argkeyval('gaus',varargin, true);  %convolve vs gaussian smooth, mapped botha nd gaussian looks better but convolve is more true? looks more sharp edgs. can compare with "C:\Users\dankr\Documents\Data\GeneralDataStuff\ComparisonOfSpikeSmoothing.jpg" 
[varargin, timeSt] = util.argkeyval('timeSt',varargin, 0); %an optional time start that is a time adjustment factor to give a time that is relative to the recording times


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


%smooth
b=ones(convWin,1)/convWin; %convolve window create the 1s, but divide by window to keep output small
for ch=1:size(spkS,2)
    idx=1;
    for ii=1:win:size(spkS,1)-win
        spkRate(idx, ch)=(nansum(spkS(ii:ii+win, ch))*(1000/win)); %convert to hz
        idx=idx+1;
    end   
    %add mirrored ends
    mirrorSt=fliplr(spkRate(1:convWin, ch));
    mirrorEnd=fliplr(spkRate(end-convWin+1:end, ch));
    temp=vertcat(mirrorSt, spkRate(:, ch), mirrorEnd);
    if gaus
        %gaussian smooth
       tempspkRateS=smoothdata(temp, 'gaussian', 20);
    else
        %convolve the two vectors
        tempspkRateS=conv(temp,b,'same');
    end
    %remove the ends
    spkRateSmooth(:, ch)=tempspkRateS(convWin+1:end-convWin);
end

%create a time vector to plot against the actual spike rates
tm=linspace(0,size(spkS,1),size(spkRateSmooth,1));

tm=tm+timeSt; %move the time start to the adjusted time start if given

end


