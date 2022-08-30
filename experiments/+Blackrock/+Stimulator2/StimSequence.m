classdef StimSequence < handle & util.Structable
% StimSequence Abstract interface for constructing stim seqquences
% 
% The StimSequence class is an abstract interface to construct commands
% necessary for configuring which stimulation patterns are sent to which 
% electrodes to send to the Blackrock stimulator hardware.
%
% To construct the StimSequence object:
%
% >> sequ = StimSequence;
%
% Set values either through object properties or via inputs to constructor
% or command configuration methods:
%
% >> sequ = StimSequence('duration',VAL,...);
% >> sequ.duration = VAL;
%
% Properties require to define:
% Properties         Definitions
%    duration        duration of stimulation pulse train 
%    electrode       scalar or vector list of electrode numbers

    properties       
        duration        { mustBeInRange(duration,   [0, 6]) } = 6
        electrode       { mustBeInRange(electrode,  [1, 96]), mustBeInteger }
    end % END properties
                
    methods       
        function this = StimSequence(varargin)
            
            % allow user to override any default values
            [varargin,this] = util.argobjprop(this,varargin);
            
            % allow user to provide table or struct with field names or
            % column/variable names as properties
            idx = cellfun(@(x)istable(x)||isstruct(x),varargin);
            if any(idx)
                
                % grab the input and convert to struct if needed
                p = varargin{idx};
                if istable(p),p=table2struct(p);end
                varargin(idx) = [];
                
                % look for matching fields/properties and transfer values
                fields = fieldnames(p);
                props = properties(this);
                for ff=1:length(fields)
                    idx = strcmpi(props,fields{ff});
                    if any(idx)
                        this.(props{idx}) = p.(fields{ff});
                    end
                end
            end
            
            % make sure no unused inputs
            util.argempty(varargin);
        end % END function StimCommand
                
        function configureDuration(this,dur)
            if nargin<2||isempty(dur), dur = this.duration;end
            this.duration = dur;
        end % END function configureDuration
        
        function configureElectrode(this,el)
            if nargin<2||isempty(el), el = this.electrode;end
            this.electrode = el;
        end % END function configureElectrode
        
        function isValid = isValidSequence(this)
            publicFields = properties(this);
            validFields  = cellfun(@(x) ~isempty(this.(x)), publicFields);
            isValid = all(validFields);        
        end % END function validateCMD
    end % END methods
end % END classdef Commands

function mustBeInRange(a,b)
    if any(a(:) < b(1)) || any(a(:) > b(2))
          error(['Value assigned to StimCommand2 property is not in range ',...
             num2str(b(1)),'...',num2str(b(2))])
    end
end