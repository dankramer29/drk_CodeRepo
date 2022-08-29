function p=CompareFiringRates(Z,unitINDX,PlotResults)
% compare the firing rate features in the training sets

% %%
if nargin<2; 
    warning('nargin==1 ; must specify unit to process')
end


%
if nargin<3; 
PlotResults=false;
end
% unitINDX=1;
% 
% decoders=obj.decoderBAK;
% 
% %%
 p1 = pdf('Normal',-3:.5:3,0,1); p1=p1/sum(p1);
 
 
A=[]; B=[]; MED=[];
for indx=1:length(Z)
A=[A ; Z{indx}(unitINDX,:)'];
B=[B ; Z{indx}(unitINDX,:)'*0+indx];
MED=[MED ; mean(Z{indx}(unitINDX,:)')];
end



% [p,table,stats] = kruskalwallis(A,B,'off');

[p,table,stats] = anova1(A,B,'off');

% note that anaova assumes independent samples.  Here we are uning an
% autocorrelated signal... consertively, estimate that the dofs are about
% 10 times less.
xunder = 1./max(0,table{2,5});
xunder(isnan(table{2,5})) = NaN;
nd=max(round(length(A)/10),500);
p = fcdf(xunder,nd,1);

% if ~PlotResults; return; end

if length(unique(A))<=20 && min(A)==0
edges=0:1:max(A(:));
else
edges=linspace(min(A),max(A),20);
end
maxdist=pairdist(MED);maxdist=max(maxdist(:))/edges(end)*100;
Counts=[];
for indx=1:length(Z)
[Counts(size(Counts,1)+1,:)]=histc(Z{indx}(unitINDX,:)',edges);
end

% normalize for number of trials
Counts=Counts./repmat(sum(Counts,2),1,length(edges));

bar(edges,Counts');
ylabel('% Bins')
xlabel('Count')

bkgrdcolor=[0 1 0];
if p>.05 && maxdist>2
    bkgrdcolor=[0 1 0];
elseif p<=.05 && p>.001 && maxdist>2
    bkgrdcolor=[1 1 0];
elseif p<=.001  && maxdist>2
    bkgrdcolor=[1 0 0];
end
set(gca,'color',bkgrdcolor)
axis tight
title(sprintf('U%d ; MD=%0.1f; p=%0.3f)',unitINDX,maxdist,p))
%%
