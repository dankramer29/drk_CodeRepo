classdef CodeRunner < handle & util.Structable
% CODERUNNER
%
%   Support for any single-line statement
%   Support for simple for loops of the following form:
%     for LOOP_VAR = LOOP_START:LOOP_END
%       ...
%     end
%   Support for nested for loops
%
%   Example file: program.txt
%   --------------------------
%   x = X_START;
%   for k = LOOP_START:LOOP_END
%       x = x + X_INCR;
%   end
%
%   Example code:
%   -------------
%   >> c = CodeRunner('program.txt');
%   >> c.strrep(...
%       {'X_START','X_INCR','LOOP_START','LOOP_END'},...
%       {'0','1','1','3'});
%   >> c.print_code
%   x = 0;
%   for k = 1:3
%       x = x + 1;
%   end
%   >> [line,avail,code,vars] = c.step;
%   ...
%   >> c.reset

    properties(SetAccess='private',GetAccess='public')
        code = {}
        line = 1
        vars = []
        avail = false
    end % END properties(SetAccess='private',GetAccess='public')
    
    properties(Access='private')
        originalCode = {}
        keywordsWithEnds = {'for'}
        loopInfo
        loopCurr = 0
    end % END properties(Access='private')
    
    methods
        function this = CodeRunner(varargin)
            if nargin>0
                load(this,varargin{:});
            end
        end % END function CodeRunner
        
        function load(this,codefile)
            
            % validate input
            assert(exist(codefile,'file')==2,'Must provide full path to existing file');
            [~,~,codeext] = fileparts(codefile);
            assert(strcmpi(codeext,'.m')||strcmpi(codeext,'.txt'),'Must provide a *.m or *.txt file');
            
            % open the file
            [fid,errmsg] = fopen(codefile,'r');
            assert(fid>=0,'Could not open file ''%s'': %s',codefile,errmsg);
            
            % read text from the file
            this.code = cell(1,1024);
            try
                idx = 1;
                this.code{idx} = fgetl(fid);
                while ischar(this.code{idx})
                    idx = idx+1;
                    this.code{idx} = fgetl(fid);
                end
                this.code(idx:end) = [];
                assert(~isempty(this.code),'Could not read ''%s''',codefile);
            catch ME
                util.errorMessage(ME);
            end
            
            % close the text file
            fclose(fid);
            
            % save the original code
            this.originalCode = this.code;
            
            % initialize
            reset(this);
        end % END function load
        
        function strrep(this,name,val)
            name = util.ascell(name);
            val = util.ascell(val);
            assert(all(cellfun(@ischar,name))&&all(cellfun(@ischar,val)),'All inputs must be char');
            for nn=1:length(name)
                for kk=1:length(this.code)
                    this.code{kk} = regexprep(this.code{kk},name,val);
                end
            end
        end % END function set_value
        
        function [avail,line,code,varlist] = step(this)
            % step one line at a time through the code
            
            % check whether we're already at the end
            assert(this.avail>0,'No more code');
            
            % check for statements that would change the line number:
            %   end, break
            if ~isempty(regexpi(this.code{this.line},'^\s*end;?\s*$')) && this.loopCurr>0
                this.line = this.loopInfo(this.loopCurr).loop_line_start;
            elseif ~isempty(regexpi(this.code{this.line},'^\s*break;?\s*$')) && this.loopCurr>0
                this.line = this.loopInfo(this.loopCurr).loop_line_end + 1;
            end
            
            % get the current line of code
            ws1_curr_code = this.code{this.line};
            
            % special cases: loop init statements, loop end statements
            if ~isempty(regexpi(ws1_curr_code,'^\s*for'))
                % add support for "for" loops
                % do not execute the code, but do initialize the loop variable
                
                % check whether it's a new loop, or update loop condition
                if this.loopCurr>0 && this.loopInfo(this.loopCurr).loop_line_start == this.line
                    % we have looped back to the start line for the current
                    % for loop: update the loop condition
                    
                    % check for loop exit condition
                    ws1_var_idx = strcmpi({this.vars.name},this.loopInfo(this.loopCurr).loop_var_name);
                    if this.vars(ws1_var_idx).value >= this.loopInfo(this.loopCurr).loop_var_end
                        
                        % exit the loop
                        this.line = this.loopInfo(this.loopCurr).loop_line_end;
                        ws1_curr_code = 'true;'; % need to execute the line with the "end" statement, but not actually do anything
                        
                        % remove the loop info for the current loop
                        this.loopInfo(this.loopCurr) = [];
                        
                        % decrement the loop counter
                        this.loopCurr = this.loopCurr - 1;
                    else
                        
                        % replace "for x=y:z" with "x=x+1"
                        ws1_curr_code = sprintf('%s = %s + 1;',...
                            this.loopInfo(this.loopCurr).loop_var_name,...
                            this.loopInfo(this.loopCurr).loop_var_name);
                    end
                else
                    % this is a new for loop
                    
                    % increment for loop counter (support nested for loops)
                    this.loopCurr = this.loopCurr + 1;
                    
                    % get the loop var name, start/end values, start/end lines
                    ws1_tok = regexpi(ws1_curr_code,'^\s*for\s*(?<loop_var_name>\w+)\s*=\s*(?<loop_var_start>\d+):(?<loop_var_end>\d+)\s*$','names');
                    ws1_tok.loop_var_start = str2double(ws1_tok.loop_var_start);
                    ws1_tok.loop_var_end = str2double(ws1_tok.loop_var_end);
                    if isempty(this.loopInfo)
                        this.loopInfo = ws1_tok;
                    else
                        ws1_fieldnames = fieldnames(ws1_tok);
                        for ws1_ff = 1:length(ws1_fieldnames)
                            this.loopInfo(this.loopCurr).(ws1_fieldnames{ws1_ff}) = ws1_tok.(ws1_fieldnames{ws1_ff});
                        end
                    end
                    
                    % capture the starting line number
                    this.loopInfo(this.loopCurr).loop_line_start = this.line;
                    
                    % find the matching "end" statement
                    ws1_matching = 0;
                    for ws1_nn = (this.line+1):length(this.code)
                        
                        % need to make sure we find the "end" statement
                        % that matches the current loop
                        for ws1_mm = 1:length(this.keywordsWithEnds)
                            if ~isempty(regexpi(this.code{ws1_nn},sprintf('^\\s*%s',this.keywordsWithEnds{ws1_mm})))
                                ws1_matching = ws1_matching + 1;
                            end
                        end
                        
                        % capture the line and break out if matching "end"
                        if ~isempty(regexpi(this.code{ws1_nn},'^\s*end;?\s*$'))
                            if ws1_matching==0
                                this.loopInfo(this.loopCurr).loop_line_end = ws1_nn;
                                break;
                            else
                                ws1_matching = ws1_matching - 1;
                            end
                        end
                    end
                    assert(isfield(this.loopInfo(this.loopCurr),'loop_line_end') && ~isempty(this.loopInfo(this.loopCurr).loop_line_end),'Could not find matching end for the loop beginning on line %d',this.line);
                    
                    % replace "for x=y:z" with "x=y;"
                    ws1_curr_code = sprintf('%s = %d;',...
                        this.loopInfo(this.loopCurr).loop_var_name,...
                        this.loopInfo(this.loopCurr).loop_var_start);
                end
            end
            
            % load workspace variables
            for ws1_kk=1:length(this.vars)
                ws1_val = this.vars(ws1_kk).value;
                eval(sprintf('%s = ws1_val;',this.vars(ws1_kk).name));
            end
            
            % evaluate the current line of code
            eval(ws1_curr_code);
            this.line = this.line + 1;
            this.avail = length(this.code) - this.line + 1;
            
            % update workspace variables
            ws1_varlist = whos;
            ws1_varlist(~cellfun(@isempty,regexpi({ws1_varlist.name},'^this$'))) = []; % remove "this"
            ws1_varlist(~cellfun(@isempty,regexpi({ws1_varlist.name},'^ans$'))) = []; % remove "ans"
            ws1_varlist(~cellfun(@isempty,regexpi({ws1_varlist.name},'^ws1_'))) = []; % remove "ws1_*"
            this.vars = ws1_varlist;
            for ws1_kk=1:length(ws1_varlist)
                this.vars(ws1_kk).value = eval(sprintf('%s',this.vars(ws1_kk).name));
            end
            
            % assign outputs
            avail = this.avail;
            line = this.line;
            code = this.code{this.line-1};
            for ws1_kk=1:length(this.vars)
                varlist.(this.vars(ws1_kk).name) = this.vars(ws1_kk).value;
            end
        end % END function step
        
        function vr = run(this)
            assert(this.avail>0,'No more code');
            av = this.step;
            while av>0
                [av,~,~,vr] = this.step;
            end
        end % END function run
        
        function reset(this,flagCode)
            this.line = 1;
            this.avail = length(this.code);
            this.vars = [];
            this.loopInfo = [];
            this.loopCurr = 0;
            if nargin>=2 && flagCode
                this.code = this.originalCode;
            end
        end % END function reset
        
        function print_code(this)
            for kk=1:length(this.code)
                fprintf('%s\n',this.code{kk});
            end
        end % END function print_code
        
        function print_workspace(this)
            for kk=1:length(this.vars)
                fprintf('%s = %s [%s]\n',this.vars(kk).name,util.any2str(this.vars(kk).value),this.vars(kk).class);
            end
        end % END function print_workspace
        
        function st = toStruct(this,varargin)
            skip = {};
            st = toStruct@util.Structable(this,skip{:});
            st.originalCode = this.originalCode;
            st.keywordsWithEnds = this.keywordsWithEnds;
        end % END function toStruct
    end % END methods
end % END classdef CodeRunner