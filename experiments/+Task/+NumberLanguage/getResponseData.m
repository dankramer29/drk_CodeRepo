function varargout = getResponseData(type,subtype)
% GETRESPONSEDATA Master file for response types
%
%   LIST = GETRESPONSEDATA
%   Get a list of response types.
%
%   LIST = GETRESPONSEDATA(TYPE)
%   Get a list of subtypes for TYPE.
%
%   [OPT,CHR,FCN,DSC] = GETRESPONSEDATA(TYPE,SUBTYPE)
%   Get the response data, characters, correct function, and descriptions
%   for TYPE/SUBTYPE.

% RESPONSE: language
options.language.english = 'NumberLanguage/english.wav';
descrip.language.english = 'say the number in English';
charact.language.english = {'0','1','2','3','4','5','6','7','8','9'};
correct.language.english = @Task.NumberLanguage.correctTrial_number;
options.language.german = 'NumberLanguage/german.wav';
descrip.language.german = 'say the number in German';
charact.language.german = {'0','1','2','3','4','5','6','7','8','9'};
correct.language.german = @Task.NumberLanguage.correctTrial_number;
options.language.spanish = 'NumberLanguage/spanish.wav';
descrip.language.spanish = 'say the number in Spanish';
charact.language.spanish = {'0','1','2','3','4','5','6','7','8','9'};
correct.language.spanish = @Task.NumberLanguage.correctTrial_number;
options.language.mandarin = 'NumberLanguage/mandarin.wav';
descrip.language.mandarin = 'say the number in Mandarin';
charact.language.mandarin = {'0','1','2','3','4','5','6','7','8','9'};
correct.language.mandarin = @Task.NumberLanguage.correctTrial_number;
options.language.morse = 'NumberLanguage/morse.wav';
descrip.language.morse = 'Express the number in morse code';
charact.language.morse = {'0','1','2','3','4','5','6','7','8','9'};
correct.language.morse = @Task.NumberLanguage.correctTrial_number;

% RESPONSE: math
options.math.equal = 'NumberLanguage/same.wav';
descrip.math.equal = 'say the number in English';
charact.math.equal = {'0','1','2','3','4','5','6','7','8','9'};
correct.math.equal = @Task.NumberLanguage.correctTrial_number;
options.math.minus = 'NumberLanguage/minus.wav';
descrip.math.minus = 'calculate @CATCHNUM@ minus the number and say the result';
charact.math.minus = {'0','1','2','3','4','5','6','7','8','9'};
correct.math.minus = @Task.NumberLanguage.correctTrial_minus;

% RESPONSE: actions
options.action.fingers = 'NumberLanguage/fingers.wav';
descrip.action.fingers = 'imagine holding up the same number of fingers';
charact.action.fingers = {'y','n'};
correct.action.fingers = @Task.NumberLanguage.correctTrial_yesno;
options.action.fingers_same = 'NumberLanguage/fingers_same.wav';
descrip.action.fingers_same = 'imagine holding up the same number of fingers';
charact.action.fingers_same = {'0','1','2','3','4','5','6','7','8','9'};
correct.action.fingers_same = @Task.NumberLanguage.correctTrial_number;
options.action.fingers_minus = 'NumberLanguage/fingers_minus.wav';
descrip.action.fingers_minus = 'imagine holding up the (@CATCHNUM@ - the number) fingers';
charact.action.fingers_minus = {'0','1','2','3','4','5','6','7','8','9'};
correct.action.fingers_minus = @Task.NumberLanguage.correctTrial_minus;

% provide requested information
if nargin>=2
    if nargout>=4
        varargout{4} = descrip.(type).(subtype);
    end
    if nargout>=3
        varargout{3} = correct.(type).(subtype);
    end
    if nargout>=2
        varargout{2} = charact.(type).(subtype);
    end
    if nargout>=1
        varargout{1} = options.(type).(subtype);
    end
elseif nargin>=1
    if nargout>=1
        varargout{1} = fieldnames(options.(type));
    end
else
    if nargout>=1
        varargout{1} = fieldnames(options);
    end
end