function timerFcn_lean(this)

% update internal frame counter
this.frameId = this.hTimer.TasksExecuted;
add( this.buffers,'frameId',this.frameId );

% Note
%
% This used to be in a single try-catch statement, but then an error in an
% early stage meant that, for example, stop requests were not processed --
% and so it was impossible to stop the Framework for recurring errors in
% the task update.
%
% The updated philosophy is to allow segments to operate sequentially even
% when previous stages have generated errors.

% updating the eye tracker
try
    if this.options.enableEyeTracker
        
        % update eye tracker
        pupil_vals = read( this.hEyeTracker );
    end
catch ME
    errorHandler( this,ME,false );
end

% updating the task
try
    if this.options.enableTask
        
        % update task
        update( this.hTask );
    end
catch ME
    errorHandler( this,ME,false );
end

% updating the sync pulse (specifically placed after task update)
try
    if this.options.enableSync
        
        % update sync
        update( this.hSync );
    end
catch ME
    errorHandler( this,ME,false );
end

% direct call to refresh display (specifically after task, before predict)
try
    if this.options.enableTask && this.options.taskDisplayRefresh
        
        % refresh the task display
        refresh( this.hTask );
    end
catch ME
    errorHandler( this,ME,false );
end

% collect neural data
try
    if this.options.enableNeural
        
        % just get the timestamp
        neuralTimes = this.hNeuralSource.time;
    end
catch ME
    errorHandler( this,ME,false );
end

% update buffers with current state
try
    
    % add results so far to the buffers
    if this.options.enableNeural
        this.buffers.add('neuralTime',neuralTimes(:)');
    end
    if this.options.enableEyeTracker
        buffnames = fieldnames(pupil_vals);
        for bb = 1:length(buffnames)
            add (this.buffers, buffnames{bb},pupil_vals.(buffnames{bb}));
        end
    end
    
catch ME
    errorHandler( this,ME,false );
end

% administrative tasks: framework internal properties update
try
    
    % buffer timing information
    add( this.buffers,'instantPeriod',this.hTimer.InstantPeriod );
    add( this.buffers,'computerTime',now );
    add( this.buffers,'elapsedTime',toc(this.runtime.tic) );
    
    % framework limits check
    chk = runtimeLimitCheck(this);
    if chk && ~this.runtime.limitProcessed
        feval( this.options.limitFcn,this );
        this.runtime.limitProcessed = true;
    end
catch ME
    errorHandler( this,ME,false );
end

% finally, the internal update
try
    
    % framework's internal update
    internalUpdate( this );
catch ME
    errorHandler( this,ME,false );
end

% force event handling
drawnow;
