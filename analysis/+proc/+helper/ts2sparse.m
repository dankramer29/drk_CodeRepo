function sp = ts2sparse(ts,varargin)
% TS2SPARSE Convert cell arrays of timestamps into a sparse logical matrix
%
%   SP = TS2SPARSE(TS)
%   For cell array TS, with one cell per feature/trial/etc. and in each
%   cell a row or column vector containing a list of timestamps, produce a
%   sparse logical matrix SP which contains one column per feature/trial
%   and one row per sample; its contents are a logical true value at the
%   corresponding row/column for each timestamp.
%
%   SP = TS2SPARSE(...,'NUMSAMPLES',N)
%   Specify the number of samples (i.e., number of rows) to allocate in the
%   sparse logical matrix SP. If N is not provided, it will be inferred
%   from the maximum value in TS.

% validate inputs
ts = util.ascell(ts);
assert(all(cellfun(@isnumeric,ts)),'TS input must be a cell array of numerical vectors containing timestamps for each feature/trial/etc.');
num_features = length(ts);

% get max timestamp
max_timestamp = max(cellfun(@max,ts));
[varargin,num_timestamps] = util.argkeyval('numsamples',varargin,max_timestamp);
util.argempty(varargin);

% pull out rows: the timestamps
row = cellfun(@(x)round(double(x(:)')),ts,'UniformOutput',false);

% pull out cols: the feature index
col = arrayfun(@(x)x*ones(1,length(row{x})),1:num_features,'UniformOutput',false);

% pull out values: logical ones
val = cellfun(@(x)true(1,length(x)),row,'UniformOutput',false);

% cat them all
col = cat(2,col{:});
row = cat(2,row{:});
val = cat(2,val{:});

% create sparse matrix
sp = sparse(row,col,val,num_timestamps,num_features);