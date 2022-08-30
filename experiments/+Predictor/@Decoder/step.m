function step(obj, options)

if nargin==1; options=[]; end

% check to see if the Linear Control Form representation exists, it it
% does, show step response.

if isprop(obj, 'LCF') && isfield(obj.LCF, 'Sys')
    step(obj.LCF.Sys);
  
end