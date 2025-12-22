function [PCdata, data, dataLength] = suaPCA(spk, varargin)
%runs a pca including a normalization (soft), mean center, and has some
%plotting. much of this is taken from tangleAnalysis

%inputs
% * Data (struct) - a C-dimensional structure where C is the number of
% conditions. For a given condition, Data(c).A should hold the data (e.g.
% firing rates). Each column of A corresponds to a neuron, and each row to
% a timepoint. Data(c).times and Data(c).analyzeTimes are optional
% fields. size(Data(c).times,1) should equal size(Data(c).A,1). 


[varargin, plt3d]=util.argkeyval('plt3d', varargin, true); %do a 3d plot
[varargin, pltMultD]=util.argkeyval('pltMultD', varargin, true); %do a multidimensional plot up to a certain number of dimensions NOT GOING TO MAKE THIS SECOND.
[varargin, interval]=util.argkeyval('interval', varargin, []); %add timepoints to the figures
[varargin, centerDataOn]=util.argkeyval('centerDataOn', varargin, []); %2 cells, first is case switch for when to center the data, 1 is StimOn, 2 is Response, and 3 is ITI. add timepoints to the figures with label
[varargin, fracVar]=util.argkeyval('timePoints', varargin, []); %.85 good value, can find how many pcs explain the fracVar of fractional variance (this is also in expVar)
[varargin, numPCs]=util.argkeyval('numPCs', varargin, 8); %number of pcs to consider. this isn't really used because i output all of them or you can use the frac variance above. this will come in when plotting multid later
[varargin, tt]=util.argkeyval('tt', varargin, []); %time to run the PC over do it in adjusted time (so -50 to 1000)
[varargin, pcaRun]=util.argkeyval('pcaRun', varargin, 1); %run it either congruent vs incongruent (1) or as choice 123 (2). which will be one figure of each but all put together for concat pcas.

[varargin, softenNorm]=util.argkeyval('softenNorm', varargin, 5); 
% * softenNorm (scalar, default: 5) - In the usual Churchlandian fashion,
% soft normalization is performed on the neural data such that each neuron
% is devided by its range (across all times and conditions) + some constant
% indicated by softenNorm. EMG data should be fully normalized (i.e.
% softenNorm set to 0)

%set up labelingand time
if isempty(centerDataOn)
    centerDataOn{1} = 1; %stim on case
    centerDataOn{2} = {'Image On'};
end



dataCenter = centerDataOn{1};
switch dataCenter
    case 1 %stim on
        preStim = -interval.preStim;
        postStim = interval.postStim;
        if isempty(tt) %adjust the time if you only want to do smaller sections of the total time
            timeMask(1) = 1;
            timeMask(end) = length(spk.congMean{1});
        else          
            timeMask(1) = tt(1)-preStim;
            timeMask(2) = tt(2)-preStim;
        end
        eventIdx = -tt(1); %in the event tt is + (and therefore after the event) it will label the first time point (incorrectly, but then just turn the label off)
        eventLbl = 'Image On';

    case 2
        preStim = -interval.preResp;
        postStim = interval.preResp;
        tt = tt+prestim;
        eventIdx = find(tt == 0);
        eventLbl = 'Response';

    case 3
        preStim = -interval.preITI;
        postStim = interval.postITI;
        tt = tt+prestim;
        eventIdx = find(tt == 0);
        eventLbl = 'Response';
end


%convert to a struct expected for tangle analysis cong vs incong
switch pcaRun
    case 1
        data = struct;
        data(1).A = spk.congMean{1}(:,timeMask(1)+1:timeMask(2))';
        data(2).A = spk.incongMean{1}(:,timeMask(1)+1:timeMask(2))';
        data(1).conditions = 'congruent';
        data(2).conditions = 'incongruent';

        datalengthC1 = length(data(1).A); %for splitting the data later
        datalengthI1 = length(data(2).A);
    case 2
        %convert to a struct that is cong vs incong but for each answer
        data = struct;
        data(1).A = spk.congMean{2}(:,timeMask(1)+1:timeMask(2))'; %choice1
        data(2).A = spk.congMean{3}(:,timeMask(1)+1:timeMask(2))'; %choice2
        data(3).A = spk.congMean{4}(:,timeMask(1)+1:timeMask(2))'; %choice3
        data(4).A = spk.incongMean{2}(:,timeMask(1)+1:timeMask(2))'; %choice1
        data(5).A = spk.incongMean{3}(:,timeMask(1)+1:timeMask(2))'; %choice2
        data(6).A = spk.incongMean{4}(:,timeMask(1)+1:timeMask(2))'; %choice3

        data(1).conditions = 'congruent 1';
        data(2).conditions = 'congruent 2';
        data(3).conditions = 'congruent 3';
        data(4).conditions = 'incongruent 1';
        data(5).conditions = 'incongruent 2';
        data(6).conditions = 'incongruent 3';

        datalengthC1 = length(data(1).A); %for splitting the data later
        datalengthC2 = length(data(2).A)+datalengthC1;
        datalengthC3 = length(data(3).A)+datalengthC2;

        datalengthI1 = length(data(3).A)+datalengthC3; %for splitting the data later
        datalengthI2 = length(data(4).A)+datalengthI1;
        datalengthI3 = length(data(5).A)+datalengthI2;
end




% Ensure data is formatted correctly
if size(data(1).A,1) < size(data(1).A,2)
   warning('Data(c).A should be a t x n matrix containing the firing rates for condition c. Ensure that this is the case')
end

% Unwrap all data into a ct X n matrix 
A = [];
conditionMask = [];
for cc = 1:length(data)
   theseData = data(cc).A;
   A = [A; theseData];
   conditionMask = [conditionMask; cc*ones(size(theseData,1),1)];
end

% soft-normalize firing rates in the usual Churchland way
if ~isempty(softenNorm)
   normFactors = range(A,1)+softenNorm;
   A = bsxfun(@times, A, 1./normFactors);
elseif any(range(A,1) > 1) && isempty(softenNorm)
   warning('A should be normalized or soft-normalized such that the range of each neuron <= 1')
end
A = bsxfun(@minus, A, mean(A,1)); % mean center

% reduce to numPCs or however many PCs capture fracVar of the variance
[PCs, pcXtime, v, ~, expVar] = pca(A); %the third variable is the eigen values of the variance, and the 5th is the explained percentage of the variance.
V = cumsum(v)./sum(v);
%this is if you want to gather only the pcs that explain x of the variance,
%right now just returning it all.
vcum = cumsum(var(A*PCs))./sum(var(A*PCs));
if ~isempty(fracVar)
   % determine how many PCs to use   
   idx = 1:size(vcum,2);
   numPCs = idx(vcum > fracVar);
   numPCs = numPCs(1);
end
if numPCs > size(PCs,2)
   topPCs = PCs;
else
   topPCs = PCs(:,1:numPCs);
end

switch pcaRun
    case 1
        PCdata.pc = PCs;
        PCdata.PCxTimeC = pcXtime(1:datalengthC1,:);
        PCdata.PCxTimeI = pcXtime(datalengthC1+1:end,:);
        PCdata.eigen = v;
        PCdata.cumulativeExpVar = vcum;
        PCdata.expVar = expVar;

        if plt3d
            pc1 = PCdata.PCxTimeC(:,1);
            pc2 = PCdata.PCxTimeC(:,2);
            pc3 = PCdata.PCxTimeC(:,3);
            plt.PCAcolorplt(pc1, pc2, 'data3', pc3, 'colorChoice', {'#395886', '#B1C9EF'}, 'eventIdx', eventIdx, 'eventLbl', eventLbl);

            pc1 = PCdata.PCxTimeI(:,1);
            pc2 = PCdata.PCxTimeI(:,2);
            pc3 = PCdata.PCxTimeI(:,3);
            plt.PCAcolorplt(pc1, pc2, 'data3', pc3,'colorChoice', {'#341514', '#E17888'}, 'newFig', false, 'eventIdx', eventIdx, 'eventLbl', eventLbl);

        end

        data(1).length = datalengthC1;
        data(2).length = datalengthI1;
        
    case 2 %TO DO, IS INCONGRUENT THE SEPARATED ONE? NEED TO DOUBLE CHECK THAT
        PCdata.pc = PCs;
        PCdata.PCxTimeC1 = pcXtime(1:datalengthC1,:);
        PCdata.PCxTimeC2 = pcXtime(datalengthC1+1:datalengthC2 ,:);
        PCdata.PCxTimeC3 = pcXtime(datalengthC2+1:datalengthC3 ,:);

        PCdata.PCxTimeI1 = pcXtime(datalengthC3+1:datalengthI1,:);
        PCdata.PCxTimeI2 = pcXtime(datalengthI1+1:datalengthI2,:);
        PCdata.PCxTimeI3 = pcXtime(datalengthI2+1:end,:);
        PCdata.eigen = v;
        PCdata.cumulativeExpVar = vcum;
        PCdata.expVar = expVar;

        if plt3d
            pc1 = PCdata.PCxTimeC1(:,1);
            pc2 = PCdata.PCxTimeC1(:,2);
            pc3 = PCdata.PCxTimeC1(:,3);
            plt.PCAcolorplt(pc1, pc2, 'data3', pc3, 'colorChoice',...
                {'#395886', '#B1C9EF'}, 'eventIdx', eventIdx, 'eventLbl', eventLbl, 'dataLbl', 'Response 1');

            pc1 = PCdata.PCxTimeC2(:,1);
            pc2 = PCdata.PCxTimeC2(:,2);
            pc3 = PCdata.PCxTimeC2(:,3);
            plt.PCAcolorplt(pc1, pc2, 'data3', pc3,'colorChoice',...
                {'#38000A', '#FFA896'}, 'newFig', false, 'eventIdx', eventIdx, 'eventLbl', eventLbl, 'dataLbl', 'Response 2');
        
            pc1 = PCdata.PCxTimeC3(:,1);
            pc2 = PCdata.PCxTimeC3(:,2);
            pc3 = PCdata.PCxTimeC3(:,3);
            plt.PCAcolorplt(pc1, pc2, 'data3', pc3,'colorChoice',...
                {'#253D2C', '#CFFFDC'}, 'newFig', false, 'eventIdx', eventIdx, 'eventLbl', eventLbl, 'dataLbl', 'Response 3');
          
            colorTempTest = {'#B1C9EF', '#FFA896', '#CFFFDC'}; %dark to light red
            for ii = 1:length(colorTempTest)
                str = colorTempTest{ii};
                C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
            end
            hold on
            h1 = plot3(nan, nan, nan, 'LineWidth', 3, 'Color', C(1,:)); % dummy
            h2 = plot3(nan, nan, nan, 'LineWidth', 3, 'Color', C(2,:)); % dummy
            h3 = plot3(nan, nan, nan, 'LineWidth', 3, 'Color', C(3,:)); % dummy

            legend([h1, h2, h3], {'Response 1', 'Response 2', 'Response 3'});

            pc1 = PCdata.PCxTimeI1(:,1);
            pc2 = PCdata.PCxTimeI1(:,2);
            pc3 = PCdata.PCxTimeI1(:,3);
            plt.PCAcolorplt(pc1, pc2, 'data3', pc3, 'colorChoice',...
                {'#395886', '#B1C9EF'}, 'eventIdx', eventIdx, 'eventLbl', eventLbl, 'dataLbl', 'Response 1');

            pc1 = PCdata.PCxTimeI2(:,1);
            pc2 = PCdata.PCxTimeI2(:,2);
            pc3 = PCdata.PCxTimeI2(:,3);
            plt.PCAcolorplt(pc1, pc2, 'data3', pc3,'colorChoice',...
                {'#38000A', '#FFA896'}, 'newFig', false, 'eventIdx', eventIdx, 'eventLbl', eventLbl, 'dataLbl', 'Response 2');
        
            pc1 = PCdata.PCxTimeI3(:,1);
            pc2 = PCdata.PCxTimeI3(:,2);
            pc3 = PCdata.PCxTimeI3(:,3);
            plt.PCAcolorplt(pc1, pc2, 'data3', pc3,'colorChoice',...
                {'#253D2C', '#CFFFDC'}, 'newFig', false, 'eventIdx', eventIdx, 'eventLbl', eventLbl, 'dataLbl', 'Response 3');
        
            hold on
            h1 = plot3(nan, nan, nan, 'LineWidth', 3, 'Color', C(1,:)); % dummy
            h2 = plot3(nan, nan, nan, 'LineWidth', 3, 'Color', C(2,:)); % dummy
            h3 = plot3(nan, nan, nan, 'LineWidth', 3, 'Color', C(3,:)); % dummy

            legend([h1, h2, h3], {'Response 1', 'Response 2', 'Response 3'});
        
        end

        data(1).length = datalengthC1;
        data(2).length = datalengthC2;
        data(3).length = datalengthC3;
        data(4).length = datalengthI1;
        data(5).length = datalengthI2;
        data(6).length = datalengthI3;

end


end