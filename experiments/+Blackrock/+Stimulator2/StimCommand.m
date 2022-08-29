classdef StimCommand < handle & util.Structable
% STIMCOMMAND Abstract interface for constructing stim commands
% 
% The StimCommand class is an abstract interface to construct commands
% necessary for configuring waveforms, electrodes, etc. to send to the
% Blackrock stimulator hardware.
%
% To construct the StimCommand object:
%
% >> cmd = StimCommand;
%
% Set values either through object properties or via inputs to constructor
% or command configuration methods:
%
% >> cmd = StimCommand('polarity',VAL,...); % etc
% >> cmd.polarity = VAL; % etc
% >> cmd.configureWaveform('polarity'
%
% Properties require to define:
% Properties         Definitions
%    waveformID      waveform ID (scalar integer >=1, <=15)
%    polarity        polarity of the waveform (1 - cathodic first, 2 - anodic first)
%    numPulses       number of pulses in the waveform (scalar integer >=1, <=255)
%    amplitude       amplitude in uA (scalar integer >= 1, <= 215)
%    phaseWidth      phase width in usec (scalar integer >= 44, <= 65535
%    frequency       frequency in Hz (scalar integer >= 4, <= 5000)
%    interphase      interphase interval in usec (scalar integer >= 53, <= 65535)
%
%    duration        duration of stimulation pulse train 
%    electrode       scalar or vector list of electrode numbers

    properties
        waveformID      { mustBeMember(waveformID,  [1:16]) } = 1
        polarity        { mustBeMember(polarity,    [0, 1]) }
        numPulses       { mustBeInRange(numPulses,  [1, 255]), mustBeInteger } %same as in blackrock
        amplitude       { mustBeInRange(amplitude,  [500, 10000]) } % BR : 1-215 uA
        phaseWidth      { mustBeInRange(phaseWidth, [44, 1000]) } % BR: 44-65535 us
        frequency       { mustBeInRange(frequency,  [4, 5000]) }  %same as in blackrock
        interphase      { mustBeInRange(interphase, [53, 200]) } % BR: 44-65535 us
        duration        { mustBeInRange(duration,   [0, 60]) } = 60
        electrode       { mustBeInRange(electrode,  [1, 96]), mustBeInteger }

    end % END properties
                
    methods       
        function this = StimCommand(varargin)
            
            % allow user to override any default values
            varargin = util.argobjprop(this,varargin);
            
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
        
        function configureWaveform(this,wid,pol,np,amp,pw,freq,ip)
            if nargin<2||isempty(wid),  wid  = this.waveformID; end
            if nargin<3||isempty(pol),  pol  = this.polarity;   end
            if nargin<4||isempty(np),   np   = this.numPulses;  end
            if nargin<5||isempty(amp),  amp  = this.amplitude;  end
            if nargin<6||isempty(pw),   pw   = this.phaseWidth; end
            if nargin<7||isempty(freq), freq = this.frequency;  end
            if nargin<8||isempty(ip),   ip   = this.interphase; end
            
            % special case for waveform ID
            if isempty(wid), wid=1;end
                        
            % update values (and validate them)
            this.waveformID = wid;
            this.polarity   = pol;
            this.numPulses  = np;
            this.amplitude  = amp;
            this.phaseWidth = pw;
            this.frequency  = freq;
            this.interphase = ip;            
        end % END function configureWaveform
                
        function configureDuration(this,dur)
            if nargin<2||isempty(dur), dur = this.duration;end
            this.duration = dur;
        end % END function configureDuration
        
        function configureElectrode(this,el)
            if nargin<2||isempty(el), el = this.electrode;end
            this.electrode = el;
        end % END function configureElectrode
        
        function isValid = isValidCommand(this)
            publicFields = properties(this);
            validFields  = cellfun(@(x) ~isempty(this.(x)), publicFields);
            isValid = all(validFields);        
        end % END function validateCMD
        
        function output = toString(this)
            publicFields = properties(this);
            fieldAbbreviations = {'ID', 'pol', 'nPuls', 'amp', 'pw', 'freq', 'inPh', 'dur', 'elc'}';
            output = cell2mat(cellfun(@(x,y) [x ': ' num2str(this.(y)) ', '], fieldAbbreviations, publicFields, 'un', 0)');
        end
    end % END methods
end % END classdef Commands

function mustBeInRange(a,b)
    if any(a(:) < b(1)) || any(a(:) > b(2))
          error(['Value assigned to StimCommand2 property is not in range ',...
             num2str(b(1)),'...',num2str(b(2))])
    end
end