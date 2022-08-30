classdef Responsive < handle & util.Structable
    properties(GetAccess=public,SetAccess=private)
        hTask
        idxResponse
        idxCharacters
        responseCharacters
        expectedResponses
        flagEnableResponseEdits = false;
    end % END properties(GetAccess=public,SetAccess=private)
    
    methods
        function this = Responsive(hTask,varargin)
            
            % validate inputs
            assert(isa(hTask,'Experiment2.TaskInterface'),'Must provide handle to Experiment2.TaskInterface object, not ''%s''',class(hTask));
            assert(~isempty(hTask.hKeyboard)&&isa(hTask.hKeyboard,'Keyboard.Input'),'The TaskInterface object must be configured to use Keyboard.Input, not ''%s''',class(hTask.hKeyboard));
            this.hTask = hTask;
            
            % initialize properties
            this.idxResponse = nan;
            this.idxCharacters = 0;
            
            % check for edit flag
            if any(strncmpi(varargin,'editresponses',4))
                this.flagEnableResponseEdits = true;
                
                % add the "editresponse" keypress entry
                if ~this.hTask.hKeyboard.isRegistered('editresponse')
                    this.hTask.hKeyboard.register('editresponse',{},{'backspace','return'});
                end
                
                % add the "editresponse" keypress to expected responses
                this.addExpectedResponse('editresponse',{'return'},0.25,0.5);
            end
        end % END function Responsive
        
        function addExpectedResponse(this,name,keys,timeout,probs)
            
            % validate input
            assert(ischar(name),'Must provide name and str as char');
            assert(iscell(keys)&&all(cellfun(@ischar,keys)),'Must provide keys as a list of string key names');
            assert(isnumeric(timeout)&&isnumeric(probs),'Must provide timeout and probs as numeric');
            
            % add response to the list
            if isempty(this.expectedResponses)
                this.expectedResponses = struct('name',name,'characters',{keys},'timeout',timeout,'probability',probs);
            else
                this.expectedResponses(end+1) = struct('name',name,'characters',{keys},'timeout',timeout,'probability',probs);
            end
        end % END function addExpectedResponse
        
        function expectInput(this,name)
            if nargin==1 || isempty(name)
                
                % no name provided - anything from any response
                expectations = arrayfun(@(x){x.name,x.characters,x.timeout,x.probability},this.expectedResponses,'UniformOutput',false);
                this.hTask.expectInput(expectations{:});
            else
                
                % name provided - expect only from that response
                which = strcmpi({this.expectedResponses.name},name);
                assert(any(which),'Could not find expected response matching name ''%s''',name);
                x = this.expectedResponses(which);
                this.hTask.expectInput({x.name,x.characters(min(length(x.characters),this.idxCharacters+1)),x.timeout,x.probability});
            end
        end % END function expectInput
        
        function [done,name,str] = checkResponseInputs(this)
            done = false;
            name = '';
            str = '';
            
            % check for inputs for any of the expected responses
            names = arrayfun(@(x)x.name,this.expectedResponses,'UniformOutput',false);
            inputs = cell(1,length(names));
            [inputs{:}] = this.hTask.hKeyboard.check(names{:});
            
            % loop over inputs
            for nn=1:length(inputs)
                if ~isempty(inputs{nn})
                    
                    % check for too many keys pressed
                    if length(inputs{nn}.anykeys)>1
                        comment(this.hTask,'Detected multiple keypresses but expected only one - please try again!',1);
                        return;
                    end
                    
                    % handle "editresponse" differently
                    if this.flagEnableResponseEdits && strcmpi(names{nn},'editresponse')
                        if strcmpi(inputs{nn}.anykeys{1},'backspace')
                            
                            % delete the current character and move back 1
                            if this.idxCharacters>0
                                this.responseCharacters{this.idxCharacters} = [];
                                this.idxCharacters = this.idxCharacters - 1;
                            end
                            if this.idxCharacters==0
                                this.idxResponse = nan;
                            end
                        elseif strcmpi(inputs{nn}.anykeys{1},'return')
                            if isnan(this.idxResponse)
                                comment(this.hTask,'Empty responses not allowed',1);
                            else
                                
                                % enter signifies done with response
                                done = true;
                                name = this.expectedResponses(this.idxResponse).name;
                                str = cat(2,this.responseCharacters{:});
                                return;
                            end
                        end
                        
                        % set up to expect another input
                        if isnan(this.idxResponse)
                            
                            % update the user
                            comment(this.hTask,'Current response string: [EMPTY]',1);
                            
                            % expect any character from any expected
                            this.expectInput;
                        else
                            
                            % update the user
                            comment(this.hTask,sprintf('Current response string: %s',cat(2,this.responseCharacters{:})),1);
                            
                            % only expect more characters from current
                            this.expectInput(this.expectedResponses(this.idxResponse).name);
                        end
                        
                        % return immediately (do not process any others)
                        return;
                    else
                        
                        % make sure new inputs falls under same response
                        if isnan(this.idxResponse)
                            this.idxResponse = nn;
                            this.responseCharacters = cell(1,255);
                        else
                            if this.idxResponse~=nn
                                comment(this.hTask,sprintf('Response already started for ''%s''; current input ''%s'' belongs to ''%s'' (not allowed)',this.expectedResponses(this.idxResponse).name,inputs{nn}.anykeys{1},this.expectedResponses(nn).name),1);
                                continue;
                            end
                        end
                        
                        % save the input key
                        this.idxCharacters = this.idxCharacters + 1;
                        this.responseCharacters{this.idxCharacters} = inputs{nn}.anykeys{1};
                        
                        % update the user
                          comment(this.hTask,sprintf('Current response string: %s',cat(2,this.responseCharacters{:})),1);
                        
                        % set up to end, or expect another input
%                         if ~this.flagEnableResponseEdits && this.idxCharacters==length(this.expectedResponses(nn).characters) % for Stroop Task
                        if ~this.flagEnableResponseEdits && this.idxCharacters>=length(this.expectedResponses(nn).characters) % for Stim Tasks
                            done = true;
                            name = this.expectedResponses(this.idxResponse).name;
                            str = cat(2,this.responseCharacters{:});
                        elseif this.idxCharacters < length(this.expectedResponses(nn).characters)
                            this.expectInput(this.expectedResponses(this.idxResponse).name);
                        end
                        
                        % return immediately (do not process any others)
                        return;
                    end
                end
            end
        end % END function checkResponseInputs
        
        function resetInput(this)
            
            % disable the keypress combinations
            names = arrayfun(@(x)x.name,this.expectedResponses,'UniformOutput',false);
            this.hTask.resetInput(names{:});
        end % END function resetInput
        
        function st = toStruct(this,varargin)
            skip = [{'hTask'} varargin];
            st = toStruct@util.Structable(this,skip{:});
        end % END function toStruct
    end % END methods
end % END classdef Responsive