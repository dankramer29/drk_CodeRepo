function decoderProps=MakeDecoder(obj,decoderTMP,trainingDataLag)

switch lower(obj.decoderParams.filterType)
    %     case 'tuningcurves'
    %         PopVec=ComputeTuningCurves(obj,x,z);
    %         return
    %
    %     case 'comparetuningcurves'
    %         [x,z,trainINDXlag]=ShiftData(obj,x,z,trainINDXS,6);
    %         obj.decoderParams.TuningFeatures='xdx';
    %         PopVec=ComputeTuningCurves(obj,x,z);
    %         obj.decoderParams.TuningFeatures='x';
    %         PopVec_x=ComputeTuningCurves(obj,x,z);
    %         obj.decoderParams.TuningFeatures='s';
    %         PopVec_s=ComputeTuningCurves(obj,x,z);
    %         obj.decoderParams.TuningFeatures='dx';
    %         PopVec_dx=ComputeTuningCurves(obj,x,z);
    %         obj.decoderParams.TuningFeatures='xdxs';
    %         PopVec_xdxs=ComputeTuningCurves(obj,x,z);
    %         obj.decoderParams.TuningFeatures='dxs';
    %
    %         PopVec_dxs=ComputeTuningCurves(obj,x,z);
    %         %%
    %         figure; hold on;
    %         plot(sort(PopVec.R2_CVmu),'.--');
    %         plot(sort(PopVec_s.R2_CVmu),'r.--');
    %         plot(sort(PopVec_dx.R2_CVmu),'g.--');
    %         plot(sort(PopVec_xdxs.R2_CVmu),'k.--');
    %         plot(sort(PopVec_x.R2_CVmu),'m.--');
    %         plot(sort(PopVec_dxs.R2_CVmu),'.--','color',[.5 .5 .5]);
    %         legend('xdx','s','dx','xdxs','x','dxs')
    %         return
    %
    % %     case 'kalman'
    % %         obj.trainAW(x);
    % %         obj.trainHQ(x,z);
    % %         obj.trainKalman(x,z);
    % %         %       obj.trainPK;
    
    
    case {'kalman','sskalman','kalmanfit'}
        x=decoderTMP.trainingData.X;
        trainINDXS=decoderTMP.trainingData.trainINDXS;
        [A,W]=obj.trainAW(x,trainINDXS);
        decoderProps.raw.A=A;
        decoderProps.raw.W=W;
        decoderProps.raw.H=decoderTMP.PopVec.H;
        decoderProps.raw.Q=decoderTMP.PopVec.Q;
        decoderProps.decodeFeatures=decoderTMP.PopVec.decodeFeatures;
        
        decoderTMP.decoderProps=decoderProps;
        decoderProps=obj.trainKalman(decoderTMP);
        
        % obj.batchPredict(xraw,zraw);
        
    case 'inversion'
        Bcf=decoderTMP.PopVec.IV.Bcf;
        
        
        
        
        
        decoderProps.Bcf=Bcf;
        decoderProps.decodeFeatures=decoderTMP.PopVec.decodeFeatures;
        
        
        if isfield(decoderTMP.PopVec.IV, 'R2_CV')
            cv.R2=decoderTMP.PopVec.IV.R2_CV;
            cv.Bcf=decoderTMP.PopVec.IV.Bcf_CV;
            
            decoderProps.cv=cv;
            decoderProps.R2cv=decoderTMP.PopVec.IV.R2_CVmu;
            decoderProps.R2=decoderTMP.PopVec.IV.R2;
        end
        
        
    case 'direct'
        
        [Bcf,R2,cvTMP]=obj.directLinearDecoderV3(decoderTMP);
        
        if ~isempty(cvTMP)
            if isstruct(cvTMP)
                cv.R2=cell2mat(cvTMP.R2')';
                for j=1:size(cvTMP.Bcf{1},1)
                    for i=length(cvTMP.Bcf);
                        BcfCV{j}(i,:)=cvTMP.Bcf{i}(j,:);
                    end
                end
                R2cv=nanmean(cv.R2);
                decoderProps.R2cv=R2cv;
                decoderProps.cv=cv;
            else
                decoderProps.R2cv=cell2mat(cvTMP);
            end
        end
        
        decoderProps.decodeFeatures=decoderTMP.PopVec.decodeFeatures;
        decoderProps.Bcf=Bcf;
        decoderProps.R2=R2;
        
end
% process to find optimal lag


