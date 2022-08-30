classdef Bank < handle
    properties
        scheme
        info
    end % END properties
    
    methods
        function this = Bank(s)
            assert(nargin==1&&~isempty(s)&&ischar(s),'Must provide char scheme');
            this.scheme = s;
            switch lower(this.scheme)
                case 'none'
                    this.info = cell2table({'A',1:1e6});
                case 'blackrock_nsp'
                    this.info = cell2table({'A',{1:32};'B',{33:64};'C',{65:96};'D',{97:128};},'VariableNames',{'Label','Channel'});
                case 'natus'
                    error('not implemented yet');
                otherwise
                    error('Unknown banking scheme "%s"',this.scheme);
            end
        end % END function Bank
    end % END methods
end % END classdef Bank