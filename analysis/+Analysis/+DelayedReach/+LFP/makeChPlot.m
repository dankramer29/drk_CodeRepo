function ch_map = makeChPlot
    % ch_map key value pairing of leads and channels
    %
    %    prompts user to enter lead locations and corresponding channels
    %    and stores inputs as key, value map.
    %    Ex: Lead location? : L amygdala
    %    Ex: Channel range? (ex 17:26) : 1:10
    %    values can be accessed by prompting the key value (lead name).
    %    Ex: ch_map('L amygdala') returns '1:10'. The channel range will
    %    be changed to an array by other functions for data indexing and
    %    plotting
    
    prompt = '# leads: ';
    in = input(prompt);
    ch_map = containers.Map( {'lead_loc'}, {'ch1:chn'} );
    for i = 1:in
        lead_loc = input('Lead location? : ', 's');
        ch_nums = input('Channel range? (ex 17:26) : ', 's');
        ch_map(lead_loc) = ch_nums;
    end
    remove(ch_map, 'lead_loc');

end