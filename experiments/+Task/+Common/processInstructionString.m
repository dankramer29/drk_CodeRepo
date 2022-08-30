function str = processInstructionString(str,symbols)
% PROCESSINSTRUCTIONSTRING Replace symbols with values
%
%   STR = PROCESSINSTRUCTIONSTRING(STR,SYM)
%   Replace symbols in STR with values. Input SYM is a cell array of cell
%   arrays, where each internal cell array contains two cells:
%   {SYMBOL,VALUE}. SYMBOL has traditionally been something like
%   '@NUMBER@', and VALUE would be the specific replacement, e.g. '5'. In
%   this way, instructions can be prepared generically but customized per
%   run of the task.
for ss=1:length(symbols)
    assert(iscell(symbols{ss}),'Symbols input must be a cell array of cell arrays');
    str = strrep(str,symbols{ss}{1},symbols{ss}{2});
end