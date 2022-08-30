classdef StimCommand < Utilities.Structable
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
    
    properties
        electrode % scalar or vector list of electrode numbers
        numPulses % number of pulses in the waveform (scalar integer >=1, <=255)
        polarity % polarity of the waveform (1 - cathodic first, 2 - anodic first)
        phaseWidth % phase width in usec (scalar integer >= 44, <= 65535
        frequency % frequency in Hz (scalar integer >= 4, <= 5000)
        amplitude % amplitude in uA (scalar integer >= 1, <= 215)
        interphase % interphase interval in usec (scalar integer >= 53, <= 65535)
        waveformID = 1 % waveform ID (scalar integer >=1, <=15)
        duration = 6 % duration of stimulation pulse train (nan for no duration setting)
    end % END properties
    
    properties(Access=private)
        rangeElectrode = [1 96]; % valid range of values for electrode
        rangeNumPulses = [1 255]; % valid range of values for numPulses
        rangePolarity = [0 1]; % valid range of values for polarity
        rangePhaseWidth = [44 65535]; % valid range of values for phaseWidth
        rangeFrequency = [4 5000]; % valid range of values for frequency
        rangeAmplitude = [1 215]; %  valid range of values for amplitude
        rangeInterphase = [53 65535]; % valid range of values for interphase
        rangeWaveformID = [1 15]; % valid range of values for waveformID
        rangeDuration = [0 6]; % valid range of values for duration
    end % END properties(Access=private)
    methods
        function set.electrode(this,val)
            validateElectrode(this,val);
            this.electrode = val;
        end % END function set.electrode
        function set.waveformID(this,val)
            validateWaveformID(this,val);
            this.waveformID = val;
        end % END function set.waveformID
        function set.numPulses(this,val)
            validateNumPulses(this,val);
            this.numPulses = val;
        end % END function set.numPulses
        function set.polarity(this,val)
            validatePolarity(this,val);
            this.polarity = val;
        end % END function set.polarity
        function set.phaseWidth(this,val)
            validatePhaseWidth(this,val);
            this.phaseWidth = val;
        end % END function set.phaseWidth
        function set.frequency(this,val)
            validateFrequency(this,val);
            this.frequency = val;
        end % END function set.frequency
        function set.amplitude(this,val)
            validateAmplitude(this,val);
            this.amplitude = val;
        end % END function set.amplitude
        function set.interphase(this,val)
            validateInterphase(this,val);
            this.interphase = val;
        end % END function set.interphase
        function set.duration(this,val)
            validateDuration(this,val);
            this.duration = val;
        end % END function set.duration
        
        function this = StimCommand(varargin)
            
            % allow user to override any default values
            [varargin,this] = Utilities.ProcVarargin(varargin,this);
            
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
            Utilities.ProcVarargin(varargin);
        end % END function StimCommand
        
        function cmd = configureWaveform(this,wid,pol,np,amp,pw,freq,ip)
            if nargin<2||isempty(wid),wid=this.waveformID;end
            if nargin<3||isempty(pol),pol=this.polarity;end
            if nargin<4||isempty(np),np=this.numPulses;end
            if nargin<5||isempty(amp),amp=this.amplitude;end
            if nargin<6||isempty(pw),pw=this.phaseWidth;end
            if nargin<7||isempty(freq),freq=this.frequency;end
            if nargin<8||isempty(ip),ip=this.interphase;end
            
            % special case for waveform ID
            if isempty(wid),wid=1;end
            
            % validate values
            validateWaveformID(this,wid);
            validatePolarity(this,pol);
            validateNumPulses(this,np);
            validateAmplitude(this,amp);
            validatePhaseWidth(this,pw);
            validateFrequency(this,freq);
            validateInterphase(this,ip);
            
            % command format: 
            % w:WAVEFORMID,POLARITY,NUM_PULSES,AMP1,AMP2,PW1,PW2,FREQ,INTERPHASE_TIME;
            cmd = sprintf('w:%d,%d,%d,%d,%d,%d,%d,%d,%d;',wid,pol,np,amp,amp,pw,pw,freq,ip);
        end % END function configureWaveform
        
        function cmd = configureDuration(this,dur)
            if nargin<2||isempty(dur),dur=this.duration;end
            validateDuration(this,dur);
            cmd = sprintf('a:%g;',dur);
        end % END function configureDuration
        
        function cmd = configureElectrode(this,el,wid)
            if nargin<2||isempty(el),el=this.electrode;end
            if nargin<3||isempty(wid)
                wid = repmat(this.waveformID,size(el)); 
            end
            if length(wid) ~= length(el); wid = wid*ones(size(el)); end
            validateElectrode(this,el);
            cmd = sprintf('q:');
            for kk=1:length(el)
                cmd = sprintf('%s%d,%d,',cmd,el(kk),wid(kk));
            end
            cmd(end) = ';';
        end % END function configureElectrode
        
        function cmd = start(~)
            cmd = 's;';
        end % END function start
        
        function cmd = stop(~)
            cmd = 't;';
        end % END function stop
    end % END methods
    
    methods(Access=private)
        function validateElectrode(this,el)
            assert(isnumeric(el)&&all(round(el)==el)&&all(isfinite(el)),'Electrode must be finite integer');
            assert(all(el >= repmat(this.rangeElectrode(1),size(el)) & el <= repmat(this.rangeElectrode(2),size(el))),'Electrode(s) must be in the range [%d %d]',this.rangeElectrode(1),this.rangeElectrode(2));
        end % END function validateElectrode
        
        function validateWaveformID(this,wid)
            assert(isnumeric(wid)&&isscalar(wid)&&round(wid)==wid&&all(isfinite(wid)),'Waveform ID must be a finite scalar integer');
            assert(wid>=this.rangeWaveformID(1)&&wid<=this.rangeWaveformID(2),'Waveform ID must be in the range [%d %d]',this.rangeWaveformID(1),this.rangeWaveformID(2));
        end % END function validateWaveformID
        
        function validatePolarity(this,pol)
            assert(isnumeric(pol)&&isscalar(pol)&&round(pol)==pol&&all(isfinite(pol)),'Polarity must be a finite scalar integer');
            assert(pol>=this.rangePolarity(1)&&pol<=this.rangePolarity(2),'Polarity must be in the range [%d %d]',this.rangePolarity(1),this.rangePolarity(2));
        end % END function validatepolarity
        
        function validateNumPulses(this,np)
            assert(isnumeric(np)&&isscalar(np)&&round(np)==np&&all(isfinite(np)),'Number of pulses must be a finite scalar integer');
            assert(np>=this.rangeNumPulses(1)&&np<=this.rangeNumPulses(2),'Number of pulses must be in the range [%d %d]',this.rangeNumPulses(1),this.rangeNumPulses(2));
        end % END function validateNumPulses
        
        function validateAmplitude(this,amp)
            assert(isnumeric(amp)&&isscalar(amp)&&round(amp)==amp&&all(isfinite(amp)),'Amplitude must be a finite scalar integer');
            assert(amp>=this.rangeAmplitude(1)&&amp<=this.rangeAmplitude(2),'Amplitude must be in the range [%d %d]',this.rangeAmplitude(1),this.rangeAmplitude(2));
        end % END function validateAmplitude
        
        function validatePhaseWidth(this,pw)
            assert(isnumeric(pw)&&isscalar(pw)&&round(pw)==pw&&all(isfinite(pw)),'Phase width must be a finite scalar integer');
            assert(pw>=this.rangePhaseWidth(1)&&pw<=this.rangePhaseWidth(2),'Phase width must be in the range [%d %d]',this.rangePhaseWidth(1),this.rangePhaseWidth(2));
        end % END function validatePhaseWidth
        
        function validateFrequency(this,freq)
            assert(isnumeric(freq)&&isscalar(freq)&&round(freq)==freq&&all(isfinite(freq)),'Frequency must be a finite scalar integer');
            assert(freq>=this.rangeFrequency(1)&&freq<=this.rangeFrequency(2),'Frequency must be in the range [%d %d]',this.rangeFrequency(1),this.rangeFrequency(2));
        end % END function validateFrequency
        
        function validateInterphase(this,ip)
            assert(isnumeric(ip)&&isscalar(ip)&&round(ip)==ip&&all(isfinite(ip)),'Interphase interval must be a finite scalar integer');
            assert(ip>=this.rangeInterphase(1)&&ip<=this.rangeInterphase(2),'Interphase interval must be in the range [%d %d]',this.rangeInterphase(1),this.rangeInterphase(2));
        end % END function validateInterphase
        
        function validateDuration(this,dur)
            assert(isnumeric(dur)&&isscalar(dur),'Duration must be a finite scalar');
            assert(dur>=this.rangeDuration(1)&&dur<=this.rangeDuration(2),'Duration must be in the range [%g %g]',this.rangeDuration(1),this.rangeDuration(2));
        end % END function validateDuration
    end % END methods(Access=private)
end % END classdef Commands