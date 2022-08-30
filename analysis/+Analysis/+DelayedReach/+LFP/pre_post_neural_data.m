function [pre_data, pre_data_times, post_data, post_data_times] = pre_post_neural_data(task0bj, neuraldataobj, phase, pretime, posttime, channels)
    % To-Do: make sure sufficient time in each trial for posttime, use
    % logical of ok-pre and ok-post for ok_trials.
    % To-Do: varargin for number of trials or specific trials?
    
    dtclass = 'single';
    
    % taskObj.phaseTimes is a 2 column array. Column 1 is the same as
    % taskObj.trialTimes column 1, meaning the start of each trial. Column 2 of
    % phaseTimes is when the effector showed, which the patient followed with
    % her right index finger. This time is being used as the onset of movement.

    move_start_times = [task0bj.phaseTimes(:, phase)];

    % can only use trials that had 1 second of recording before the movement
    % started

    trial_start_times = [task0bj.trialTimes(:,1)];

    wait_duration = move_start_times - trial_start_times;

    ok_trials = wait_duration >= 1.000;

    % make start and duration array for neural data of waiting to move
    nd_wait_start = move_start_times(ok_trials) - pretime;
    nd_wait_duration = pretime * ones(length(nd_wait_start), 1);
    nd_wait_procwin = [nd_wait_start nd_wait_duration];

    % make start and duration array for neural data of moving
    nd_move_start = move_start_times(ok_trials);
    nd_move_duration = posttime * ones(length(nd_move_start), 1);
    nd_move_procwin = [nd_move_start nd_move_duration];
    
    nd_wait_procwin_short = nd_wait_procwin(1:47,:);
    nd_move_procwin_short = nd_move_procwin(1:47,:);
    
    assert(isequal(size(nd_wait_procwin_short), size(nd_move_procwin_short)), 'Procwin sizes do not match')
    
    [pre_data, pre_data_times, ~] = proc.blackrock.broadband(...
    neuraldataobj, 'PROCWIN', nd_wait_procwin_short, dtclass, 'CHANNELS', channels,...
    'Uniformoutput', true);

    [post_data, post_data_times, ~] = proc.blackrock.broadband(...
    neuraldataobj, 'PROCWIN', nd_move_procwin_short, dtclass, 'CHANNELS', channels,...
    'Uniformoutput', true);
    
end %end func pre_post_neural_data
