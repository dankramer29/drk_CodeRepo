function componentAnglePlot( dPCA_out, numCompToShow )
  
    if nargin<2
        numCompToShow = size(dPCA_out.W,2);
    end
    
    figure('Position',[379   855   312   243]);
    
    % angles and correlations between components
    Z = dPCA_out.Z(:,:)';
    a = corr(Z(:,1:numCompToShow));
    b = dPCA_out.V(:,1:numCompToShow)'*dPCA_out.V(:,1:numCompToShow);

    [~, psp] = corr(dPCA_out.V(:,1:numCompToShow), 'type', 'Kendall');
    map = tril(a,-1)+triu(b);
    
    imagesc(map,[-1 1]);
    
    cMap = diverging_map(linspace(0,1,100),[0 0 1],[1 0 0]);
    colormap(cMap);

    xlabel('Component')
    ylabel('Component')
    set(gca,'FontSize',16,'LineWidth',2);

    cb = colorbar('FontSize',16,'LineWidth',2);

    hold on
    [i,j] = ind2sub(size(triu(b,1)), ...
        find(abs(triu(b,1)) > 3.3/sqrt(size(dPCA_out.V,1)) & psp<0.001)); % & abs(csp)>0.02));
    plot(j,i,'k*')
    
    text(0.57,0.90,'Dot Product\newlineBetween Axes','FontSize',12,'Units','Normalized');
    text(0.05,0.15,'Correlation Between\newlineComponents','FontSize',12,'Units','Normalized');
end

