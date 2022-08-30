function [HandNum, HandStats] = stim_map(subject)

% Need:
%     Boxes per electrode
%         Each grid
%         Mean/std
%     Electrodes in each box
%         each grid
%         mean/std
%     Percentage of hand covered
%         mean
%     Percentage of fingers covered
%         mean
%     Percentage of palm covered
%         mean
%     Other areas covered per grid, meaning extends to other areas
%     Orientation of fingers and hand?

% %Inputs:
%     subject=        name of subject, like this 'LName, FName', see in the folder research for the names
% for saving the data
%
%Example
%    [unique_locations,elec_counts, handstats] = ArtSens.stim_map(subject);
%       [HandStats]=ArtSens.stim_map(subject);


xx=[]; yy=[]; zz=[];
str_comp='d1a;d1b;d1c;d1d;d1e;d1f;d1g;d1h;d2a;d2b;d2c;d2d;d2e;d2f;d3a;d3b;d3c;d3d;d3e;d3f;d4a;d4b;d4c;d4d;d4e;d4f;d5a;d5b;d5c;d5d;d5e;d5f;w1;w2;w3;w4;x1;x2;x3;x4;y1;y2;y3;y4;z1;z2;z3;z4';
str_csplit=strsplit(str_comp, ';');
Boxnum=zeros(49,1);

dirpath='C:\Users\Daniel\Dropbox\Residency\!BLX\Arificial sensation\Minigrid mapping and papers\Research\';
filename=fullfile(dirpath, sprintf('%s%s', subject, '.xlsx'));
% filename to load
[~,~,raw] = xlsread(filename);

% get sensation-type indices
sen_idx4 = cellfun(@(x)strcmpi('sensation',x),raw(:,4));
sen_idx5 = cellfun(@(x)strcmpi('sensation',x),raw(:,5));
if nnz(sen_idx4)>=1
    sen_idx=sen_idx4;
elseif nnz(sen_idx5)>=1
    sen_idx=sen_idx5;
end
%%
locations = raw(sen_idx,3);
%get rid of any ending ;s
for ii=1:length(locations)
    if strcmp(locations{ii}(end), ';')
        locations{ii}(end)=[];
    end
end
%split the electrodes
elecs1 = cell2mat(raw(sen_idx,1));
elecs2 = cell2mat(raw(sen_idx,2));
split_loc=cellfun(@(x)strsplit(x,';'),locations, 'UniformOutput', false);
%%
palm=cell(size(locations));
digits=cell(size(locations));
handonly=cell(size(locations));
TotBPE=NaN(49,1);
HandBPE=NaN(49,1);
DigitBPE=NaN(49,1);
PalmBPE=NaN(49,1);
BPE=NaN(2,4);
NonHand=NaN(49,1);
ElecPerBoxMean=NaN(2,3);
%%
for ii=1:length(split_loc) %ii=electrodes
    idx1=1; idx2=1; idx3=1; idx4=1;
    for jj=1:length(split_loc{ii}) %jj=boxes
        %check for errant entries or non hnad entries and load into cell
        err=strfind(str_comp, split_loc{ii}{jj});
        if isempty(err)
            disp(sprintf('errant entry or non hand entry in row %d position %d entry %s', ii, jj, split_loc{ii}{jj}))
            nonhand{ii}{idx4}=split_loc{ii}{jj};
            idx4=idx4+1;
        else
            nonhand{ii}=[];
        end
        %check for duplicates
        dup=strfind(locations{ii},split_loc{ii}{jj});
        if length(dup(1))>1
            disp(sprintf('duplicate entry in row %d position %d entry %s', ii, jj, split_loc{ii}{jj}))
        end
        %break up into hand, digits and palms
        xx=regexpi(split_loc{ii}{jj}, {'[dwxyz][12345]'});
        if ~isempty(xx{1})
            handonly{ii}{idx3}=split_loc{ii}{jj};
            idx3=idx3+1;
            xx=regexpi(split_loc{ii}{jj}, {'d[12345]'});
            if ~isempty(xx{1})
                digits{ii}{idx1}=split_loc{ii}{jj};
                idx1=idx1+1;
            else
                palm{ii}{idx2}=split_loc{ii}{jj};
                idx2=idx2+1;
            end
        end
    end
    TotBPE(ii,1)=length(split_loc{ii}); %all areas
    HandBPE(ii,1)=length(handonly{ii}); %hand only
    DigitBPE(ii,1)=length(digits{ii}); %digits only
    PalmBPE(ii,1)=length(palm{ii}); %palm only
    
%%
    for rr=1:48
        %look through each box and see how many times it comes up.
        if ~isempty(strfind(locations{ii},str_csplit{rr}))
            Boxnum(rr,1)=Boxnum(rr,1)+1;            
        end
    end    
end
%%
%electrodes per box-electrodes stimulating the same box
ElecPerBoxMean(1,1)=length(locations); %number of electodes that stimulated
ElecPerBoxMean(1,2)=mean(Boxnum); %average number of times each box was stimulated 
ElecPerBoxMean(1,3)=ElecPerBoxMean(1,2)/length(locations); %percentage of those that were stimulated
if ~isempty(nonhand)
Temp=cellfun(@(x)length(x),nonhand); 
Temp=Temp';
NonHand(1:length(Temp),1)=Temp;
end
%%
%boxes per electrode
BPE(1,1)=nanmean(HandBPE);
BPE(2,1)=BPE(1,1)/48; %percentage
BPE(1,2)=nanmean(DigitBPE);%digit only (meaning this says of the boxes per electrode, this many are from the digits and the rest from the palm)
BPE(2,2)=BPE(1,2)/32; %percentage
BPE(1,3)=nanmean(PalmBPE);%palm only
BPE(2,3)=BPE(1,3)/16; %percentage
BPE(1,4)=nanmean(NonHand); %non hand, no percentage for nonhand since can be anything
%%
%load hand stats
HandNum=table(HandBPE,DigitBPE, PalmBPE, NonHand,  Boxnum, ...
    'VariableNames',{'HandBoxesPerElectrode','DigitBPE','PalmBPE', 'NonHandBPE',  'ElecPerBox'});
HandStats=table(BPE, ElecPerBoxMean(:,1), ElecPerBoxMean(:,2),ElecPerBoxMean(:,3),...
    'VariableNames', {'BPEmeansHandDigitPalmNonhandNum_Perc', 'ElecPerBoxNumElecsThatStimulated', 'ElecPerBoxMean', 'PercOfStimElecs'});


end % END of GETSTIMLOCATIONS