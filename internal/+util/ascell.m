function val = ascell(val)
% ASCELL Ensure a value is a cell array
%
%   CL = ASCELL(VAL)
%   If VAL is a cell array, it will be returned unmodified.  Otherwise, it
%   will be placed into a cell and returned.

if ~iscell(val),val={val};end