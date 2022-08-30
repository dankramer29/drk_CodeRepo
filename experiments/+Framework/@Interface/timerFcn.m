function timerFcn(this)

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
        pupil_vals = read( this.hEyeTracker );
    end
catch ME
    errorHandler( this,ME,false );
end

% updating the task
try
    if this.options.enableTask
        update( this.hTask );
    end
catch ME
    errorHandler( this,ME,false );
end

% retrieve current status
try
    if this.options.enableTask
        this.state = this.hTask.getState;
        this.target = this.hTask.getTarget;
    end
catch ME
    errorHandler( this,ME,false );
end

% updating the sync pulse (specifically placed after task update)
try
    if this.options.enableSync
        update( this.hSync );
    end
catch ME
    errorHandler( this,ME,false );
end

% direct call to refresh display (specifically after task, before predict)
try
    if this.options.enableTask && this.options.taskDisplayRefresh
        refresh( this.hTask );
    end
catch ME
    errorHandler( this,ME,false );
end

% collect neural data
try
    if this.options.enableNeural
        [neuralTimes,z] = read( this.hNeuralSource );
    end
catch ME
    errorHandler( this,ME,false );
end

% update buffers with current state
try
    
    % add results so far to the buffers
    if this.options.enableTask || this.options.enablePredictor
        add( this.buffers,'state',this.state(:)' );
    end
    if this.options.enableTask
        add( this.buffers,'target',this.target(:)' );
    end
    if this.options.enableNeural
        add( this.buffers,'neuralTime',neuralTimes(:)' );
        add( this.buffers,'features',z(:)' );
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

% state prediction
try
    if this.options.enablePredictor
        
        % get prediction
        this.state = Predict( this.hPredictor,this.state(:),z(:),this.target(:) );
        add( this.buffers,'prediction',this.state(:)' );
        if this.options.enableTask
            
            % send state to task
            setState( this.hTask,this.state );
        end
    end
catch ME
    errorHandler( this,ME,false );
end

% administrative tasks: the GUI
try
    
    % update GUIs
    if ~this.options.headless
        for kk=1:length(this.hGUI)
            UpdateFcn( this.hGUI{kk} );
        end
    end
    
    % execute registered functions
    for kk=1:length(this.updateFcnList)
        feval( this.updateFcnList{kk}{2:end} );
    end
catch ME
    errorHandler( this,ME,false );
end

% administrative tasks: framework internal properties update
try
    
    % buffer timing information
    this.buffers.add('instantPeriod',this.hTimer.InstantPeriod);
    this.buffers.add('computerTime',now);
    this.buffers.add('elapsedTime',toc(this.runtime.tic));
    
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
