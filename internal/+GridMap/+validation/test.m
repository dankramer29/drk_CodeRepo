% test script for grid map object

map = GridMap.Interface('C:\Users\spenc\Documents\Research\Keck\Data\P010\20170823-PH2\20170830\20170830-132252-132257-DelayedReach-AllGrids-001.map');



%% updateGridChannel
for gid=0:map.NumGrids-1
    
    fprintf('Checking updateGridChannel for gid %d...',gid);
    
    % get list of original channels
    grid_orig_ch = map.GridInfo.Channel{map.GridInfo.GridID==gid};
    
    % update to +10 on channel numbers (no over/underlap testing)
    map.updateGridChannel(gid,grid_orig_ch+10,'over_under',true);
    
    % get new channel numbers
    grid_new_ch = map.GridInfo.Channel{map.GridInfo.GridID==gid};
    
    % make sure it's as expected
    assert(all(grid_new_ch-grid_orig_ch==10));
    assert(all(map.GridInfo.Channel{map.GridInfo.GridID==gid}==map.ChannelInfo.Channel(map.ChannelInfo.GridID==gid)));
    
    % put back to the way it was
    map.updateGridChannel(gid,grid_orig_ch,'over_under',true);
    
    % get new channel numbers
    grid_new_ch = map.GridInfo.Channel{map.GridInfo.GridID==gid};
    
    % make sure it's as expected
    assert(all(grid_new_ch==grid_orig_ch));
    assert(all(map.GridInfo.Channel{map.GridInfo.GridID==gid}==map.ChannelInfo.Channel(map.ChannelInfo.GridID==gid)));
    
    % update feedback
    fprintf(' success\n');
end


%% updateGridID
for gid=0:map.NumGrids-1
    
    fprintf('Checking updateGridID for gid %d...\n',gid);
    label_orig = map.GridInfo.Label{map.GridInfo.GridID==gid};
    
    % move this grid to every other grid position
    for newgid=0:map.NumGrids-1
        
        fprintf('  to new gid %d...',newgid);
        
        % update the grid id
        map.updateGridID(gid,newgid);
        
        % make sure it's as expected: grid label
        label_new = map.GridInfo.Label{map.GridInfo.GridID==newgid};
        assert(strcmpi(label_orig,label_new));
        fprintf(' chk 1');
        
        % make sure channels are in order
        new_ch = map.GridInfo.Channel{map.GridInfo.GridID==newgid};
        if any(map.GridInfo.GridID<newgid)
            assert(new_ch(1)>map.GridInfo.Channel{map.GridInfo.GridID==(newgid-1)}(end));
            fprintf(' chk 2');
        end
        if any(map.GridInfo.GridID>newgid)
            assert(new_ch(end)<map.GridInfo.Channel{map.GridInfo.GridID==(newgid+1)}(1));
            fprintf(' chk 3');
        end
        
        % put back to the way it was
        map.updateGridID(newgid,gid);
        
        % make sure it's as expected
        label_new = map.GridInfo.Label{map.GridInfo.GridID==gid};
        assert(strcmpi(label_orig,label_new));
        fprintf(' chk 4');
        
        % make sure channels are in order
        new_ch = map.GridInfo.Channel{map.GridInfo.GridID==newgid};
        if any(map.GridInfo.GridID<newgid)
            assert(new_ch(1)>map.GridInfo.Channel{map.GridInfo.GridID==(newgid-1)}(end));
            fprintf(' chk 5');
        end
        if any(map.GridInfo.GridID>newgid)
            assert(new_ch(end)<map.GridInfo.Channel{map.GridInfo.GridID==(newgid+1)}(1));
            fprintf(' chk 6');
        end
        
        % update feedback
        fprintf(' success\n');
    end
end





% updateGridTemplate





% removeGrid
% editGrid
% addGrid