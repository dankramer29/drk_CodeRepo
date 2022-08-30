classdef NeuralMapping < handle
    
    properties
        Params
        
        FitParams
        FitResults
        
        
        verbosity  =1;  %[1:Everything, 2:Less 3: EvenLess 4:None]
    end
    
    
    methods
        function NeuralMapping(varargin)
             [varargin,PlotFit]   = Utilities.ProcVarargin(varargin,'PlotFit',0);
             [varargin,Params]   = Utilities.ProcVarargin(varargin,'Params',[]);
             [varargin,trainINDXS]   = Utilities.ProcVarargin(varargin,'Type',[]);
        end
        
        function [Bcf,R2,cv]=EstimateMapping(X,Z,varargin)
            
            %% wrapper interface for various mappings between Z->X
            
            %% set defaults for varargin
            [varargin,PlotFit]   = Utilities.ProcVarargin(varargin,'PlotFit',0);
            [varargin,trainINDXS]   = Utilities.ProcVarargin(varargin,'trainINDXS',[]);
            [varargin,Params]   = Utilities.ProcVarargin(varargin,'Params',[]);
            
            AllTrialData = Analyze.LoadConvertedData('TrajectoryControl','20151207');
            
            %%
%             for tmp=.5:.05:1;
%             % State=Analyze.returnFieldValues(AllTrialData,'State');
%             [X,StatesRun]=Analyze.getContinuousData(AllTrialData,'All','state');
%             [T,targetRun]=Analyze.getContinuousData(AllTrialData,'All','target');
%             [Z,FeaturesRun]=Analyze.getContinuousData(AllTrialData,'All','features');
%             SmoothingFilter=DecUtil.makeSmoothingFilter('exp',[2 tmp]);%           
%             Z=DecUtil.filter_mirrored(Z',SmoothingFilter)';
%             
%              Ze=[Z,ones(size(Z,1),1)];
%                     Bcf=[Ze\X]';
%                     Xhat=(Bcf*Ze')';
%                     R2=diag(corr(Xhat,X).^2)'
%                     figure; hold on
%                     plot(X(:,2))
%                     plot(Xhat(:,2))
%                     title(num2str(R2(2)))
%                     xlim([500 1500])
%             end
                    %%
            
            if isempty(trainINDXS);
                trainINDXS=1:size(X,1);
            end
            
            
            switch lower(Type)
                
                case 'linear'
                    Ze=[Z,ones(size(Z,1),1)];
                    Bcf=[Ze\X]';
                    Xhat=(Bcf*Ze');
                    R2=diag(corr(Xhat',X).^2)';
                    
                case 'linearModel'
                    for k=1:size(X,2)
                        Vmdl1{k}=LinearModel.fit(Z,X(:,k));
                        R2(k)=Vmdl1{k}.Rsquared.Ordinary;
                        %     %Construct Force Vectors
                        Bcf(k,:)=[Vmdl1{k}.Coefficients.Estimate(2:end)', Vmdl1{k}.Coefficients.Estimate(1)];
                    end
                    
                    
                case 'robust'
                    Vmdl1{k}=LinearModel.fit(Z,X(:,k),'RobustOpts','on');
                    Bcf(k,:)=[Vmdl1{k}.Coefficients.Estimate(2:end)', Vmdl1{k}.Coefficients.Estimate(1)];
                    R2(k)=Vmdl1{k}.Rsquared.Ordinary;
                    
                    
                case 'lasso'
                    obj.msgName(sprintf('Lasso fit for dof %d ...',k),0);
                    %             if matlabpool('size')>0
                    %                 opts = statset('UseParallel','always');
                    %             else
                    opts = statset('UseParallel','never');
                    %             end
                    %           [B FitInfo] = lasso(sX(k,:)',sZ','CV',10,'Options',opts);
                    if isempty(Params)
                        Params.CV=8;
                        Params.NumLambda=30;
                        Params.Alpha=1;
                        Params.lassoPlot=1;
                        Params.optINDX='mid';
                    end
                    
                    for k=1:size(X,2)
                        [B,FitInfo] = lasso(Z,X(:,k),'CV',Params.CV ,'Options',opts,...
                            'NumLambda',Params.NumLambda,'Alpha', Params.Alpha);
                        
                        % choose indx
                        switch  Params.optINDX
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
                        
                        MSE=FitInfo.MSE(OptIndx);
                        cv{k}=1-(MSE/var(X(:,k)));
                        
                        if Params.lassoPlot
                            lassoPlot(B,FitInfo,'PlotType','CV')
                        end
                    end
                    Ze=[Z,ones(size(Z,1),1)];
                    Xhat=(Bcf*Ze');
                    R2=diag(corr(Xhat',X).^2)';
                    
                    
                    
            end
        end
    end
end
    
