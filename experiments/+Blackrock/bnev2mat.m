function st = bnev2mat(bnev,matfile)
% BNEV2MAT Save a Blackrock.NEV object (as struct) to a MAT file

assert(isa(bnev,'Blackrock.NEV'),'Must provide a Blackrock.NEV object, not ''%s''',class(bnev));
st = bnev.toStruct;
if nargin<2
    matfile = fullfile('.',[bnev.SourceBasename '.mat']);
end
[~,~,ext] = fileparts(matfile);
assert(strcmpi(ext,'.mat'),'Target file should have a ''.mat'' extension, not ''%s''',ext);
assert(exist(matfile,'file')~=2,'File ''%s'' already exists',matfile);
save(matfile,'-struct','st');