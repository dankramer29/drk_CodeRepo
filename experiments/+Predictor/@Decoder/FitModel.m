function [Bcf, stats]=FitModel(obj,PRED,RESP)

switch lower(obj.decoderParams.fitType)
    case {'standard','crossvalquick'}
        Bcf=[PRED'\RESP']';
        cc=corrcoef((Bcf*PRED)',RESP');
        stats.R2=cc(2,1).^2;
        stats.cc=cc(2,1);
        
    case 'ridge'
        Bcf = ridge(RESP',PRED',k,0);
        
    case 'robust'
        mdl=LinearModel.fit(PRED',RESP','RobustOpts','on');
        Bcf=[mdl.Coefficients.Estimate(2:end)', mdl.Coefficients.Estimate(1)];
        stats.R2=mdl.Rsquared.Ordinary;
        
    case 'robustlasso'
        
        mdl=LinearModel.fit(PRED(1:end-1,:)',RESP','RobustOpts','on');
        Weights=mdl.Robust.Weights;
        
        %         fprintf('Lasso fit for dof %d ...',k)
        if matlabpool('size')>0
            opts = statset('UseParallel','always');
        else
            opts = statset('UseParallel','never');
        end
        %           [B FitInfo] = lasso(RESP',PRED','CV',10,'Options',opts);
        
        [B FitInfo] = lasso(PRED(1:end-1,:)',RESP','CV',obj.decoderParams.lassoOptions.CV ,'Options',opts,...
            'NumLambda',obj.decoderParams.lassoOptions.NumLambda,'Alpha', obj.decoderParams.lassoOptions.Alpha,...
            'Weights',Weights);
        
        % choose indx
        switch  obj.decoderParams.lassoOptions.optINDX
            case 'mid'
                OptIndx=round((FitInfo.IndexMinMSE+FitInfo.Index1SE)/2);
            case 'IndexMinMSE'
                OptIndx=FitInfo.IndexMinMSE;
            case 'Index1SE'
                OptIndx=FitInfo.Index1SE;
            otherwise
                OptIndx=round((FitInfo.IndexMinMSE+FitInfo.Index1SE)/2);
        end
        
        Bcf=[B(:,OptIndx)',FitInfo.Intercept(OptIndx)];
        
        if obj.decoderParams.lassoPlot
            lassoPlot(B,FitInfo,'PlotType','CV')
        end
        %         fprintf('took %0.2f secs \n             ',toc)
        cc=corrcoef((Bcf*PRED)',RESP');
        stats.R2=cc(2,1).^2;
        stats.cc=cc(2,1);
    case 'lasso'
        %         tic
        %         fprintf('Computing Lasso Fit...')
%         if matlabpool('size')>0
%             opts = statset('UseParallel','always');
%         else
            opts = statset('UseParallel','never');
%         end
        %           [B FitInfo] = lasso(RESP',PRED','CV',10,'Options',opts);
        
        [B FitInfo] = lasso(PRED(1:end-1,:)',RESP','CV',obj.decoderParams.lassoOptions.CV ,'Options',opts,...
            'NumLambda',obj.decoderParams.lassoOptions.NumLambda,'Alpha', obj.decoderParams.lassoOptions.Alpha);
        
        % choose indx
        switch  obj.decoderParams.lassoOptions.optINDX
            case 'mid'
                OptIndx=round((FitInfo.IndexMinMSE+FitInfo.Index1SE)/2);
            case 'IndexMinMSE'
                OptIndx=FitInfo.IndexMinMSE;
            case 'Index1SE'
                OptIndx=FitInfo.Index1SE;
            otherwise
                OptIndx=round((FitInfo.IndexMinMSE+FitInfo.Index1SE)/2);
        end
        
        Bcf=[B(:,OptIndx)',FitInfo.Intercept(OptIndx)];
        
        if obj.decoderParams.lassoPlot
            lassoPlot(B,FitInfo,'PlotType','CV')
        end
        %         fprintf('took %0.2f secs \n             ',toc)
        
        cc=corrcoef((Bcf*PRED)',RESP');
        stats.R2=cc(2,1).^2;
        stats.cc=cc(2,1);
        
    case 'speedlasso'
        %         weight the fit by the speed of movement
        %         fprintf('Computing Lasso Fit...')
        if matlabpool('size')>0
            opts = statset('UseParallel','always');
        else
            opts = statset('UseParallel','never');
        end
        %%
        % [B FitInfo] = lasso(RESP',PRED','CV',10,'Options',opts);
%         speed=obj.decoderParams.speed;
        speed=Utilities.mnorm(PRED(1:end-1,:)');
        peakSpeed=prctile(speed,95);
        Weights= speed./peakSpeed;
        Weights(Weights>1)=1; 
%         Weights=sqrt(Weights);
        Weights(Weights<.05)=.05;
        
%         Weights=Weights.^2;
%         Weights=Weights(obj.decoderParams.trainINDXS);
%         figure; plot(speed); hold on; plot(Weights,'r')
        %%
        
        [B FitInfo] = lasso(PRED(1:end-1,:)',RESP','CV',obj.decoderParams.lassoOptions.CV ,'Options',opts,...
            'NumLambda',obj.decoderParams.lassoOptions.NumLambda,'Alpha', obj.decoderParams.lassoOptions.Alpha,...
            'Weights',Weights);
        
        % choose indx
        switch  obj.decoderParams.lassoOptions.optINDX
            case 'mid'
                OptIndx=round((FitInfo.IndexMinMSE+FitInfo.Index1SE)/2);
            case 'IndexMinMSE'
                OptIndx=FitInfo.IndexMinMSE;
            case 'Index1SE'
                OptIndx=FitInfo.Index1SE;
            otherwise
                OptIndx=round((FitInfo.IndexMinMSE+FitInfo.Index1SE)/2);
        end
        
        Bcf=[B(:,OptIndx)',FitInfo.Intercept(OptIndx)];
        
        if obj.decoderParams.lassoPlot
            lassoPlot(B,FitInfo,'PlotType','CV')
        end
        %         fprintf('took %0.2f secs \n             ',toc)
        
        cc=corrcoef((Bcf*PRED)',RESP');
        stats.R2=cc(2,1).^2;
        stats.cc=cc(2,1);
        
end
% fitTime=toc;
% R2str=[R2str, sprintf('%0.2f ',R2(k))];

