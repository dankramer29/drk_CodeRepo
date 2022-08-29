function [ blocks ] = stroop_task( task_num, loops, varargin )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    

%
[varargin, iti]=util.argkeyval('iti',varargin, 0.5);
[varargin, load_trials]=util.argkeyval('load_trials', varargin, true);
[varargin, dis_time]=util.argkeyval('dis_time', varargin, [1 0.75 0.5]); % the display times for easy, medium and hard

color_letters={'g', 'b', 'y', 'r'};
color_names={'green', 'blue', 'yellow', 'red'};



if load_trials
    assert(loops<=12, 'cant load files, need to make load_files=false on varargin');
    if exist('C:\Users\Daniel\Documents\Code\analysis\+tasks\stroop_trials_EasyMedHard_12blocks.mat', 'file')
        load('C:\Users\Daniel\Documents\Code\analysis\+tasks\stroop_trials_EasyMedHard_12blocks.mat');
    else
        [filename, filepath]=uigetfile({'*.mat'});
        full_file=fullfile(filepath, filename);
        load(full_file);
    end
else    
    %NEED TO ADJUST THE TASK_NUM TRIALS FOR TMP3-6 IF YOU'RE GOING TO
    %CHANGE THE AMOUNT BEING DONE
    for jj=1:4 %
        tmp1=randi(4,task_num,1);
        tmp2=randi(4,task_num,1);
        tmp3=randi(4,36,1);
        tmp4=randi(4,36,1);
        tmp5=randi(4,45,1);
        tmp6=randi(4,45,1);
        for kk=1:task_num
            clr_name1{kk,1}=color_names{tmp2(kk)};
            clr_name1{kk,2}=color_letters{tmp1(kk)};
        end
        for kk=1:36
            
            clr_name2{kk,1}=color_names{tmp4(kk)};
            clr_name2{kk,2}=color_letters{tmp3(kk)};
        end
        for kk=1:45            
            clr_name3{kk,1}=color_names{tmp6(kk)};
            clr_name3{kk,2}=color_letters{tmp5(kk)};
        end
        blocks{jj, 1}=clr_name1;
        blocks{jj+4, 1}=clr_name2;
        blocks{jj+8, 1}=clr_name3;
    end
end


%% create and run test 
test_trials=15;
tmp1=randi(4,test_trials,1);
tmp2=randi(4,test_trials,1);

for kk=1:test_trials
    if tmp1(kk)==tmp2(kk)&&tmp1(kk)<=3
        tmp1(kk)=tmp1(kk)+1;
    elseif tmp1(kk)==tmp2(kk)&&tmp1(kk)==4
        tmp1(kk)=1;
    end
    
    clr_name{kk,1}=color_names{tmp2(kk)};
    clr_name{kk,2}=color_letters{tmp1(kk)};
    
end
test_blocks{1, 1}=clr_name;


%%
%run through practice
% figuretest=figure('units','normalized','outerposition',[0 0 1 1], 'Color', [0 0 0]);
% pause(1);
% hstart=annotation(figuretest,'textbox',...
%     [0.3 0.460913705583756 0.385844166014098 0.116751269035533],...
%     'Color','w',...
%     'String', {'Say the color of the letters that make up the word'},...
%     'LineStyle','none',...
%     'FontSize',55,...
%     'FitBoxToText','off',...
%     'EdgeColor',[1 1 1]);
% pause(5);
% delete(hstart);
% for ii=1:test_trials
%     % Create textbox
%         h=annotation(figuretest,'textbox',...
%             [0.45 0.460913705583756 0.385844166014098 0.116751269035533],...
%             'Color',test_blocks{1}{ii,2},...
%             'String', test_blocks{1}{ii,1},...
%             'LineStyle','none',...
%             'FontSize',55,...
%             'FitBoxToText','off',...
%             'EdgeColor',[1 1 1]);
%         
%         pause(3);
%         delete(h);
%         pause(iti); 
% end
% 
% waitforbuttonpress;
% close all


%% Run actual trials
%randomly pick which block to run
coin=randi(3,1,1);
block_num=struct;
block_num.one=[2 3 5 6 12 11 8 7 1 4 9 10];
block_num.two=[6 5 3 2 11 12 4 1 10 9 7 8];
block_num.three=[4 1 11 12 5 6 10 9 2 3 8 7];
nm=fields(block_num);
run_block=block_num.(nm{coin});
for jj=1:length(run_block)  
        close all
        figure1=figure('units','normalized','outerposition',[0 0 1 1], 'Color', [0 0 0]);
        pause(1);
        hstart=annotation(figure1,'textbox',...
            [0.3 0.460913705583756 0.385844166014098 0.116751269035533],...
            'Color','w',...
            'String', {'Say the color of the letters that make up the word'},...
            'LineStyle','none',...
            'FontSize',55,...
            'FitBoxToText','off',...
            'EdgeColor',[1 1 1]);
        pause(5);
        delete(hstart);
        pause(1);
        hstart=annotation(figure1,'textbox',...
            [0.3 0.460913705583756 0.385844166014098 0.116751269035533],...
            'Color','w',...
            'String', {'Block ', num2str(run_block(jj)), ' waiting for button press'},...
            'LineStyle','none',...
            'FontSize',55,...
            'FitBoxToText','off',...
            'EdgeColor',[1 1 1]);
        waitforbuttonpress;
        delete(hstart)
        for ii=1:size( blocks{run_block(jj)},1)
            
            % Create textbox
            h=annotation(figure1,'textbox',...
                [0.45 0.460913705583756 0.385844166014098 0.116751269035533],...
                'Color',blocks{run_block(jj)}{ii,2},...
                'String', blocks{run_block(jj)}{ii,1},...
                'LineStyle','none',...
                'FontSize',65,...
                'FitBoxToText','off',...
                'EdgeColor',[1 1 1]);
            if run_block(jj)<=4
                pause(dis_time(1));
            elseif run_block(jj)>4 && run_block(jj)<=8
                pause(dis_time(2));
            elseif run_block(jj)>8 && run_block(jj)<=12
                pause(dis_time(3));
            end
            delete(h);
            pause(iti);
            
        end
        hstart=annotation(figure1,'textbox',...
            [0.3 0.460913705583756 0.385844166014098 0.116751269035533],...
            'Color','w',...
            'String', {'waiting for button press'},...
            'LineStyle','none',...
            'FontSize',55,...
            'FitBoxToText','off',...
            'EdgeColor',[1 1 1]);
        waitforbuttonpress
end

end

