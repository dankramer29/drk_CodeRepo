function GenerateControlFormSolution
tic
switch obj.decoderParams.fitType
    case 'standard'
        Vmdl1{k}=LinearModel.fit(smoothZ',dXsmooth(k,:)');
        R2(k)=Vmdl1{k}.Rsquared.Ordinary;
        %     %Construct Force Vectors
        Bcf(k,:)=[Vmdl1{k}.Coefficients.Estimate(2:end)', Vmdl1{k}.Coefficients.Estimate(1)];
        
    case 'standardQuick'
        Bcf(k,:)=[smoothZ'\dXsmooth(k,:)']';
        
        
    case 'robust'
        Vmdl1{k}=LinearModel.fit(smoothZ(1:end-1,:)',dXsmooth(k,:)','RobustOpts','on');
        Bcf(k,:)=[Vmdl1{k}.Coefficients.Estimate(2:end)', Vmdl1{k}.Coefficients.Estimate(1)];
        
        
    case 'lasso'
        obj.msgName(sprintf('Lasso fit for dof %d ...',k),0)
        if matlabpool('size')>0
            opts = statset('UseParallel','always');
        else
            opts = statset('UseParallel','never');
        end
        
        [B FitInfo] = lasso(smoothZ(1:end-1,:)',dXsmooth(k,:)','CV',obj.decoderParams.lassoOptions.CV ,'Options',opts,'NumLambda',obj.decoderParams.lassoOptions.NumLambda,'Alpha', obj.decoderParams.lassoOptions.Alpha);
        
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
        
        Bcf(k,:)=[B(:,OptIndx)',FitInfo.Intercept(OptIndx)];
        obj.msgName(sprintf('took %0.2f secs',toc),1,0)
        
end