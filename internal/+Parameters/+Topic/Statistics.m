function [topic,props] = Statistics        

topic = struct(...
    'name','Statistics Properties',...
    'description','Properties related to statistics',...
    'id','st');

props.fdr = struct(...
    'validationFcn',@(x)islogical(x)||(isnumeric(x)&&(x==1||x==0)),...
    'default',true,...
    'attributes',struct('Description','Enable adjustment of p-values for false-discovery rate (Benjamini-Hochberg method)'));

props.q = struct(...
    'validationFcn',@isnumeric,...
    'default',0.05,...
    'attributes',struct('Description','Allowable false discovery rate'));

props.alpha = struct(...
    'validationFcn',@(x)isnumeric(x)&&x>=0&&x<=1,...
    'default',0.05,...
    'attributes',struct('Description','Significance level for hypothesis testing'));

props.nboot = struct(...
    'validationFcn',@(x)isnumeric(x)&&mod(x,1)==0,...
    'default',1e3,...
    'attributes',struct('Description','Number of bootstrap samples'));

props.nshuf = struct(...
    'validationFcn',@(x)isnumeric(x)&&mod(x,1)==0,...
    'default',1e4,...
    'attributes',struct('Description','Number of shuffle repetitions'));

props.nsamp = struct(...
    'validationFcn',@(x)isnumeric(x)&&mod(x,1)==0,...
    'default',20,...
    'attributes',struct('Description','Number of random samples (with repetition) to pull out for a shuffle distribution'));