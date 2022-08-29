function [dt,f,relt] = getPhaseSpectralPower(task,debug,varargin)
[varargin,flag_car] = util.argkeyval('car',varargin,false);
[varargin,flag_db] = util.argkeyval('db',varargin,true);
[varargin,flag_outlier] = util.argkeyval('outlier',varargin,false);
util.argempty(varargin);


%% get phase info
[~,blc,map] = proc.helper.getAnalysisObjects(task,debug);
[phtimes,~,num_trials] = proc.helper.getPhaseInfo(task,blc,debug);
num_phases = size(phtimes,2)-1;


%% read data
dt = blc.read('class','single');


%% identify outliers (time domain)
% use multiples of (Xth percentile) as threshold
% threshold 1 is a percentage of samples above a relaxed threshold
% threshold 2 is any incident above a harsh threshold
% threshold 3 is a (large) percentage of samples below a harsh threshold
if flag_outlier
    tile_prc = 90;
    multiple_relaxed = 5;
    samples_relaxed = ceil(0.03*size(dt,1));
    multiple_harsh = 7;
    samples_harsh = ceil(0.0001*size(dt,1));
    multiple_low = 0.4;
    samples_low = min(size(dt,1),ceil(0.8*size(dt,1)));
    
    % first, apply thresholds 1/2/3 to time series
    tiles_dt = prctile(abs(dt(:)),tile_prc);
    outlier_dt1 = squeeze(sum(abs(dt)>multiple_relaxed*tiles_dt))>=samples_relaxed;
    outlier_dt2 = squeeze(nansum(abs(dt)>=multiple_harsh*tiles_dt))>=samples_harsh;
    outlier_dt3 = squeeze(nansum(abs(dt)<=multiple_low*tiles_dt))>=samples_low;
    outlier_dt = outlier_dt1 | outlier_dt2 | outlier_dt3;
    
    % next, apply thresholds 1/2 to first difference in time
    ddt_outlier = diff(dt);
    tiles_ddt = prctile(abs(ddt_outlier(:)),tile_prc);
    outlier_ddt1 = squeeze(sum(abs(ddt_outlier)>multiple_relaxed*tiles_ddt))>=samples_relaxed;
    outlier_ddt2 = squeeze(nansum(abs(ddt_outlier)>=multiple_harsh*tiles_ddt))>=samples_harsh;
    outlier_ddt = outlier_ddt1 | outlier_ddt2;
    
    % outlier indication in either, then organize in cell by channel
    idx_outlier = outlier_dt | outlier_ddt;
    idx_outlier = arrayfun(@(x)idx_outlier(x,:),1:size(idx_outlier,1),'UniformOutput',false);
end


%% common-average re-reference
if flag_car
    for cc=1:map.NumChannels
        grid_lbl = map.GridInfo.Label{map.GridInfo.GridNumber==map.ChannelInfo.GridNumber(cc)};
        idx_car = map.GridChannelIndex{map.GridInfo.GridNumber==map.ChannelInfo.GridNumber(cc)}; % CAR by grid
        idx_car = idx_car(idx_usech(idx_car));
        if isempty(idx_car)
            debug.log(sprintf('CAR-%d: No channels available in %s for CAR (channel remains unreferenced)',cc,grid_lbl),'info');
            continue;
        end
        ref = dt(:,idx_car);
        dt(:,cc) = dt(:,cc) - nanmean(ref,2);
    end
end


%% compute spectral power
chr_params = struct('tapers',[5 9],'trialave',false,'Fs',blc.SamplingRate,'pad',1,'fpass',[0 500]);
chr_movingwin = [0.25 0.05];
[S,t,f] = chronux_gpu.ct.mtspecgramc(dt,chr_movingwin,chr_params);
t = t + (chr_movingwin(1)-t(1)); % moving the timestamp to the end of the time bin
dt = cell(1,num_phases);
relt = cell(1,num_phases);
for pp=1:num_phases
    dt{pp} = cell(1,num_trials);
    dt{pp} = cell(1,num_trials);
    for rr=1:num_trials
        idx_trial = t>=phtimes(rr,pp) & t<=phtimes(rr,pp+1);
        dt{pp}{rr} = S(idx_trial,:,:);
        relt{pp}{rr} = t(idx_trial)';
    end
    
    len = cellfun(@(x)size(x,1),dt{pp});
    len = max(len(~isoutlier(len)));
    idx_lt = cellfun(@(x)size(x,1)<=len,dt{pp});
    dt{pp}(idx_lt) = cellfun(@(x)[x; nan(len-size(x,1),size(x,2),size(x,3))],dt{pp}(idx_lt),'UniformOutput',false);
    dt{pp}(~idx_lt) = cellfun(@(x)x(1:len,:,:),dt{pp}(~idx_lt),'UniformOutput',false);
    dt{pp} = cat(4,dt{pp}{:});
    relt{pp}(idx_lt) = cellfun(@(x)[x; nan(len-size(x,1),size(x,2))],relt{pp}(idx_lt),'UniformOutput',false);
    relt{pp}(~idx_lt) = cellfun(@(x)x(1:len,:),relt{pp}(~idx_lt),'UniformOutput',false);
    relt{pp} = cellfun(@(x)x-x(1),relt{pp},'UniformOutput',false);
    relt{pp} = cat(2,relt{pp}{:});
    relt{pp} = nanmedian(relt{pp},2);
end


%% convert to dB
if flag_db
    dt = cellfun(@(x)10*log10(x),dt,'UniformOutput',false);
end


%% identify outliers (freq domain)
% use multiples of (Xth-Yth percentile) as threshold
% threshold 1 is a percentage of samples above a relaxed threshold
% threshold 2 is any incident above a harsh threshold
if flag_outlier
    idx_outlier_freq = cell(1,map.NumGrids);
    for gg=1:map.NumGrids
        dtfreq_outlier = cellfun(@(x)squeeze(x(:,:,map.GridChannelIndex{gg},:)),dtfreq,'UniformOutput',false);
        dtfreq_outlier = cat(1,dtfreq_outlier{:});
        tile_prc = [25 75];
        multiple_relaxed = 5;
        samples_relaxed = ceil(0.05*size(dtfreq_outlier,1));
        multiple_harsh = 7;
        samples_harsh = ceil(0.0001*size(dtfreq_outlier,1));
        
        % first, apply thresholds 1/2/3 to time series
        dtfreq_outlier = permute(dtfreq_outlier,[2 1 3 4]);
        tiles_dtfreq = prctile(dtfreq_outlier(:,:),tile_prc,2);
        iq_dtfreq = diff(tiles_dtfreq,1,2);
        outlier_dtfreq1 = squeeze(nansum(dtfreq_outlier>(tiles_dtfreq(:,2)+multiple_relaxed*iq_dtfreq),2))>=samples_relaxed;
        outlier_dtfreq2 = squeeze(nansum(dtfreq_outlier>(tiles_dtfreq(:,2)+multiple_harsh*iq_dtfreq),2))>=samples_harsh;
        outlier_dtfreq = outlier_dtfreq1 | outlier_dtfreq2;
        
        % nice animated figure
        figure('Position',[400 400 800 300])
        for kk=1:length(f)
            subplot(121);
            imagesc(squeeze(outlier_dtfreq1(kk,:,:))); title(sprintf('freq %d/%d (%.2f Hz)',kk,length(f),f(kk)));
            subplot(122);
            imagesc(squeeze(outlier_dtfreq2(kk,:,:))); title(sprintf('freq %d/%d (%.2f Hz)',kk,length(f),f(kk)));
            pause(0.05);
        end
        
        % outlier indication in either, then organize in cell by channel
        idx_outlier_freq{gg} = outlier_dtfreq;
        idx_outlier_freq{gg} = arrayfun(@(x)squeeze(idx_outlier_freq{gg}(:,x,:)),1:length(map.GridChannelIndex{gg}),'UniformOutput',false);
    end
    idx_outlier_freq = cat(2,idx_outlier_freq{:});
end