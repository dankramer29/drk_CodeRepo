function [dn,ds] = systime2datenum(st)
% SYSTIME2DATENUM Convert microsoft systemtime structure to matlab datenum
%
%   systime: [year month day-of-week day hour minute second millisecond]
%   datevec: [year month             day hour minute second            ]
%
%   outputs are the datenum and a string representation of the datenum.
%
%   note that windows SYSTEMTIME structure's day-of-week is zero-based
%   whereas MATLAB's is one-based, hence -1.

dv = [st([1 2 4 5 6]) st(7) + st(8)/1000];
ds = datestr(dv,'dd-mmm-yyyy HH:MM:SS.FFF');
dn = datenum(dv);