function p=compareTrainingSets(obj,decINDXs,unitINDXs)
% compare training sets in decoderBAK


if nargin<2 || isempty(decINDXs)
    decINDXs=1:length(obj.decoderBAK);
end

for i=decINDXs
    Z{i}=obj.decoderBAK(i).decoderProps.Z;
    activeFeatures{i}=obj.decoderBAK(i).decoderProps.activeFeatures;
end

if nargin<3
    obj.msgName('No Unit Indices specified : restricting to activeFeatures ()');
    unitINDXs=find(sum(cell2mat(activeFeatures),2)>=1);
end


subPlotDims=plt.getSubPlotDimensions(length(unitINDXs));

h=plt.fig('units','inches','width',subPlotDims(2)*1.5,'height',subPlotDims(1)*1.5,'font','Helvetica','fontsize',10);

% first pass, get p vals
indx=1;
% for curUnit=unitINDXs(:)';
% %     p=CompareFiringRates(Z,unitINDX,PlotResults)
%     plt.mysubplot(subPlotDims(1),subPlotDims(2),indx);
%     p(indx)=Predictor.Decoder.CompareFiringRates(Z,curUnit);
%     indx=indx+1;
% end


% first pass, get p vals
% write beta values into full length vector;

nBetas=length(obj.decoderBAK(i).decoderProps.activeFeatures)+1;
Bc=zeros(length(decINDXs),nBetas,obj.decoderParams.nDOF);

for i=decINDXs
    for j=1:obj.decoderParams.nDOF;
        Bc(i,[obj.decoderBAK(i).decoderProps.activeFeatures; true],j)=obj.decoderBAK(i).decoderProps.Bc(j*2,:);
    end
    groupNames{i}=obj.decoderBAK(i).decoderProps.groupName;
end

[uGroupNames,b,groupINDXS]=unique(groupNames);
% Bc=Bc(:,[unitINDXs;nBetas ],:);
%%
% colors=[linspace(0,1,length(uGroupNames)); linspace(0,0,length(uGroupNames)); linspace(1,0,length(uGroupNames))]';
colors=jet(length(uGroupNames));
% layout=uiextras.TabPanel('Parent',f);
for dof=1:obj.decoderParams.nDOF
    %     axes('Parent', layout)
    % g=uiextras.GridFlex('Parent',layout);
    plt.fig('units','inches','width',subPlotDims(2)*1.5,'height',subPlotDims(1)*1.5,'font','Helvetica','fontsize',10);
    
    %%
    indx=1;
    foo=Bc(:,:,dof);
    foo=sort(foo(:)); nf=round(length(foo)*.01);
    
    lims(1)=min(foo(nf)); lims(2)=max(foo(end-nf));
    
    for curUnit=unitINDXs(:)';
        
        edges=Bc(:,curUnit,dof); edges=abs(edges(:));
        edges=linspace(-max(edges),max(edges)+.0001,10);
        mp=(edges(2)-edges(1))/2;
        
        %     p=CompareFiringRates(Z,unitINDX,PlotResults)
        plt.mysubplot(subPlotDims(1),subPlotDims(2),indx);hold on
        %      tmp=uicontrol('Parent',g)
        %      ax= axes('Parent', g,'ActivePositionProperty','OuterPosition');
        for gn=1:length(uGroupNames)
            %             bins(gn,:)=histc(Bc(groupINDXS==gn,curUnit,dof)',edges);
            [f,xi,bw]=ksdensity(Bc(groupINDXS==gn,curUnit,dof)');
            [f,xi]=ksdensity(Bc(groupINDXS==gn,curUnit,dof)','bandwidth',bw/2);
            
            plot(xi,f,'color',colors(gn,:));
            % boundedline(xi,f,[f;f*0]','cmap',colors(gn,:),'alpha')
        end
        %         bar(edges(1:end-1)'+mp,bins(:,1:end-1)','EdgeColor','None','BarWidth',1)
        axis tight
        xlim(lims)
        indx=indx+1;
    end
    % set(g,'ColumnSizes',repmat(-1,1,subPlotDims(1)),'RowSizes',repmat(-1,1,subPlotDims(2)))
    legend(uGroupNames)
end






%% plot as function of decoder indx
for dof=1:obj.decoderParams.nDOF
    %     axes('Parent', layout)
    % g=uiextras.GridFlex('Parent',layout);
    plt.fig('units','inches','width',subPlotDims(2)*1.5,'height',subPlotDims(1)*1.5,'font','Helvetica','fontsize',10);
    
    %%
    indx=1;
    foo=Bc(:,:,dof);
    foo=sort(foo(:)); nf=round(length(foo)*.01);
    
    lims(1)=min(foo(nf)); lims(2)=max(foo(end-nf));
    
    for curUnit=unitINDXs(:)';
        
        plt.mysubplot(subPlotDims(1),subPlotDims(2),indx);hold on
        
        for gn=1:length(uGroupNames)
                       
            values=Bc(groupINDXS==gn,curUnit,dof)';
            plot(values,'color',colors(gn,:))
            
        end
        %         bar(edges(1:end-1)'+mp,bins(:,1:end-1)','EdgeColor','None','BarWidth',1)
        axis tight
        ylim(lims)
        indx=indx+1;
    end
    % set(g,'ColumnSizes',repmat(-1,1,subPlotDims(1)),'RowSizes',repmat(-1,1,subPlotDims(2)))
    legend(uGroupNames)
end