function [nevfile,varargout] = threshold(ns,varargin)
% THRESHOLD Threshold broadband neural data to detect spike events
%
%   NEVFILE = THRESHOLD(NS)
%   Threshold full-bandwidth data from an NS6 file to re-generate a spike
%   event file. This process more or less implements the same process used
%   in the Blackrock hardware during online spike thresholding, with one
%   important difference - the filters are noncausal to avoid phase
%   distortion. The threshold is set to a default value of -3.5 (in
%   multiples of estimated standard deviation of background noise). The
%   function returns the path to the new or updated spike event file, and
%   the path to a sidecar MAT file which contains the post-hoc estimated
%   standard deviation of the background noise). The output file has the
%   same basename as the source file, but is appended with
%   "_threshold%+0.1f", and shares the .nev extension. A few notes:
%
%     * Noncausal (forward and reverse) filtering to mitigate phase
%       distortion; note the 2x effect on stopband attenuation and passband
%       ripple.
%     * Windowed processing for better memory use profile; mirrored
%       signal ends to avoid boundary effects in the filtering
%     * Support for flexible amount of data captured for each waveform, and
%       the alignment of the waveform samples with respect to the threshold
%       crossing (waveform_samples, samples_before_thresh)
%     * Rejection of spikes occurring within a user-defined refractory
%       period (refractory)
%     * Rejection of spikes occuring within a user-defined temporal window
%       across a user-defined number of channels (chanlimit, chanlimitwin)
%     * Creates a new NEV file with the detected spike events
%     * Creates a new MAT file that stores the estimated standard deviation
%       of the background noise (useful for determining waveform SNR)
%
%   [...] = THRESHOLD(...,'THRESHOLD',THR)
%   Set the threshold level, a value defined in multiples of the estimated
%   standard deviation of the background noise. Default value is -3.5.
%
%   [...] = THRESHOLD(...,'OVERWRITE')
%   Overwrite the target file if it exists.
%
%   [...] = THRESHOLD(...,'OUTDIR',DIR)
%   [...] = THRESHOLD(...,'OUTBASE',BASE)
%   Specify the directory and file basename for the output spike event file
%   and MAT sidecar file.
%
%   [...] = THRESHOLD(...,'CAR')
%   [...] = THRESHOLD(...,'CAR_CHANNELS',CHLIST)
%   Set a flag, "CAR" to common-average re-reference the data, and use the
%   key-value pair "CAR_CHANNELS" to provide a list of channels to include
%   in the reference.
%
%   [...] = THRESHOLD(...,'WAVEFORM_SAMPLES',NWVFRM)
%   [...] = THRESHOLD(...,'SAMPLES_BEFORE_THRESH',NSAMP)
%   Set the number of samples in a spike waveform (default 48) and the
%   number of samples to save prior to the threshold crossing (default 11).
%
%   [...] = THRESHOLD(...,'THRESHOLD_FILTER',FILTNAME)
%   Specify the filter that should be applied to the data prior to
%   thresholding. By default, this is "BUTTER_O8_BP_250-5000" which is an
%   8th-order Butterworth bandpass with passband 250 Hz - 5000 Hz. See
%   BLACKROCK.GETSPIKECONTENTFILTER for a list of other available filters.
%
%   [...] = THRESHOLD(...,'REFRACTORY',REFR)
%   Set the refractory period, i.e., the amount of time following a spike
%   during which no other spikes will be detected. Default is 0.5 msec.
%
%   [...] = THRESHOLD(...,'CHANLIMITWIN',CH)
%   Set a limit on the number of channels which may contain simultaneous
%   spike events before it will be discarded (under the hypothesis that an
%   event occuring on too many channels at once is likely to be some form
%   of artifact).
%
%   [...] = THRESHOLD(...,'CAUSAL')
%   Explicitly request either causal filtering (default is noncausal).
%
%   [...] = THREHSOLD(...,DEBUG)
%   Provide an object of class DEBUG.DEBUGGER to serve as a logging
%   mechanism for all messages. By default, a new object will be created
%   with the base title "blackrock_threshold".
%
%   See also BLACKROCK.NSX, BLACKROCK.NEV, BUFFER.DYNAMIC.
[varargin,flag_overwrite] = util.argflag('overwrite',varargin,false);
[varargin,flag_sidecar] = util.argflag('matfile',varargin,false);
[varargin,flag_plot] = util.argflag('plot',varargin,false);
[varargin,outdir,~,found_outdir] = util.argkeyval('outdir',varargin,nan);
[varargin,outbase,~,found_outbase] = util.argkeyval('outbase',varargin,nan);
[varargin,flag_car] = util.argflag('car',varargin,false);
[varargin,car_channels,found_carchan] = util.argkeyval('car_channels',varargin,nan);
[varargin,wv_nsamp] = util.argkeyval('waveform_samples',varargin,48);
[varargin,wv_npre] = util.argkeyval('samples_before_thresh',varargin,10);
[varargin,threshold_filter] = util.argkeyval('threshold_filter',varargin,{'butter_o4_bp_250-5000'});
[varargin,threshold] = util.argkeyval('threshold',varargin,-3,6);
[varargin,smoothingparam] = util.argkeyval('smoothingparam',varargin,2e-11); % matlab's automatic value, 2e-11, was the same for two different subjects' data files
[varargin,refractory_period] = util.argkeyval('refractory',varargin,0.5e-3);
[varargin,channel_limit_win] = util.argkeyval('chanlimitwin',varargin,20);
[varargin,flag_noncausal] = util.argflag('causal',varargin,true);
[varargin,flag_nameonly] = util.argflag('nameonly',varargin,false);
[varargin,debug,found_debug] = util.argisa('Debug.Debugger',varargin,nan);
if ~found_debug,debug=Debug.Debugger('blackrock_threshold');end
if threshold>0,warning('THRESHOLD>0! This is probably wrong.');end
try
    if ~debug.isRegistered('Blackrock.NEV')
        debug.registerClient('Blackrock.NEV','verbosityScreen',Debug.PriorityLevel.ERROR);%,'verbosityLogfile',Debug.PriorityLevel.INSANITY);
    end
    if ~debug.isRegistered('Blackrock.NSx')
        debug.registerClient('Blackrock.NSx','verbosityScreen',Debug.PriorityLevel.ERROR);%,'verbosityLogfile',Debug.PriorityLevel.INSANITY);
    end
catch ME
    util.errorMessage(ME);
    keyboard
end
util.argempty(varargin);

% validate the NSx input
flag_internal = false;
if ischar(ns) && exist(ns,'file')==2
    flag_internal = true;
    [~,~,srcext] = fileparts(ns);
    assert(strcmpi(srcext,'.ns6'),'Must provide the full path to a NS6 file');
    ns = Blackrock.NSx(ns,debug);
end
assert(isa(ns,'Blackrock.NSx'),'Must provide an object of type ''Blackrock.NSx'', not ''%s''',class(ns));
if ~flag_internal
    ns.setDebug(debug);
end
if ~strcmpi(ns.SourceExtension,'.ns6')
    debug.log(sprintf('Spike detection should be run on the full-bandwidth, unfiltered broadband data (typically stored in an NS6 file), not on a %s file',upper(ns.SourceExtension(2:end))),'warn');
end
if ~found_carchan
    car_channels = [ns.ChannelInfo.ChannelID];
end

% set up output file
if ~found_outdir
    outdir = ns.SourceDirectory;
end
if ~found_outbase
    outbase = ns.SourceBasename;
end
nevfile = fullfile(outdir,sprintf('%s_threshold%+0.1f.nev',outbase,threshold));
matfile = fullfile(outdir,sprintf('%s_threshold%+0.1f.mat',outbase,threshold));
if flag_nameonly
    varargout{1} = matfile;
    return;
end

% read original data from associated NEV file
srcnev = fullfile(ns.SourceDirectory,sprintf('%s.nev',ns.SourceBasename));
assert(exist(srcnev,'file')==2,'Could not find source NEV file "%s"',srcnev);
nv = Blackrock.NEV(srcnev,debug);
data = nv.read('all','UniformOutput',false);
fields = fieldnames(data);
for kk=1:length(fields)
    if isempty(data.(fields{kk})) || strncmpi(fields{kk},'spike',5)
        data = rmfield(data,fields{kk});
    elseif length(data.(fields{kk}))~=ns.NumDataPackets
        debug.log(sprintf('Removing data field ''%s'' because in the original NEV it has %d blocks, but NSx file has %d',fields{kk},length(data.(fields{kk})),ns.NumDataPackets),'warn');
        data = rmfield(data,fields{kk});
    end
end

% check target file up front
assert(flag_overwrite||exist(nevfile,'file')~=2,'Target NEV file exists and overwrite is disabled ("%s")',nevfile);

% number of samples in each waveform, before/after threshold crossing
wv_npost = wv_nsamp - wv_npre - 1;

% construct the bandpass filter
nm = util.ascell(threshold_filter);
filtobj = cell(1,length(nm));
for nn=1:length(nm)
    filtobj{nn} = Blackrock.getSpikeContentFilter(nm{nn});
end

% loop over data packets in the NSx file
local_fs = ns.Fs;
refractory_samples = local_fs*refractory_period;
npre_filt = 1*ns.Fs; % samples before data window (for edge effects in filtering)
npre_spk = 100; % samples before data window (in case of early spike)
npre_max = max(npre_filt,npre_spk);
npost_spk = 100; % samples after data window (in case of late spike)
nmirr = 2*ns.Fs; % mirroring
nwin = 10*ns.Fs; % window
nchan = ns.ChannelCount;
for bb=1:ns.NumDataPackets
    thresholdCrossings = Buffer.Dynamic('r');
    tocs = Buffer.Dynamic('r');
    
    % loop over windows of data
    winstart = 1:nwin:ns.PointsPerDataPacket(bb);
    feedback_tracker = 0;
    for kk=1:length(winstart)
        stopwatch = tic;
        numWinsRemaining = length(winstart)-kk;
        
        % account for running up against end of packet
        numSamplesRemaining = ns.PointsPerDataPacket(bb)-winstart(kk)+1;
        nwin_local = min(nwin,numSamplesRemaining);
        npre_local = min(npre_max,winstart(kk)-winstart(1));
        npost_local = min(npost_spk,(numSamplesRemaining-nwin_local));
        
        % read the broadband data
        if kk==1
            
            % the first time we include the pre amount
            bufwin_local = winstart(kk)+[-npre_local (nwin_local+npost_local-1)];
            dt = ns.read('points',bufwin_local,'ref','packet','double','packet',bb,'normalized')';
        else
            
            % now we read new data into the second portion
            bufwin_local = winstart(kk)+[0 (nwin_local+npost_local-1)];
            dt = ns.read('points',bufwin_local,'ref','packet','double','packet',bb,'normalized')';
            dt = [prev_dt; dt];
        end
        
        % second time we copy npre samples from end to beginning
        if kk<length(winstart)
            prev_dt = dt(max(1,size(dt,1)-npost_local-npre_max+1):(size(dt,1)-npost_local),:);
        end
        
        % apply common-average rereference
        if flag_car
            car = nanmean(dt(:,car_channels),2); % common average of selected channels
            dt = dt - car; % subtraction of car from the data
        end
        
        % filter the data
        if kk==1
            
            % in the first round, there's no buffer of actual data
            % to avoid edge effects so mirror the data to mitigate
            nmirr_local = min(nmirr,size(dt,1));
            dt = [flipud(dt(2:nmirr_local,:)); dt; flipud(dt((end-nmirr_local+1):end-1,:))];
        end
        for nn=1:length(filtobj)
            if flag_noncausal
                dt = filtfilt(filtobj{nn},dt);
            else
                dt = filter(filtobj{nn},dt);
            end
        end
        if kk==1
            
            % remove the mirrored portions
            dt = dt(nmirr_local+(0:nwin_local+npre_local+npost_local-1),:);
        end
        
        % compute estimates of noise variance
        % NOTE: consider computing noise variance model on data with
        % pre/post buffers still in place to avoid edge effects (could end
        % up seeing artifically increased or decreased threshold crossings
        % at regular intervals, which could in the worst case align with
        % some task attribute)
        sigma_winstarts = 1:round(0.25*local_fs):size(dt,1);
        sigma_winlen = 2*local_fs;
        sigma_noise = nan(length(sigma_winstarts),nchan);
        for ww=1:length(sigma_winstarts)
            idx_st = sigma_winstarts(ww);
            idx_lt = min(size(dt,1),idx_st+sigma_winlen-1);
            if (idx_lt-idx_st+1) < 0.1*local_fs
                
                % if not much data to work with, use previous estimate or 1
                if ww>1
                    sigma_noise(ww,:) = sigma_noise(ww-1,:);
                else
                    sigma_noise(ww,:) = 1;
                end
            else
                
                % compute var of background noise (valid for Gaussian; here
                % obviously an estimate)
                sigma_noise(ww,:) = nanmedian(abs(dt(idx_st:idx_lt,:))/0.6745);
            end
        end
        
        % generate sample-by-sample thresholds
        first_sigma_nwin = find(sigma_winstarts>=npre_local,1,'first');
        if isempty(first_sigma_nwin) || (length(sigma_winstarts) - first_sigma_nwin)<6
            
            % just use the mean variance
            noise_model = nanmean(sigma_noise,1);
            thresh = arrayfun(@(x)repmat(threshold*x,nwin_local,1),noise_model,'UniformOutput',false);
        else
            
            % scaled smoothing parameter
            sc = smoothingparam;
            if length(sigma_winstarts)<10
                sc = smoothingparam/1e2;
            end
            
            % fit a spline to the noise variance estimates
            noise_model = arrayfun(@(x)fit(sigma_winstarts(:)+sigma_winlen/2,sigma_noise(:,x),'smoothingspline','smoothingparam',sc),1:nchan,'UniformOutput',false);
            thresh = cellfun(@(x)threshold*feval(x,npre_local+(1:nwin_local)),noise_model,'UniformOutput',false);
        end
        
        % pull out the pre/post buffers and just operate on the core window
        bufpre = dt(max(1,npre_local-npre_spk+1):npre_local,:);
        bufpost = dt((end-npost_local+1):end,:);
        dt = dt((npre_local+1):(end-npost_local),:);
        npre_local = size(bufpre,1);
        npost_local = size(bufpost,1);
        
        % identify threshold crossings
        tm = cell(1,nchan);
        wvfrm = cell(1,nchan);
        for ch=1:nchan
            
            % identify threshold crossings
            local_tm = find(dt(:,ch)<thresh{ch});
            
            % skip if none found
            if isempty(local_tm),continue;end
            
            % remove any crossings only 1 sample apart (under assumption
            % that they are part of the same waveform which triggered the
            % threshold crossing in the first place)
            d1tm = diff(local_tm);
            local_tm = local_tm([1; find(d1tm>1)+1]);
            
            % impose a refractory period
            d1tm = diff(local_tm);
            local_tm = local_tm([1; find(d1tm>refractory_samples)+1]);
            
            % identify crossings that are too close to beginning/end
            idxExcl = find(local_tm<=(wv_npre+1)|local_tm>=(nwin_local-(wv_npost-1)));
            tmExcl = local_tm(idxExcl);
            local_tm(idxExcl) = [];
            
            % capture the waveform for each crossing
            idx = repmat((-wv_npre:wv_npost)',1,length(local_tm(:))) + repmat(local_tm(:)',wv_nsamp,1);
            local_wvfrm = reshape(dt(idx(:),ch),[wv_nsamp length(local_tm(:))])';
            
            % add in waveforms for excluded crossings
            if ~isempty(tmExcl)
                wvfrmExcl = nan(wv_nsamp,length(tmExcl));
                for tt=1:length(tmExcl)
                    
                    % determine indices for this waveform
                    idxFullWaveform = tmExcl(tt) + (-wv_npre:wv_npost);
                    
                    % copy over data from core window
                    idxInData = idxFullWaveform( idxFullWaveform>=1 & idxFullWaveform<=nwin_local );
                    idxDataInWaveform = idxInData - tmExcl(tt) + wv_npre + 1;
                    wvfrmExcl(idxDataInWaveform,tt) = dt(idxInData,ch);
                    
                    % copy over data from pre-buffer
                    numInBufPre = min(npre_local,nnz(idxFullWaveform<1));
                    if numInBufPre>0
                        idxInBuf = npre_local + ((-numInBufPre+1):0);
                        idxInWaveform = find(idxFullWaveform==0,1,'first') + ((-numInBufPre+1):0);
                        wvfrmExcl(idxInWaveform,tt) = bufpre(idxInBuf,ch);
                    end
                    
                    % copy over data for post-buffer
                    numInBufPost = min(npost_local,nnz(idxFullWaveform>nwin_local));
                    if numInBufPost>0
                        idxInBuf = 1:numInBufPost;
                        idxInWaveform = idxDataInWaveform(end)+idxInBuf;
                        wvfrmExcl(idxInWaveform,tt) = bufpost(idxInBuf,ch);
                    end
                end
                local_tm = [local_tm(:); tmExcl(:)];
                local_wvfrm = [local_wvfrm; wvfrmExcl'];
            end
            
            % add in the win start offset
            local_tm = local_tm + winstart(kk) - 1;
            
            % add in the recording block timestamp offset
            % a timestamp of *zero* corresponds to the beginning of the
            % data acquisition cycle
            local_tm = local_tm + ns.Timestamps(bb);
            
            % subtract off the number of samples prior to threshold
            % crossing, to match up with original NEV
            local_tm = local_tm - wv_npre;
            
            % place results into output cell arrays
            tm{ch} = local_tm;
            wvfrm{ch} = local_wvfrm;
            
            % plot the data
            if flag_plot
                plot_data(dt(:,ch),thresh{ch},tm{ch},ch,bufwin_local,local_fs,winstart(kk),ns.Timestamps(bb),wv_npre);
            end
        end
        for ch=1:nchan
            if ~isempty(tm{ch})
                chs = repmat(ch,length(tm{ch}),1);
                add(thresholdCrossings,[tm{ch} chs wvfrm{ch}]);
            end
        end
        
        % update user
        add(tocs,toc(stopwatch));
        if kk/length(winstart)>=feedback_tracker
            debug.log(sprintf('Packet %d/%d: %.1f%% (%s remaining)',...
                bb,ns.NumDataPackets,100*kk/length(winstart),...
                util.hms(numWinsRemaining*nanmedian(get(tocs)),'mm:ss')),'info');
            feedback_tracker = feedback_tracker + 0.1;
        end
    end
    
    % sort everything by ascending timestamp
    tmpx = get(thresholdCrossings);
    if isempty(tmpx)
        
        % create spikes structure
        data.Spike{bb}.Timestamps = [];
        data.Spike{bb}.Units = zeros(size(tmpx,1),1);
        data.Spike{bb}.Channels = [];
        data.Spike{bb}.Waveforms = [];
        continue;
    elseif size(tmpx,1)<3*channel_limit_win
        
        % create spikes structure
        data.Spike{bb}.Timestamps = tmpx(:,1);
        data.Spike{bb}.Units = zeros(size(tmpx,1),1);
        data.Spike{bb}.Channels = tmpx(:,2);
        data.Spike{bb}.Waveforms = tmpx(:,3:end)';
    else
        
        % count number of occurrences per timestamp
        [num_instances_per_ts,ts_bins] = histcounts(tmpx(:,1),(0:max(tmpx(:,1))+1)-0.5);
        ts_bins = ts_bins(1:end-1)+0.5;
        
        % remove indices for timestamps occurring on too many channels
        badidx = ismember(tmpx(:,1),ts_bins(num_instances_per_ts>channel_limit_win));
        tmpx(badidx,:) = [];
        
        % create spikes structure
        data.Spike{bb}.Timestamps = tmpx(:,1);
        data.Spike{bb}.Units = zeros(size(tmpx,1),1);
        data.Spike{bb}.Channels = tmpx(:,2);
        data.Spike{bb}.Waveforms = tmpx(:,3:end)';
    end
end

% create the NEVWriter object and add data
fields = fieldnames(data);
args = {};
if flag_overwrite
    args = {'overwrite'};
end
nvw = Blackrock.NEVWriter(nevfile,'like',nv,args{:},debug);

% check how many recording blocks (cells)
for kk=1:length(fields)
    assert(length(data.(fields{kk}))==ns.NumDataPackets,'Incorrect number of blocks for ''%s''',fields{kk});
end
for kk=1:ns.NumDataPackets
    arg = arrayfun(@(x)data.(fields{x}){kk},1:length(fields),'UniformOutput',false);
    idx = find(cellfun(@isempty,arg));
    for nn=1:length(idx)
        arg{idx(nn)} = fields{idx(nn)};
    end
    nvw.addData(arg{:});
end

% save the new NEV file
debug.log(sprintf('Writing new NEV file ''%s''',nevfile),'info');
nvw.save;

% save the noise standard deviation estimates
varargout = {};
if flag_sidecar
    timestamps = cell(1,ns.NumDataPackets);
    sigma = cell(1,ns.NumDataPackets);
    for bb=1:ns.NumDataPackets
        timestamps{bb} = 1:100:ns.PointsPerDataPacket(bb);
        sigma{bb} = cellfun(@(x)single(feval(x,timestamps{bb})),spl{bb},'UniformOutput',false);
        sigma{bb} = cat(2,sigma{bb}{:});
    end
    save(matfile,'sigma','timestamps');
    varargout{1} = matfile;
end
end % END function threshold


function plot_data(dt,thresh,tm,ch,bufwin_local,local_fs,local_winstart,local_timestamp,wv_npre)
% plot the data/threshold/crossings

% undo modifications from end of loop_iter
tm = tm + wv_npre;
tm = tm - local_timestamp;
tm = tm - local_winstart + 1;

nwin_local = length(dt);
figure
t = (local_winstart+(1:nwin_local))/local_fs;
plot(t,dt);
hold on
plot(t,thresh);
plot(t(tm),dt(tm),'k.','MarkerSize',10)
xlim(t([1 end]))
title(sprintf('Channel %d, [%.1f %.1f] sec',ch,bufwin_local(1)/local_fs,bufwin_local(2)/local_fs));
end % END function plot_data