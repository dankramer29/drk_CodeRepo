function [ mean_sd, thresh_binary ] = shuffle_subtraction_stats2d( data1, itiData1, data2, itiData2, varargin )
%shuffle_stats shuffles the data between two data sets takes the mean and
%std to make a distribution of the data to compare the true values to. Here
%it compares the difference between the tstat max of one data set, compared
%to iti, to that of the other compared to the iti (so a difference in tstat
%maxes) and compares that to the same thing but all itis.
%this is using a tmax approach (Groppe DM, Urbach TP, Kutas M. Mass
%univariate analysis of event-related brain potentials/fields I: a critical tutorial review. Psychophysiology. 2011)
%this approach takes the tmax across any and all permutations (in theory
%can do it across all channels as well since it's just a tmax, but right
%now done for each channel).

%data 1 is emt and data 2 is idt the way it's being input

%   
% %OUTPUT:
%     mn- the mean of data1 and data2 
%     sd- the std of data1 and data2 
%     est_p-the percentage of the distribution that is farther out than yours
%     with the assumption that if it's less than 0.05, it's significant

[varargin, alph]=util.argkeyval('alph', varargin, 0.05); %option to plot the historgram
[varargin, plt]=util.argkeyval('plt', varargin, false); %option to plot the historgram
[varargin, fdr_adj]=util.argkeyval('fdr_adj', varargin, false); %option to adjust for multiple comparisons with an fdr method
[varargin, xshuffles]=util.argkeyval('xshuffles', varargin, 10000); %how many shuffles you want to do, default is 10k
[varargin, zscoreAcrossAllData]=util.argkeyval('zscoreAcrossAllData', varargin, 0); %if you want to z score across all data
[varargin, timeRange]=util.argkeyval('timeRange', varargin, []); %a time range to look for peaks in the data, default is all, and to be entered in seconds
[varargin, histogramBuiltThresholds]=util.argkeyval('histogramBuiltThresholds', varargin, []); %you can load in a prebuilt histogram of thresholds if you want, should be [threshPositive threshNegative]
[varargin, testChoice]=util.argkeyval('testChoice', varargin, 'ttst'); %pick which test you want to do.'ttst' ttest is one option, 'subtractedDiff' a difference from iti is another.
[varargin, tt]=util.argkeyval('tt', varargin, []); %tt time if you want for plotting
[varargin, gpuOn]=util.argkeyval('gpuOn', varargin, true); %run the shuffle as gpu, takes 7-9 seconds with it off


util.argempty(varargin); % check all additional inputs have been processed


%calculate the size of the samples you want to take
L1 = size(data1, 1);
L2 = size(data2, 1);
L1iti = size(itiData1, 1);
L2iti = size(itiData2, 1);

%find the time range
if isempty(timeRange)
    tR = [1 length(data1)];
else
    if isempty(tt)
        error('need to include the time points as tt to find the range') %need to know the time range of the data
    elseif timeRange(1,1)>10 || timeRange(1,2)>10 % if in ms
        timeRange = timeRange/1000; %convert to seconds
        temptR = find(tt>=timeRange(1,1) & tt<=timeRange(1,2));
        tR(1,1) = temptR(1); tR(1,2) = temptR(end);
    else
        temptR = find(tt>=timeRange(1,1) & tt<=timeRange(1,2));
        tR(1,1) = temptR(1); tR(1,2) = temptR(end);
    end
end


%if iti is not as long as the real data, add mirrored ends. 
if size(itiData1,2)<size(data1,2)
    extr=ceil(size(data1,2)/size(itiData1,2));
    itiData1Temp = itiData1;
    for ii = 1:extr
        if mod(ii,2) %if odd numbered
            temp = flip(itiData1,2);
        else
            temp = itiData1;
        end
        itiData1Temp = cat(2,itiData1Temp, temp);
    end    
    itiData1Temp(:,size(data1,2)+1:end,:) = [];
else
    itiData1Temp = itiData1;
end

if size(itiData2,2)<size(data2,2)
    extr=ceil(size(data2,2)/size(itiData2,2));
    itiData2Temp = itiData2;
    for ii = 1:extr
        if mod(ii,2) %if odd numbered
            temp = flip(itiData2,2);
        else
            temp = itiData2;
        end
        itiData2Temp = cat(2,itiData2Temp, temp);
    end    
    itiData2Temp(:,size(data2,2)+1:end,:) = [];
else
    itiData2Temp = itiData2;
end

%option to z score across all the data.
if zscoreAcrossAllData
    a1Temp = mean(data1,3);
    a1 = mean(a1Temp, 2);
    a1itiTemp = mean(itiData1Temp,3);
    a2 = mean(a1itiTemp,2);
    %combined means
    combined_a = (a1+a2)/2;
    for jj= 1:size(data1,1)
        temp = data1(jj,:,:);
        stdT = std(temp(:));
        b1(jj,1) = stdT;
    end
    for jj= 1:size(itiData1Temp,1)
        temp = itiData1Temp(jj,:,:);
        stdT = std(temp(:));
        b2(jj,1) = stdT;
    end
    %combined standard deviation formula
    combined_b = sqrt(((L1 - 1) * b1.^2 + (L2 - 1) * b2.^2) / (L1 + L2 - 2));
    data1T = (data1-combined_a)./combined_b;
    itidata1T = (itiData1Temp-combined_a)./combined_b;
else
    data1T = data1;
    itidata1T = itiData1Temp;
end

if zscoreAcrossAllData
    a1Temp = mean(data2,3);
    a1 = mean(a1Temp, 2);
    a1itiTemp = mean(itiData2Temp,3);
    a2 = mean(a1itiTemp,2);
    %combined means
    combined_a = (a1+a2)/2;
    for jj= 1:size(data2,1)
        temp = data2(jj,:,:);
        stdT = std(temp(:));
        b1(jj,1) = stdT;
    end
    for jj= 1:size(itiData2Temp,1)
        temp = itiData2Temp(jj,:,:);
        stdT = std(temp(:));
        b2(jj,1) = stdT;
    end
    %combined standard deviation formula
    combined_b = sqrt(((L1 - 1) * b1.^2 + (L2 - 1) * b2.^2) / (L1 + L2 - 2));
    data2T = (data2-combined_a)./combined_b;
    itidata2T = (itiData2Temp-combined_a)./combined_b;
else
    data2T = data2;
    itidata2T = itiData2Temp;
end

if gpuOn
    data1T = gpuArray(data1T);
    data2T = gpuArray(data2T);
    itidata1T = gpuArray(itidata1T);
    itidata2T = gpuArray(itidata2T);
end

ticT = tic;
for ii=1:xshuffles   
    switch testChoice %do a ttest as the comparison 
        case 'ttst'
            %% fake data 1, all iti
            totdata=cat(1, itidata1T, itidata2T);
            totdata=totdata(randperm(size(totdata,1)),:);
            mean1=nanmean(totdata(1:L1,:));
            mean2=nanmean(totdata(L1+1:end,:)); %since it takes L1 to end, it's just the rest

            %run the guts of a ttest2 (much faster than the built in function)
            sp=sqrt(((L1-1)*std(totdata(1:L1,:),[],1).^2+(L1iti-1)*std(totdata(L1+1:end,:),[],1).^2)./(L1+L1iti-2));
            tstat_res1(ii,:)=(mean1-mean2)./(sp*sqrt(1/L1+1/L1iti));
            %take the most extreme tstat (tmax) between the time threshold
            maxTiti1(ii,1) = max(abs(tstat_res1(ii,tR(1):tR(2))));
            
            %% do it again for data 2 but still all iti
            totdata=cat(1, itidata1T, itidata2T);
            totdata=totdata(randperm(size(totdata,1)),:);
            mean1=nanmean(totdata(1:L2,:));
            mean2=nanmean(totdata(L2+1:end,:)); %since it takes L1 to end, it's just the rest

            %run the guts of a ttest2 (much faster than the built in function)
            sp=sqrt(((L2-1)*std(totdata(1:L2,:),[],1).^2+(L2iti-1)*std(totdata(L2+1:end,:),[],1).^2)./(L2+L2iti-2));
            tstat_res2(ii,:)=(mean1-mean2)./(sp*sqrt(1/L2+1/L2iti));
            %take the most extreme tstat (tmax) between the time threshold
            maxTiti2(ii,1) = max(abs(tstat_res2(ii,tR(1):tR(2))));
           
            %% take the difference of max t stats (so the highest absolute value wherever it happens) and build the histogram
            thresh(ii,1) = maxTiti1(ii,1)-maxTiti2(ii,1);

        case 'subtractedDiff'
           % NOT FINISHED, NEED TO THINK ABOUT A PURE SUBTRACTION BUT
           % PROBABLY SINCE TAKING THE DIFFERENCE BETWEEN DATA 1 AND DATA
           % 2, JUST SPLIT THE DATA, TAKE THE MEAN, AND SUBTRACT THE
           % PEAKS.IF THIS GETS FIXED, NEED TO ADJUST THE OUTPUTS OF THE
           % REAL DATA BELOW AS WELL
            totdata=cat(1, data1T, itiData2T);
            totdata=totdata(randperm(size(totdata,1)),:);
            mean1=nanmean(totdata(1:L1,:));
            mean2=nanmean(totdata(L1+1:end,:));

            %take the peak of 

            %run the guts of a ttest2 (much faster than the built in function)
            sp=sqrt(((L1-1)*std(totdata(1:L1,:),[],1).^2+(L2-1)*std(totdata(L1+1:end,:),[],1).^2)./(L1+L2-2));
            tstat_res(ii,:)=(mean1-mean2)./(sp*sqrt(1/L1+1/L2));
            %take the most extreme tstat (tmax) and build the distribution off of
            %that.
            thresh(ii,1) = max(abs(tstat_res(ii,:)));
    end    
end
toc(ticT)
data1T = gather(data1T);
data2T = gather(data2T);
itidata1T = gather(itidata1T);
itidata2T = gather(itidata2T);
thresh = gather(thresh);

%sort the histogram
threshSort=sort(thresh);
%find the tail(s)
%single tail for tstat or p values. 
thresh1tail=threshSort(round(size(threshSort,1)*(1-alph)));

%since t stat is a 1 tail distribution, really only needs the 1 tail, but
%if you want to do some other distribution stat like run positive and
%negative deflections separately (RIGHT NOW NOT FULLY BUILT)
alphP = 1-(alph/2); 
alphN = alph/2;
threshP=threshSort(round(size(threshSort,1)*alphP)); %find the alphP (say 97.5th) spot in the histogram
threshN=threshSort(round(size(threshSort,1)*alphN));


%get the real mean difference
mn1=mean(data1T);
mn1iti=mean(itidata1T);
sd1=std(data1T, [], 1);
sd1iti=std(itidata1T, [], 1);
SEM1 = std(data1T, [], 1) / sqrt(size(data1T,1));
SEM1iti = std(itidata1T, [], 1) / sqrt(size(itidata1T,1));

sp=sqrt(((L1-1)*std(data1T,[],1).^2+(L1iti-1)*std(itidata1T,[],1).^2)./(L1+L1iti-2));
tstat_resR1=(mn1-mn1iti)./(sp*sqrt(1/L1+1/L1iti));
[maxTdata1 in1] = max(abs(tstat_resR1(1, tR(1):tR(2)))); %do this in the time range and find the max peak

%again for data2
mn2=mean(data2T);
mn2iti=mean(itidata2T);
sd2=std(data2T);
sd2iti=std(itidata2T);
SEM2 = std(data2T, [], 1) / sqrt(size(data2T,1));
SEM2iti = std(itidata2T, [], 1) / sqrt(size(itidata2T,1));

sp=sqrt(((L2-1)*std(data2T,[],1).^2+(L2iti-1)*std(itidata2T,[],1).^2)./(L2+L2iti-2));
tstat_resR2=(mn2-mn2iti)./(sp*sqrt(1/L2+1/L2iti));
[maxTdata2, in2]= max(abs(tstat_resR2(1, tR(1):tR(2))));

realDiff = maxTdata1 - maxTdata2;

%% find the max t stat mass (meaning the sum of the t stats in the max area using image recognition using bwconncomp)

if realDiff >=0 && abs(realDiff)>thresh1tail %this is where it counts how many shuffled points, this would be essentially 1 tailed.
    thresh_binary = 1; %1 if data 1 is bigger
elseif realDiff <0 && abs(realDiff)>thresh1tail
    thresh_binary = 2; %2 if data 2 is bigger
else
    thresh_binary = 0; %1 if data 1 is bigger
end



[~, in1r]  = ind2sub(size(tstat_resR1), in1); %this will give the location of the max (need to add tR)
[~, in2r]  = ind2sub(size(tstat_resR2), in2);

%this is from an old function and i haven't checked to see if this works.
% switch tails
%     case 1
%         diffR=abs(mn(1)-mn(2)); %one tailed
%         temp_p=arrayfun(@gt, difftot, diffR);
%         est_p=nnz(temp_p,2)/xshuffles; %get the percentage
%     case 2
%         diffR=mn(1)-mn(2);
%         if diffR<0
%             est_p=nnz(difftot<=diffR)/xshuffles;
%         else
%             est_p=nnz(difftot>=diffR)/xshuffles;
%         end
% end

if fdr_adj
    est_p=stats.fdr_bh(length(thresh_binary)); %runs a multiple comparisons correction
end
%%
if plt
    figure;
    subplot(3,1,1) %PUTTING DATA 2 first WHICH IS IDT (TO MATCH THE SPECTROGRAM OUTPUT)
    H1 = shadedErrorBar(tt,mn1,SEM1*2,'lineprops', {'-b'}); %data 1 is emt
    hold on;  
    H2 = shadedErrorBar(tt,mn2,SEM2*2,'lineprops', {'-r'}); %data 2 is idt
    ax = axis;
    %if sum(thresh_binary) > 0
        %this puts a line where the two max points are (+5 around it to
        %make it visible)
        x_seg = tt(in1r+tR(1)-5:in1r+tR(1)+5); % Get x values for segment
        plot(x_seg, ax(3)+0.02 * ones(size(x_seg)), 'b-', 'LineWidth', 2); % Plot horizontal line
        hold on
        x_seg = tt(in2r+tR(1)-5:in2r+tR(1)+5); % Get x values for segment
        plot(x_seg, ax(3)+0.02 * ones(size(x_seg)), 'r-', 'LineWidth', 2); % Plot horizontal line
        
        % this is code to put a line at the time points where it occurs but
        % since it's a single max, not using this, using above
        % trueIndices = find(thresh_binary);
        % % Find breaks in consecutive true values
        % splitPoints = find(diff(trueIndices) > 1);
        % % Split into segments
        % startIdx = [1, splitPoints + 1];
        % endIdx = [splitPoints, length(trueIndices)];
        % for ii = 1:length(startIdx)
        %     x_seg = tt(trueIndices(startIdx(ii))+tR(1):trueIndices(endIdx(ii))+tR(1)); % Get x values for segment
        %     plot(x_seg, ax(3)+0.02 * ones(size(x_seg)), 'g-', 'LineWidth', 2); % Plot horizontal line
        % end
  %  end
    aX = gca; 
    if ~isempty(tt)
        aX.XLim = [tt(1) tt(end)];
    else
        aX.XLim = length(mn1);
    end
    legend([H1.mainLine, H2.mainLine], {'data 1 (EmT)', 'data 2 (IdT)'})
    title('mean and 2SE')
    subplot(3,1,2) 
    plot(tt, tstat_resR1, 'b-')
    hold on
    plot(tt, tstat_resR2, 'r-')
    x_seg = tt(in1r+tR(1)-5:in1r+tR(1)+5); % Get x values for segment
    plot(x_seg, ax(3)+0.02 * ones(size(x_seg)), 'b-', 'LineWidth', 2); % Plot horizontal line
    hold on
    x_seg = tt(in2r+tR(1)-5:in2r+tR(1)+5); % Get x values for segment
    plot(x_seg, ax(3)+0.02 * ones(size(x_seg)), 'r-', 'LineWidth', 2); % Plot horizontal line

    %this plots the real
    % if ~isempty(tt)
    %     plot(tt(tR(1):tR(2)), realDiff)
    %     aX = gca;
    %     aX.XLim = [tt(1) tt(end)];
    % else
    %     plot(realDiff)
    %     aX = gca;
    %     aX.XLim(1,2) = length(mn1);
    % end
    mxT = max(abs(realDiff));
    title('tstat difference')
    subplot(3,1,3)
    histogram(thresh,xshuffles)
    hold on
    plot([thresh1tail thresh1tail], [1 7]);
    plot([mxT mxT], [1 7], 'b');
    title('histogram and .05 threshold')
end

%TO DO. FIRST CHECK THAT THE GREEN SIGNIFICANCE LINE IS ENDING UP WHERE YOU
%WANT IT. SECOND,CHECK IT'S TAKING THE RIGHT DIFFERENCE, IT SHOULD BE THE
%TSTAT MAX DIFFERENCE FROM ITI, SO WHY IS IT CONTINUOUS?
    
%output
mean_sd = table;
mean_sd.mean{1,1} = mn1;
mean_sd.mean{2,1} = mn2;
mean_sd.sd{1,1} = sd1;
mean_sd.sd{2,1} = sd2;
mean_sd.se{1,1} = SEM1;
mean_sd.se{2,1} = SEM2;
mean_sd.thresh_SubtractionBinary{1,1} = thresh_binary;
mean_sd.tmaxLoc{1,1} = in1r+tR(1);
mean_sd.tmaxLoc{2,1} = in2r+tR(1);
mean_sd.thresh_tmaxDiff{1,1} = realDiff;
mean_sd.histo{1,1} = thresh;
mean_sd.xshuffles{1,1} = xshuffles;
mean_sd.thresh1tail{1,1} = thresh1tail;
mean_sd.thresh{1,1} = alph;







end


