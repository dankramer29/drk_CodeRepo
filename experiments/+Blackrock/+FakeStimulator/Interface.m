classdef Interface < Blackrock.Stimulator2.Interface & util.Structable
    % Fake Interface encapsulate communication with the stimulator server.
    %
    %   EXAMPLE:
    %   >> hStimulator2 = Blackrock.Stimulator2.Interface;
    %   >> 
    %   >> cmd = Blackrock.Stimulator2.StimCommand;
    %   >> cmd.configureWaveform(1, 0, 5, 50, 200, 150, 53);
    %   >> cmd.electrode = 1;
    %   >> cmd.duration = 1;
    %   >> 
    %   >> hStimulator2.configure(cmd);
    %   >> hStimulator2.start(cmd);
    %   >> 
    %   >> //DO SOMETHING
    %   >> 
    %   >> hStimulator2.stop();
    %   >> hStimulator2.close();
    %
    %   See BLACKROCK.STIMULATOR2.INTERFACE.
        
    properties(Access=private)
        
        isOpen = false;                 % whether the interface is open
        isSequenceLoaded = false;       % whether a sequence is loaded
        
    end
        
    methods
        function this = Interface(varargin)
            % INTERFACE Constructor for the Interface class
            %
            %   S = INTERFACE
            %   Create an object of the Blackrock.Stimulator2/Interface.  
            %   Default values for each property are listed below. Any  
            %   publically writeable property may be set as a keyword-value 
            %   input pair in the arguments of the constructor.  Use the 
            %   MATLAB 'properties' function to get a list of all 
            %   properties of this class.
            %
            %   STIMINTERFACE(...,'VERBOSE',TRUE)
            %   STIMINTERFACE(...,'VERBOSE',FALSE)
            %   Enable or disable verbosity.
            %
            %   See also BLACKROCK.STIMULATOR2/INTERFACE.
            
            % call dummy version of super class constructor
            this@Blackrock.Stimulator2.Interface('dummy', 1);
            
            % load debug/verbosity HST env vars
            [this.debug,this.verbosity] = env.get('debug','verbosity');
            this.commentFcn = {@cmdWindowOutput, this};
            
            this.isOpen = true;
            cmdWindowOutput(this, 'Fake Blackrock Stimulator is open', 3);
        end % END function Interface               
        
        
        function enableTrigger(this, edge)
            % ENABLETRIGGER set enable trigger for stimulator
            %
            %   ENABLETRIGGER(THIS, EDGE)
            %   Sends command to stimulator object to enable stimulation on
            %   trigger input. EDGE sets mode (1 - rising (low to high), 2
            %   - falling (high to low), 3 - either rising or falling).
            %   Default value is rising.
            
            comment(this, sprintf('Fake Trigger enabled, mode set: %d', edge), 7);
        end
        
        
        function disableTrigger(this)
            % DISABLETRIGGER disable trigger for stimulator
            %
            %   DISABLETRIGGER(THIS)
            %   Sends command to stimulator object to disation stimulation on
            %   trigger input. 

            comment(this, 'Fake Trigger disabled.', 7);
        end
            
            
        function start(this, cmd)
            % START Stop stimulating
            %
            %   START(THIS, CMD)
            %   Sends command to stimulator object to begin stimulating.
            %   Runs check to ensure compliance with injected charge limits
            %   and maximum allowable charge per phase / amplitude / etc. 
            %   CMD must be a Blackrock.Stimulator2.StimCommand object.
            
            % check if cmd is safe
            %validate(this,cmd);
                        
            % if sequence isn't laoded, load
            if ~this.isSequenceLoaded, configure(this, cmd); end                                   
            assert(this.isSequenceLoaded, 'Sequence must be loaded to play stimulation');
                        
            % turn on stimulation
            comment(this, sprintf('Fake Stimulator On. [%d sec] [Params: %s]', cmd.duration, cmd.toString()), 3);
        end % END function start
        
        
        function stop(this)
            % STOP Stop stimulating
            %
            %   STOP(THIS)
            %   Sends command to stimulator object to stop stimulating
            
            comment(this, 'Fake Stimulator stopped.', 7);
        end % END function stop
   
        function output = configure(this, cmd)
            % CONFIGURE Update local stimulator object with waveform and
            % sequence information
            %
            %   CONFIGURE(THIS, CMD)
            %   Set values for waveform pattern and set all electrodes to
            %   stimulate that pattern simultaneously for specified 
            %   duration. CMD must be a Blackrock.Stimulator2.StimCommand
            %   object.
            
            try 
                this.configurePattern(cmd);
                this.configureBasicSequence(cmd.waveformID, cmd.electrode);
                output = true;
                
            catch ME
                util.errorMessage(ME);
                output = false;
            end
        end % END function configure
        
        function close(this)
            % CLOSE Close the STIMMEX interface
            %
            %   CLOSE(THIS)
            %   If recording, stop recording, then close the CBMEX
            %   interface.
            
            % make sure the interface is open
            assert(this.isOpen,'STIMMEX not open');
            
            comment(this, 'Fake Stimulator disconnected.', 3);

            this.isOpen = false;            
        end % END function close
        
        function skip = structableSkipFields(this)
            skip = {};
            skip1 = structableSkipFields@Blackrock.Stimulator2.Interface(this);
            skip = [skip skip1];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = [];
            st1 = structableManualFields@Blackrock.Stimulator2.Interface(this);
            st = util.catstruct(st,st1);
        end % END function structableManualFields
        
        function delete(this)
            % DELETE Delete the object
            %
            %   DELETE(THIS)
            %   If the Interface is open, close it, then delete the object
            %   as normal.
            
            % if open, close
            if this.isOpen, close(this); end
        end % END function delete
                
    end % END methods
    
    methods(Access='private')              
        function configurePattern(this, cmd)
            % CONFIGUREPATTERN update Blackrock CereStim96 waveform
            %
            %   CONFIGUREPATTERN(THIS,CMD)
            %   Update local stimulation object with waveform parameters
            %   and send pattern to stimulator via stimmex (handled by
            %   stimulator object)

            assert(this.isOpen, 'Interface must be open to send a command');
            assert(isa(cmd, 'Blackrock.Stimulator2.StimCommand'), 'Must send a Blackrock.Stimulator2.StimCommand object');
            assert(cmd.isValidCommand(), 'Must be a valid command');

        end % END function configure
        
        
        function configureBasicSequence(this, wid, el)
            % CONFIGUREBASICSEQUENCE update Blackrock CereStim96 seqeunce
            %
            %   CONFIGUREBASICSEQUENCE(THIS, WID, EL)
            %   Update local stimulation object with the set of electrode
            %   to be stimulated in which order and what duration
                                   
            % sequence loaded
            this.isSequenceLoaded = true;            
                        
        end % END function configureBasicSequence
                
        function cmdWindowOutput(this,msg,vb)
            % CMDWINDOWOUTPUT Internal function for printing messages
            %
            %   CMDWINDOWOUTPUT(THIS,MSG)
            %   Print the string in MSG to the screen with the '[CBMEX]'
            %   identifier prepended.
            %
            %   CMDWINDOWOUTPUT(...,ARG1,ARG2,...,ARGn)
            %   Provide additional arguments which will be passed directly
            %   to the COMMENT method of this class.
            %
            %   See also BLACKROCK.INTERFACE/COMMENT.
            if vb<=this.verbosity, fprintf('[FAKE STIMMEX] %s\n', msg); end
        end % END function cmdWindowOutput
    end % END methods
    
end % END classdef Interface