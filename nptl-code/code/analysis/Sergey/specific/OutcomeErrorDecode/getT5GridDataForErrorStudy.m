% Prepares T5 grid task data for subsequent error analysis.
% Note: I beleive that processExpt should have already been called on these
% experiments, or also there won't be the required derivative files.




% % with click
datasets = {...
    't5.2016.10.12';
    't5.2016.10.13';
    't5.2016.10.24';
    't5.2016.12.15'; % WARNING: need to have this days keyboardConstants, allKeyboards, etc on path
    };

% without click
% datasets = {...
%     't5.2016.09.28'; %blocks 7, 8, 9, 10, 23, 24, 25
%     't5.2016.10.03'; % blocks 30,31
%     };

% % hand-code to ignore certain blocks
% Not currently used - i got around this for t5.2016.12.15 because the only
% ignore block was 18x18, which isn't in wantKeyboardType
ignoreBlock = {...
    [];
    [];
    [];
    [7]; 
    };

% Rroot = '/net/derivative/R/';
dataRoot = '/net/experiments/';
saveDir = '/net/home/sstavisk/16outcomeError/giveToNir/';
startDir = pwd;
wantTaskType = 'keyboard';
wantKeyboardType = [double( keyboardConstants.KEYBOARD_GRID_6X6 ) ;
    double( keyboardConstants.KEYBOARD_GRID_9X9 );
    double( keyboardConstants.KEYBOARD_GRID_10X10 );
    double( keyboardConstants.KEYBOARD_GRID_12X12 );
    double( keyboardConstants.KEYBOARD_GRID_14X14 );
    double( keyboardConstants.KEYBOARD_GRID_16X16 );
    double( keyboardConstants.KEYBOARD_GRID_20X20 );
    double( keyboardConstants.KEYBOARD_GRID_24X24 );
    ]; % Looking for blocks of this type

for iDataset = 4 : numel( datasets ) 
    myDataset = datasets{iDataset};
    participant = myDataset(1:2);

    % Get the path to this directory's FileLogger folder.
    FLpath = [dataRoot participant '/' myDataset '/Data/FileLogger'];
    fprintf('\n**********\nDataset %s\n\n', myDataset );
    blocks = getBlockTypes( FLpath );
    if isempty( blocks )
        error('No blocks found for this day. Double-check this is a real experiment day?')
    end
    
    % Which blocks have the right task type
    hasRightType = arrayfun( @(x) strcmp( x.taskType, wantTaskType ), blocks );
    
    % Ignore specified blocks
    ignoreBlocks = ismember( [blocks.blockNum], ignoreBlock{iDataset} );    
    fprintf(' %i blocks ignored based on ignoreBlock\n', ...
        nnz( ignoreBlocks & hasRightType ) )
    hasRightType(ignoreBlocks) = false;
    
    
    fprintf('%i blocks total, %i have task type %s\n', ...
        numel( blocks ), nnz( hasRightType ), wantTaskType  );
    tryBlocks = [blocks(hasRightType).blockNum];

    % Load decoders used
    allDecoders = loadAllFiltersFromSession( myDataset );
    allDecoderNames = arrayfun(@(x) x.name, allDecoders, 'UniformOutput', false );
    
    
     keepBlocks = {}; % will save blocks here
    % Loop through these cantidate blocks and generate the R struct fully
    % from offline .nsx data -- necessary given that the .postTrial fields
    % for LFP seem not to be working correctly
    for iBlock = 1 : numel( tryBlocks)        
        blockNum = tryBlocks(iBlock);
        
%         if blockNum == 19
%             keyboard % DEV why is it not being loaded?
%         end
        
        fprintf('trying loadStreamWithAddons(''%s'',''%s'',%i)... (%i/%i)\n', ...
            participant, myDataset, blockNum, iBlock, numel(tryBlocks) )
        try
            stream = loadStreamWithAddons(participant, myDataset, blockNum );
        catch
            fprintf(2, 'Failed to loadStreamWithAddons. Moving on.\n')
            continue
        end
        if isempty( stream )
            fprintf(2, 'This stream is empty. Moving on\n');
            continue
        end
        try
            R = onlineR( stream ); % misnomer since clearly not online behavior, it's going form nsx
        catch
            fprintf(2, 'Failed to onlineR from this block''s stream. Moving on.\n')
            continue
        end
        if isempty( R ) 
            fprintf('  no trials in this block R struct, continuiing\n')
            continue
        end
        
        confirmBlockNum = R(1).startTrialParams.blockNumber;
        assert( blockNum == confirmBlockNum );
        taskName = R(1).taskDetails.taskName;
        
        fprintf('Block %i (%i trials) tasktype=%s\n', blockNum, numel( R ), taskName );
        if ~strcmp( taskName, wantTaskType )
            continue
        end
        
        % Now we check if this is right keyboard type
        myKeyboard = R(1).startTrialParams.keyboard;
        fprintf('  keyboard type %i, looking for %s\n', myKeyboard, mat2str( wantKeyboardType ) );
        
        if any( myKeyboard == wantKeyboardType );
            % Correct keyboard type, this block is what I want
            thisBlock.blockNum = blockNum;
            thisBlock.keyboardType = myKeyboard;
            fprintf('  KEEPING\n');
     

            thisBlock.R = R; %we'll be saving this block
            
            % Record threshold used for this block.
            myDecoderName = R(1).decoderD.filterName;
            % it has a stupid mystery whitespace at the end. Remove
            % before strcmp
            [~,myInd] = regexp( myDecoderName, '.+m+a+t');
            myDecoderName = myDecoderName(1:myInd);
            myDecoder = allDecoders( strcmp( allDecoderNames, myDecoderName) );
            thisBlock.decoder = myDecoder;
            thisBlock.thresholds = myDecoder.model.thresholds;
            
            keepBlocks{end+1} = thisBlock;
        end
    end
    
    numTrialsEachBlock = cellfun(@(x) length(x.R), keepBlocks );
    fprintf('Saving down %i blocks'' R structs with total of %i trials ...\n', ...
        numel( keepBlocks ), sum(numTrialsEachBlock) );
    
    % I have the data I want. Now save it.
    fullpath = [saveDir myDataset '.mat'];
    fprintf('Saving %s\n', fullpath );
    save( fullpath, 'keepBlocks', '-v7.3');    

end



cd( startDir );