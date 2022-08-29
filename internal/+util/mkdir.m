function [status,msg] = mkdir(dr)
if exist(dr,'dir')==7,return;end
[status,msg] = mkdir(dr);
assert(status,'Could not create directory "%s": %s',dr,msg);
assert(exist(dr,'dir')==7,'Could not create directory "%s": unknown error',dr);
