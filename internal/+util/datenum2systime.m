function st = datenum2systime(dn)
% DATENUM2SYSTIME Convert matlab datenum to microsoft systemtime structure
%
%   systime: [year month day-of-week day hour minute second millisecond]
%   datevec: [year month             day hour minute second            ]
%
%   note that windows SYSTEMTIME structure's day-of-week is zero-based
%   whereas MATLAB's is one-based, hence -1.

% source date
if nargin==0||isempty(dn)
    dn=now;
end
tm = datevec(dn);

% conversion
st = uint16([tm(1:2) weekday(dn)-1 tm(3:5) floor(tm(6)) 1e3*mod(tm(6),1)]);