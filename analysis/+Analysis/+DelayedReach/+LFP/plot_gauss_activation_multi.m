function plot_gauss_activation_multi(grid_activs_1, elecmatrix_1,grid_activs_2, elecmatrix_2,grid_activs_3, elecmatrix_3, cortex)
    
    elec_stack = [elecmatrix_1; elecmatrix_2;  elecmatrix_3];
    brain=cortex.vert;
    load('dg_colormap.mat', 'cm') %KM color scheme
%     load('loc_colormap.mat', 'cm') %EC lab color scheme

    %g1 = g_mp
    %g2 = g_rip
    %g3 = g_rsp
    
    g1 = zeros(length(cortex(:,1)),1);
    gsp1 = 20;

    for k=1:length(elecmatrix_1(:,1)) %cycle through, adding gaussian shading
        b_z=abs(brain(:,3)-elecmatrix_1(k,3));
        b_y=abs(brain(:,2)-elecmatrix_1(k,2));
        b_x=abs(brain(:,1)-elecmatrix_1(k,1));
        d=grid_activs_1(k)*exp((-(b_x.^2+b_z.^2+b_y.^2))/gsp1); %gaussian 
        g1 = g1 + d';
    end
    
    g2 = zeros(length(cortex(:,1)),1);
    gsp2 = 50;

    for k=1:length(elecmatrix_2(:,1)) %cycle through, adding gaussian shading
        b_z=abs(brain(:,3)-elecmatrix_2(k,3));
        b_y=abs(brain(:,2)-elecmatrix_2(k,2));
        b_x=abs(brain(:,1)-elecmatrix_2(k,1));
        d=grid_activs_2(k)*exp((-(b_x.^2+b_z.^2+b_y.^2))/gsp2); %gaussian 
        g2 = g2 + d';
    end
    
    g3 = zeros(length(cortex(:,1)),1);
    gsp3 = 50;

    for k=1:length(elecmatrix_3(:,1)) %cycle through, adding gaussian shading
        b_z=abs(brain(:,3)-elecmatrix_3(k,3));
        b_y=abs(brain(:,2)-elecmatrix_3(k,2));
        b_x=abs(brain(:,1)-elecmatrix_3(k,1));
        d=grid_activs_3(k)*exp((-(b_x.^2+b_z.^2+b_y.^2))/gsp3); %gaussian 
        g3 = g3 + d';
    end

    g1_indx = ~(g1 > -0.0010 & g1 < 0.0010);
    g2_indx = ~(g2 > -0.0010 & g2 < 0.0010);
    g3_indx = ~(g3 > -0.0010 & g3 < 0.0010);

    if any(g1_indx & g2_indx)
        g_and_indx = g1_indx & g2_indx;
        g_larg_indx = abs(g1) > abs(g2);
        g2_indx(g_larg_indx & g_and_indx) = 0;
    end
    if any(g1_indx & g3_indx)
        g_and_indx = g1_indx & g3_indx;
        g_larg_indx = abs(g1) > abs(g3);
        g3_indx(g_larg_indx & g_and_indx) = 0;
    end
    if any(g3_indx & g2_indx)
        g_and_indx = g3_indx & g3_indx;
        g_larg_indx = abs(g3) > abs(g2);
        g2_indx(g_larg_indx & g_and_indx) = 0;
    end

    g_all = g1;
    g_all(g2_indx) = g2(g2_indx);
    g_all(g3_indx) = g3(g3_indx);

    tripatch(cortex, 'nofigure', g_all');
    shading interp;
    g_a=get(gca);
    g_d=g_a.CLim;
    set(gca,'CLim',[-max(abs(g_d)) max(abs(g_d))])
    l=light;
    colormap(cm)
    lighting gouraud;
    material dull;
    axis off

    % change view and lighting 
    if mean(elec_stack(:,1))<0 % left
        view(270, 0); set(l,'Position',[-1 0 1]) 
    else % right
        view(90, 0); set(l,'Position',[1 0 1])
    end
    view(90, 0); set(l,'Position',[1 0 1]) 
    set(gcf, 'color', 'w')

    plot3(elecmatrix_3(:,1)*1.01, elecmatrix_3(:,2), elecmatrix_3(:,3),'.','MarkerSize',12,'Color',[.99 .99 .99])
    plot3(elecmatrix_2(:,1)*1.01, elecmatrix_2(:,2), elecmatrix_2(:,3),'.','MarkerSize',12,'Color',[.99 .99 .99])
    plot3(elecmatrix_1(:,1)*1.01, elecmatrix_1(:,2), elecmatrix_1(:,3),'.','MarkerSize',5,'Color',[.99 .99 .99])
    
    
    hold off
end