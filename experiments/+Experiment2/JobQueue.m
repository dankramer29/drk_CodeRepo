classdef JobQueue <  handle & util.StructableHierarchy
    
    properties
        maxDepth = 20; % max number of jobs supported
    end % END properties
    
    properties(GetAccess=public,SetAccess=private)
        hTask % handle to Experiment2.TaskInterface object
        queue % job queue
    end % END properties(GetAccess=public,SetAccess=private)
    
    methods
        function this = JobQueue(ht,varargin)
            
            % save parent reference
            assert(isa(ht,'Experiment2.TaskInterface'),'Must provide a handle to Experiment2.TaskInterface object');
            this.hTask = ht;
            
            % set properties via name-value pairs in varargin
            varargin = util.argobjprop(this,varargin);
            util.argempty(varargin);
            
            % initialize queue
            this.queue = Buffer.ObjectQueue(this.maxDepth);
        end % END fucntion JobQueue
        
        function val = numJobs(this)
            val = this.queue.numEntries;
        end % END function numJobs
        
        function submit(this,job,executionTime)
            
            % default execution time is now
            if nargin<3,executionTime=GetSecs;end
            
            % ensure cell array
            assert(iscell(job),'job must be a cell array');
            
            % convert string to function if necessary
            if ischar(job{1})
                job{1} = str2func(job{1});
            end
            
            % ensure function handle
            assert(isa(job{1},'function_handle'),'first element must be a function handle');
            
            % add execution time to the end of the job
            job = [job {executionTime}];
            
            % add job to queue
            this.queue.add(job);
        end % END function submit
        
        function dispatch(this)
            try
                
                % retrieve the job
                job = get(this.queue,1);
                comment(this.hTask,sprintf('dispatching job ''%s''',func2str(job{1})),3);
                
                % pull out execution time and current time
                currTime = GetSecs;
                executionTime = job{end};
                job(end) = [];
                
                % execute job or re-submit
                if (executionTime-currTime)<0
                    feval(job{:});
                else
                    submit(this,job,executionTime);
                end
            catch ME
                keyboard
                empty(this.queue);
                comment(this.hTask,'JobQueue out of sync; resetting to empty',5);
                rethrow(ME);
            end
        end % END function dispatch
        
        function tf = isempty(this)
            tf = isempty(this.queue);
        end % END function isempty
        
        function list = structableSkipFields(this)
            list = {'hTask','queue'};
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = [];
        end % END function structableManualFields
    end % END methods
end % END classdef JobQueue