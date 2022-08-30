function [str,bytes,lbl] = bytestr(bytes,varargin)

% possible labels
lbl = {'B','KB','MB','GB','TB'};

% track how many times the bytes are divisible by 1024
idx = 1;
while bytes>10
    bytes = bytes/1024;
    idx = idx + 1;
end

% make sure the magnitude is above 1
if bytes<1
    bytes = bytes*1024;
    idx = idx - 1;
end

% print out a string
lbl = lbl{idx};
str = sprintf('%.2f %s',bytes,lbl);