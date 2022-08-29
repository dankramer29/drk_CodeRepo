function [topic,props] = Analysis        

topic = struct(...
    'name','Analysis Properties',...
    'description','Properties related to analysis',...
    'id','an');

props.cache = struct(...
    'shufN',@(x)isnumeric(x)&&x>=0,...
    'default',false,...
    'attributes',struct('Description','number of shuffles to use'));

props.mintrials = struct(...
    'sampleN',@(x)isnumeric(x)&&x>=0,...
    'default',45,...
    'attributes',struct('Description','number of samples to use'));
