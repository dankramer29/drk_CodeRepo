function [dn,ds] = systime2datenum(st)
% SYSTIME2DATENUM Convert a microsoft systime structure to matlab datenum

datevec = [st([1 2 4 5 6]) st(7) + st(8)/1000];
ds = datestr(datevec,'dd-mmm-yyyy HH:MM:SS.FFF');
dn = datenum(datevec);