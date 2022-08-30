function Caltech_LFP(ns,varargin)

% process user inputs
[varargin,lfp,~,found] = util.argflag('lfp',varargin,false);
if ~found,lfp=true;end
[varargin,spike] = util.argflag('spike',varargin,false);
[varargin,record] = util.argflag('record',varargin,false);
util.argempty(varargin);

% window size in framework cycles for spike and lfp
ns.dtMultipleEvent = 5;
ns.dtMultipleContinuous = 5;

% recording
ns.enableFileStorage = record;

% construct feature lists
st_spike.handle = @Framework.FeatureList.EventFeatureList;
st_spike.args = {};
st_lfp.handle = @Framework.FeatureList.LocalAvgLFPFeatureList;
st_lfp.args = {'N',1024,'fs',2e3,...
    'groupDefinitions',[
        struct('FrequencyBand',[0 20],'KernelType','gaussian','KernelParameters',{{9,1.3}},'SubsamplingFactor',3),...
        struct('FrequencyBand',[20 54],'KernelType','gaussian','KernelParameters',{{8,1.2}},'SubsamplingFactor',3),...
        struct('FrequencyBand',[66 150],'KernelType','gaussian','KernelParameters',{{7,1.1}},'SubsamplingFactor',3),...
        struct('FrequencyBand',[150 300],'KernelType','gaussian','KernelParameters',{{6,1.0}},'SubsamplingFactor',3),...
        struct('FrequencyBand',[300 600],'KernelType','gaussian','KernelParameters',{{5,1.0}},'SubsamplingFactor',3)],...
    'enablePlot',false,...
    };
if spike && lfp
    ns.featureListConfig = [st_spike st_lfp];
elseif lfp
    ns.featureListConfig = st_lfp;
elseif spike
    ns.featureListConfig = st_spike;
end