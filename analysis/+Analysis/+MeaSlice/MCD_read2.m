function MCD_read2(contourTime)
% read MCD data using neuroshare
% Example;
%  contourTime=[1.64 1.645 1.65 1.655 1.68 1.685]; MCD_read2(contourTime);
%
%  contourTime: times you want to see the plots
%   Date        Programmer      Description of change
%   ====        ==========      =====================
%   09/01/16    Penning Yu      original code  


%to load them in, enter the path to the file you want to run here and it
%will work.
examplePath = 'C:\Users\Daniel\Documents\DATA\RussinSliceStuff_MEA files 1-25-19'; %pwd
% remember the current path where Neuroshare.m is located

% the path of the Matlab_interface files
cd 'C:\Users\Daniel\Documents\Code\external\Matlab_Interface'

% % or include FIND into the search path

[nsresult] = mcs_SetLibrary('nsMCDlibrary64.dll');
[nsresult,info] = ns_GetLibraryInfo();
cd(examplePath);
[nsresult, hfile] = ns_OpenFile('Case 72 Slice1-4AP-BL.mcd');
[nsresult,info]=ns_GetFileInfo(hfile);

% Find out about the Entity types
% Then read specific entity info and data

MEAPin=[47 48 46 45 38 37 28 36 27 17 26 16 35 25 15 14 24 34 13 23 ...
        12 22 33 21 32 31 44 43 41 42 52 51 53 54 61 62 71 63 72 82 ...
        73 83 64 74 84 85 75 65 86 76 87 77 66 78 67 68 55 56 58 57];
% for MAP 6*10
% MEALocation = [78 68 58 48 38 28; 66 55 56 46 45 36; 87 67 57 47 37 17; ...
%     86 76 77 27 26 16; 85 75 65 35 25 15; 84 74 64 34 24 14; ... 
%     83 73 72 22 23 13; 82 62 52 42 32 12; 63 54 53 43 44 33; ...
%     71 61 51 41 31 21];

% For MAP inverse 8*8 
MEALocation=[nan 78 68 58 48 38 28 nan; 87 77 67 57 47 37 27 17;86 76 66 56 46 36 26 16;...
    85 75 65 55 45 35 25 15; 84 74 64 54 44 34 24 14;83 73 63 53 43 33 23 13;...
    82 72 62 52 42 32 22 12;nan 71 61 51 41 31 21 nan];
 
% raw electrode data
[nsresult,entity] = ns_GetEntityInfo(hfile,1);
[nsresult,analog] = ns_GetAnalogInfo(hfile,1);

sampRate=1/info.TimeStampResolution;

StartIndex=1;               %   Starting index number of the analog data item.
IndexCount=10*sampRate; %   Number of analog values to retrieve.
data=zeros(length(MEAPin),IndexCount);

MEAIdx=0;
for MEALoc_i=1:64;
    [EntityID]=find(MEAPin==MEALocation(MEALoc_i));
    if ~isempty(EntityID)
        MEAIdx=MEAIdx+1;
    [nsresult,count,data(MEAIdx,:)]=ns_GetAnalogData(hfile,EntityID,StartIndex,IndexCount);
    end
end

data=bsxfun(@minus,data',mean(data'));
data=data*10e5; % change the units from voltage to uV
% 

% for MAP 6*10
%     index = reshape(1:60, 6, 10).';
% for i = 1:60
%     subplot(10, 6, index(i));
%     plot(data(i,:));
%     axis([1 length(data) -200e-6 200e-6])
%   end


% make a plot
% for MAP inverse 8*8
MEAIdx=0;
subplotIdx = reshape(1:64, 8, 8).';
for MEALoc_i = 1:64
    if (MEALoc_i~=1) && (MEALoc_i~=8) && (MEALoc_i~=57) && (MEALoc_i~=64)
        subplot(8, 8, subplotIdx(MEALoc_i));
        MEAIdx=MEAIdx+1;
        t1=1:length(data(:,MEAIdx)); 
        t1=t1/sampRate; 
        plot(t1,data(:,MEAIdx));
        xlabel('Time(s)');
        ylabel('Voltage(uV)');
        axis([ [1.5 2] -50 50]);
    end
end

%The following code has the effect of removing the unwanted axis
%labels. Ultimately you would palce this in a separate function
%to allow for re-use. 

c=get(gcf,'children'); %get the axes
%Find the axis labels (since all are the same)
xlab= get(get(c(1),'xlabel'),'string');
ylab= get(get(c(1),'ylabel'),'string');

%Remove any currently existing axis labels, noting the location
%of each axis
pos=ones(length(c),4);
for i=1:length(c)
     pos(i,:)=get(c(i),'position');
     set(get(c(i),'xlabel'),'string','')
     set(get(c(i),'ylabel'),'string','')
end

%Add the labels back to the edge plots
for ii=1:length(c)
    %Add X 
    if pos(ii,2)==min(pos(:,2));
        set(get(c(ii),'xlabel'),'string',xlab)
    end
    %Add Y
    if pos(ii,1)==min(pos(:,1));
        set(get(c(ii),'ylabel'),'string',ylab)
    end
end
data3=NaN(8,8,size(data,1));

% rearrange the data to 3 dimensions
MEAIdx=0;
for i=1:8
    for j=1:8
        if ~((i==1 || i==8) && (j==1 || j==8))
            MEAIdx=MEAIdx+1;          
            data3(j,i,:)=data(:,MEAIdx);
        end
    end
end
[X,Y] = meshgrid(1:8,8:-1:1);

for i=1:length(contourTime)
        figure;contour(X,Y,data3(:,:,round(contourTime(i)*sampRate))); c=colorbar; view([0 90]);
        c.Label.String = 'Voltage (uV)';
%     figure;surf(X,Y,data3(:,:,round(t(i)*sampRate))); colorbar; view([0 90]);
end


cd(pwd);
end