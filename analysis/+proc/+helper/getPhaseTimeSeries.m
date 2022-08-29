function [dt,relt] = getPhaseTimeSeries(task,debug,varargin)
[varargin,flag_car] = util.argkeyval('car',varargin,false);
[varargin,flag_outlier] = util.argkeyval('outlier',varargin,false);
util.argempty(varargin);

%% get phase info
[~,blc,map] = proc.helper.getAnalysisObjects(task,debug);
[phtimes,~,num_trials] = proc.helper.getPhaseInfo(task,blc,debug);
num_phases = size(phtimes,2)-1;

%% get time series
[~,largest_section] = max([blc.DataInfo.NumRecords]);
dt = cell(1,num_phases);
relt = cell(1,num_phases);
for pp=1:num_phases
    dt{pp} = arrayfun(@(x)blc.read(...
        'times',phtimes(x,pp:pp+1),...
        'context','section',...
        'section',largest_section),(1:num_trials)','UniformOutput',false);
    relt{pp} = cellfun(@(x,y)(y+(0:(1/blc.SamplingRate):(size(x,1)/blc.SamplingRate-1/blc.SamplingRate)))',dt{pp}(:),arrayfun(@(x)x,phtimes(:,pp),'UniformOutput',false),'UniformOutput',false);
    
    len = cellfun(@(x)size(x,1),dt{pp});
    len = max(len(~isoutlier(len)));
    idx_lt = cellfun(@(x)size(x,1)<=len,dt{pp});
    dt{pp}(idx_lt) = cellfun(@(x)[x; nan(len-size(x,1),size(x,2))],dt{pp}(idx_lt),'UniformOutput',false);
    dt{pp}(~idx_lt) = cellfun(@(x)x(1:len,:),dt{pp}(~idx_lt),'UniformOutput',false);
    dt{pp} = cat(3,dt{pp}{:});
    relt{pp}(idx_lt) = cellfun(@(x)[x; nan(len-size(x,1),size(x,2))],relt{pp}(idx_lt),'UniformOutput',false);
    relt{pp}(~idx_lt) = cellfun(@(x)x(1:len,:),relt{pp}(~idx_lt),'UniformOutput',false);
    relt{pp} = cellfun(@(x)x-x(1),relt{pp},'UniformOutput',false);
    relt{pp} = cat(2,relt{pp}{:});
    relt{pp} = nanmedian(relt{pp},2);
end
phase_end_times = cumsum([0 cellfun(@(x)x(end),relt)]);


%% identify outliers
% use multiples of (Xth percentile) as threshold
% threshold 1 is a percentage of samples above a relaxed threshold
% threshold 2 is any incident above a harsh threshold
% threshold 3 is a (large) percentage of samples below a harsh threshold
if flag_outlier
    dt_outlier = cat(1,dt{:});
    tile_prc = 90;
    multiple_relaxed = 5;
    samples_relaxed = ceil(0.03*size(dt_outlier,1));
    multiple_harsh = 7;
    samples_harsh = ceil(0.0001*size(dt_outlier,1));
    multiple_low = 0.4;
    samples_low = min(size(dt_outlier,1),ceil(0.8*size(dt_outlier,1)));
    
    % first, apply thresholds 1/2/3 to time series
    tiles_dt = prctile(abs(dt_outlier(:)),tile_prc);
    outlier_dt1 = squeeze(sum(abs(dt_outlier)>multiple_relaxed*tiles_dt))>=samples_relaxed;
    outlier_dt2 = squeeze(nansum(abs(dt_outlier)>=multiple_harsh*tiles_dt))>=samples_harsh;
    outlier_dt3 = squeeze(nansum(abs(dt_outlier)<=multiple_low*tiles_dt))>=samples_low;
    outlier_dt = outlier_dt1 | outlier_dt2 | outlier_dt3;
    
    % next, apply thresholds 1/2 to first difference in time
    ddt_outlier = diff(dt_outlier);
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
    idx_usech = cellfun(@(x)nnz(x)<=0.2*numel(x),idx_outlier);
    for pp=1:task.numPhases
        for cc=1:map.NumChannels
            grid_lbl = map.GridInfo.Label{map.GridInfo.GridNumber==map.ChannelInfo.GridNumber(cc)};
            idx_car = map.GridChannelIndex{map.GridInfo.GridNumber==map.ChannelInfo.GridNumber(cc)}; % CAR by grid
            idx_car = idx_car(idx_usech(idx_car));
            if isempty(idx_car)
                debug.log(sprintf('CAR-%d: No channels available in %s for CAR (channel remains unreferenced)',cc,grid_lbl),'info');
                continue;
            end
            ref = dt{pp}(:,idx_car,~idx_outlier{cc});
            dt{pp}(:,cc,:) = dt{pp}(:,cc,:) - nanmean(ref(:,:),2);
        end
    end
end