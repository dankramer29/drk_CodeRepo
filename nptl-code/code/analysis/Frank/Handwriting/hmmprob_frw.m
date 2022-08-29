function [pSeq] = hmmprob_frw(seq,tr,e,startProb)
%HMMDECODE calculates the posterior state probabilities of a sequence.
%   PSTATES = HMMDECODE(SEQ,TRANSITIONS,EMISSIONS) calculates the
%   posterior state probabilities, PSTATES, of sequence SEQ from a Hidden
%   Markov Model specified by transition probability matrix,  TRANSITIONS,
%   and EMISSION probability matrix, EMISSIONS. TRANSITIONS(I,J) is the
%   probability of transition from state I to state J. EMISSIONS(K,SYM) is 
%   the probability that symbol SYM is emitted from state K. The
%   posterior probability of sequence SEQ is the probability P(state at
%   step i = k | SEQ).  PSTATES is an array with the same length as SEQ and
%   one row for each state in the model. The (i,j) element of PSTATES gives
%   the probability that the model was in state i at the jth step of SEQ.
%
%   [PSTATES, LOGPSEQ] = HMMDECODE(SEQ,TR,E) returns, LOGPSEQ, the log of
%   the probability of sequence SEQ given transition matrix, TR and
%   emission matrix, E.  
%
%   [PSTATES, LOGPSEQ, FORWARD, BACKWARD, S] = HMMDECODE(SEQ,TR,E) returns
%   the forward and backward probabilities of the sequence scaled by S. 
%   The actual forward probabilities can be recovered by using:
%        f = FORWARD.*repmat(cumprod(s),size(FORWARD,1),1);
%   The actual backward probabilities can be recovered by using:
%       bscale = cumprod(S, 'reverse');
%       b = BACKWARD.*repmat([bscale(2:end), 1],size(BACKWARD,1),1);
%
%   HMMDECODE(...,'SYMBOLS',SYMBOLS) allows you to specify the symbols
%   that are emitted. SYMBOLS can be a numeric array or a cell array of the
%   names of the symbols.  The default symbols are integers 1 through M,
%   where N is the number of possible emissions.
%
%   This function always starts the model in state 1 and then makes a
%   transition to the first step using the probabilities in the first row
%   of the transition matrix. So in the example given below, the first
%   element of the output states will be 1 with probability 0.95 and 2 with
%   probability .05.
%
%   Examples:
%
% 		tr = [0.95,0.05;
%             0.10,0.90];
%           
% 		e = [1/6,  1/6,  1/6,  1/6,  1/6,  1/6;
%            1/10, 1/10, 1/10, 1/10, 1/10, 1/2;];
%
%       [seq, states] = hmmgenerate(100,tr,e);
%       pStates = hmmdecode(seq,tr,e);
%
%       [seq, states] = hmmgenerate(100,tr,e,'Symbols',...
%                 {'one','two','three','four','five','six'});
%       pStates = hmmdecode(seq,tr,e,'Symbols',...
%                 {'one','two','three','four','five','six'});
%
%   See also HMMGENERATE, HMMESTIMATE, HMMVITERBI, HMMTRAIN.

%   Reference: Biological Sequence Analysis, Durbin, Eddy, Krogh, and
%   Mitchison, Cambridge University Press, 1998.  

%   Copyright 1993-2014 The MathWorks, Inc.

numStates = size(tr,1);
numSymbols = size(e,2);

% add extra symbols to start to make algorithm cleaner at f0 and b0
seq = [numSymbols+1, seq ];
L = length(seq);

% so we introduce a scaling factor
fs = zeros(numStates,L);
fs(:,1) = startProb;

s = zeros(1,L);
s(1) = 1;

tr = tr';
for count = 2:L
    fs(:,count) = e(:,seq(count)) .* (tr*fs(:,count-1));
    
    s(count) =  sum(fs(:,count));
    fs(:,count) =  fs(:,count)./s(count);
end

pSeq = sum(log(s));



