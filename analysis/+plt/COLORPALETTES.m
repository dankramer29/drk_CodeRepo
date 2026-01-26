%ColorPalettes
%this will take some aesthetically pleasing color wheels for use in plots.

%%
%first, convert hex to rgb which is somewhat easier than picking out rgbs
%You can pull both from powerpoint with the dropper function but easier to
%cut and paste the hex code.

%to pull colors, go into power point and next to the rainbow or color
%wheel, make a shape, then go to fill, use the eye dropper and grab the
%color, then go back to fill and do "more fill colors and it will be on the
%color you like.

colorTempTest = {'#87bf54', '#65bda5', '#50bcdf'};

for ii = 1:length(colorTempTest)
    str = colorTempTest{ii};
    colorTempTestRGB(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end

%% plots to look at them.
figure
X = repmat(10,1,length(C));
Y = 1:length(C);
bb = bar(Y,X);
bb.FaceColor = 'flat';
for ii = 1:length(C)
    bb.CData(ii,:) = C(ii,:);
end


figure
hold on
X=1:10;
for ii=1:N
    Y=X+ii;
    plot(Y, 'LineWidth', 3, 'color', C(ii,:))
end


%% This is just an evenly spaced color wheel

N=100;
C=linspecer(N); 


figure
hold on
X=1:10;
for ii=1:N
    Y=X+ii;
    plot(Y, 'LineWidth', 3, 'color', C(ii,:))
end

%% darker color wheel (this one is page 3 of color pallettes in power poin

colorTempTest = {'#1A1334', '#26294A', '#055459', '#077353', '#14C285', '#ABD96D', '#FCBF54', '#EE6C3B', '#EC0E47', '#A02C5D', '#710461', '#022B7A' };

for ii = 1:length(colorTempTest)
    str = colorTempTest{ii};
    C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end

figure
X = repmat(10,1,length(C));
Y = 1:length(C);
bb = bar(Y,X);
bb.FaceColor = 'flat';
for ii = 1:length(C)
    bb.CData(ii,:) = C(ii,:);
end

figure
hold on
X=1:10;
for ii=1:length(C)
    Y=X+ii;
    plot(Y, 'LineWidth', 3, 'color', C(ii,:))
end




%% lighter more pastel color wheel (first page)
colorTempTest = {'#fee327', '#fdca54', '#f6a570', '#f1969b', '#f08ab1', '#c78dbd', '#927db6', '#5da0d7', '#00b3e1', '#50bcbf', '#65bda5', '#87bf54' };
for ii = 1:length(colorTempTest)
    str = colorTempTest{ii};
    C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end

figure
X = repmat(10,1,length(C));
Y = 1:length(C);
bb = bar(Y,X);
bb.FaceColor = 'flat';
for ii = 1:length(C)
    bb.CData(ii,:) = C(ii,:);
end


figure
hold on
X=1:10;
for ii=1:length(C)
    Y=X+ii;
    plot(Y, 'LineWidth', 3, 'color', C(ii,:))
end


%% alternate with pastel version of each
clear colorTempTest
clear C
colorTempTest = {'#228511', '#B1EDDD','#0E4D92', '#C9E4FF',  '#4E2A84', '#E3D7FF'};
for ii = 1:length(colorTempTest)
    str = colorTempTest{ii};
    C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end


figure
X = repmat(10,1,length(C));
Y = 1:length(C);
bb = bar(Y,X);
bb.FaceColor = 'flat';
for ii = 1:length(C)
    bb.CData(ii,:) = C(ii,:);
end

%% better green, blue, purple
clear colorTempTest
clear C
colorTempTest = {'#38761dff', '#93c47dff', '#c9daf8ff', '#6d9eebff', '#8e7cc3ff', '#d9d2e9ff'};
for ii = 1:length(colorTempTest)
    str = colorTempTest{ii};
    C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end


figure
X = repmat(10,1,length(C));
Y = 1:length(C);
bb = bar(Y,X);
bb.FaceColor = 'flat';
for ii = 1:length(C)
    bb.CData(ii,:) = C(ii,:);
end

%% pastel alternat version
clear colorTempTest
clear C
colorTempTest = {'#93c47dff', '#b6d7a8ff', '#d9ead3ff', '#3d85c6ff', '#9fc5e8ff','#d0e0e3ff'};
for ii = 1:length(colorTempTest)
    str = colorTempTest{ii};
    C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end


figure
X = repmat(10,1,length(C));
Y = 1:length(C);
bb = bar(Y,X);
bb.FaceColor = 'flat';
for ii = 1:length(C)
    bb.CData(ii,:) = C(ii,:);
end

%% bright purple blue and orange
clear colorTempTest
clear C
colorTempTest = {'#ff00ffff', '#9900ffff', '#0000ffff', '#00ffffff', '#ffff00ff','#ff9900ff'};
for ii = 1:length(colorTempTest)
    str = colorTempTest{ii};
    C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end


figure
X = repmat(10,1,length(C));
Y = 1:length(C);
bb = bar(Y,X);
bb.FaceColor = 'flat';
for ii = 1:length(C)
    bb.CData(ii,:) = C(ii,:);
end


%% bright green/blue/purple
colorTempTest = {'#228E2C', '#64D413', '#0072BD', '#4DBEEE', '#7E2F8E', '#FF13A6'};
for ii = 1:length(colorTempTest)
    str = colorTempTest{ii};
    C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end

figure
X = repmat(10,1,length(C));
Y = 1:length(C);
bb = bar(Y,X);
bb.FaceColor = 'flat';
for ii = 1:length(C)
    bb.CData(ii,:) = C(ii,:);
end

%% slightly darker version
colorTempTest = {'#38761dff', '#93c47dff', '#0b5394ff', '#6d9eebff', '#9c1eb0ff', '#a587c9ff'};
for ii = 1:length(colorTempTest)
    str = colorTempTest{ii};
    C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end

figure
X = repmat(10,1,length(C));
Y = 1:length(C);
bb = bar(Y,X);
bb.FaceColor = 'flat';
for ii = 1:length(C)
    bb.CData(ii,:) = C(ii,:);
end

%% dark version colors for blue green purple
%just three

colorTempTest = { '#274e13ff', '#153465ff','#691060ff'};
for ii = 1:length(colorTempTest)
    str = colorTempTest{ii};
    C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end

figure
X = repmat(10,1,length(C));
Y = 1:length(C);
bb = bar(Y,X);
bb.FaceColor = 'flat';
for ii = 1:length(C)
    bb.CData(ii,:) = C(ii,:);
end

% sunset

colorTempTest = { '#240002', '#6f0100', '#a53005', '#d97d0c', '#fec135'};
for ii = 1:length(colorTempTest)
    str = colorTempTest{ii};
    C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end

figure
X = repmat(10,1,length(C));
Y = 1:length(C);
bb = bar(Y,X);
bb.FaceColor = 'flat';
for ii = 1:length(C)
    bb.CData(ii,:) = C(ii,:);
end

%% a two color version of red and blue
clear colorTempTest C
colorTempTest = { '#DA3068', '#14469F'};
for ii = 1:length(colorTempTest)
    str = colorTempTest{ii};
    C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end

figure
X = repmat(10,1,length(C));
Y = 1:length(C);
bb = bar(Y,X);
bb.FaceColor = 'flat';
for ii = 1:length(C)
    bb.CData(ii,:) = C(ii,:);
end

%% three color blue to light blue to red 
clear colorTempTest 
clear C

colorTempTest = { '#769FCB', '#DDF0F7', '#FF6C65'}; %blue red combo
for ii = 1:length(colorTempTest)
    str = colorTempTest{ii};
    C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end

figure
X = repmat(10,1,length(C));
Y = 1:length(C);
bb = bar(Y,X);
bb.FaceColor = 'flat';
for ii = 1:length(C)
    bb.CData(ii,:) = C(ii,:);
end

% pink brown, yellow, green, purple blue
colorTempTest = {'#fee327', '#47181e',  '#f08ab1',  '#927db6', '#00b3e1',  '#87bf54' };


% red brown, yellow, green, purple blue (same as above)

colorTempTest = {'#9B4923', '#C31704',  '#F4C500', '#927db6', '#00b3e1',  '#87bf54'};

