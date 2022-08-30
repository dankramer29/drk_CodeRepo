function [topic,props] = SpectralPower        

topic = struct(...
    'name','Spectral Power Parameters',...
    'description','Parameters related to spectral power',...
    'id','spc');

props.pwr2db = struct(...
    'validationFcn',@(x)islogical(x)||(isnumeric(x)&&(x==1||x==0)),...
    'default',true,...
    'attributes',struct('Description','whether to convert power to decibels'));

props.varstab = struct(...
    'validationFcn',@(x)islogical(x)||(isnumeric(x)&&(x==1||x==0)),...
    'default',false,...
    'attributes',struct('Description','variance-stabilizing transformation'));

props.varstabmethod = struct(...
    'validationFcn',@(x)ischar(x)&&any(strcmpi(x,{'sqrt','log','atanh'})),...
    'default','log',...
    'attributes',struct('Description','variance-stabilization method: sqrt, log, or atanh'));

props.varstabparams = struct(...
    'validationFcn',@(x)true,...
    'default',[],...
    'attributes',struct('Description','parameters for variance-stabilizing transformation'));

props.norm = struct(...
    'validationFcn',@(x)islogical(x)||(isnumeric(x)&&(x==1||x==0)),...
    'default',false,...
    'attributes',struct('Description','whether to normalize the spectrogram'));

props.normsrc = struct(...
    'validationFcn',@(x)ischar(x)&&any(strcmpi(x,{'baseline','same'})),...
    'default','baseline',...
    'attributes',struct('Description','''baseline'',''same'' source of data used to calculate normalizing parameters'));

props.normmethod = struct(...
    'validationFcn',@(x)ischar(x)&&any(strcmpi(x,{'zscore','minmax','adaptive','baseline'})),...
    'default','baseline',...
    'attributes',struct('Description','''zscore'',''minmax'',''adaptive'' method to use for normalization'));

props.normparams = struct(...
    'validationFcn',@(x)true,...
    'default',[],...
    'attributes',struct('Description','parameters for normalization routine'));

props.timeavg = struct(...
    'validationFcn',@(x)islogical(x)||(isnumeric(x)&&(x==1||x==0)),...
    'default',false,...
    'attributes',struct('Description','whether to average bin counts over time (i.e. produce one average value for analysis window)'));

props.smooth = struct(...
    'validationFcn',@(x)islogical(x)||(isnumeric(x)&&(x==1||x==0)),...
    'default',false,...
    'attributes',struct('Description','whether to the smooth the bin counts'));

props.smoothmethod = struct(...
    'validationFcn',@(x)ischar(x)&&any(strcmpi(x,{'mj','moving','lowess','loess','sgolay','rlowess','rloess'})),...
    'default','moving',...
    'attributes',struct('Description','method to use for smoothing the bin counts ''mj'',or any of the built-in method ''smooth'' methods'));

props.smoothparams = struct(...
    'validationFcn',@(x)true,...
    'default',[],...
    'attributes',struct('Description','parameter to be passed to the smoothing method (all lower case fields of a struct)'));

props.freqbands = struct(...
    'validationFcn',@(x)(iscell(x)&&all(cellfun(@(z)all(ismember(size(z),[1 2])),x))) || (isnumeric(x)&&(isempty(x)||size(x,2)==2)),...
    'default',[],...
    'attributes',struct('Description','frequency bands to use when calculating band power'));

props.movingwin = struct(...
    'validationFcn',@(x)isnumeric(x)&&length(x)==2,...
    'default',[0.5 0.25],...
    'attributes',struct('Description','moving window (start,step) for calculating spectral power over time'));