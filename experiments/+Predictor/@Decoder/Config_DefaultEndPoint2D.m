function obj=Config_DefaultEndPoint2D(obj,varargin)

% obj=DefaultEndPoint2D(obj,localParams)
% Default configuratoin file for 2D endpoint control
%
% The configuration file is divided up into multiple fields
% decoderParams     Params that govern the construction of the decoder
% runtimeParams     Params that govern runtime operation of the decoder
% frameworkParams   Params that govern interation with the framework and OS
% guiParams         Params that govern construction and operation of GUI
% idealAgentParams  Params that govern the Ideal Agent

%% import necassary packages
import Utilities.getInputField

%% process localParams
if nargin==1, localParams=[]; else localParams=varargin{1}; end
if ~isfield(localParams,'frameworkParams'),     localParams.frameworkParams=[]; end
if ~isfield(localParams,'decoderParams'),       localParams.decoderParams=[];   end
if ~isfield(localParams,'runtimeParams'),       localParams.runtimeParams=[];   end
if ~isfield(localParams,'guiParams'),           localParams.guiParams=[];       end
if ~isfield(localParams,'idealAgentParams'),    localParams.idealAgentParams=[];end

%% frameworkParams
baseField=localParams.frameworkParams;
frameworkParams.savePath                        = getInputField(baseField,'savePath',pwd);
frameworkParams.saveName                        = getInputField(baseField,'saveName',[datestr(now,'yyyymmdd-HHMMSS') '_decoder.mat']);
frameworkParams.featureDescriptions             = getInputField(baseField,'featureDescriptions',[]);
frameworkParams.saveOnTrain                     = getInputField(baseField,'saveOnTrain',true);  % save out results of decoder training.
obj.frameworkParams=frameworkParams;

%% decoderParams
baseField=localParams.decoderParams;

% general properties
decoderParams.filterType                      = getInputField(baseField,'filterType','direct');
decoderParams.nDOF                            = getInputField(baseField,'nDOF',2);
decoderParams.dofLabels                       = getInputField(baseField,'dofLabels',{'X','Y'});
decoderParams.samplePeriod                    = getInputField(baseField,'samplePeriod',.05);
decoderParams.trainingTarget                  = getInputField(baseField,'trainingTarget','IdealPrediction'); % 'IdealPrediction', 'Kinematics'

% preprocess
decoderParams.minFiringRate                   = getInputField(baseField,'minFiringRate',2);
decoderParams.updateSignalStatisticsOnTrain   = getInputField(baseField,'updateSignalStatisticsOnTrain',true); % update signal statistics on each train
decoderParams.validFeatures                   = getInputField(baseField,'validFeatures',[]); % determine which features are considered for the decode model.
decoderParams.diffX                           = getInputField(baseField,'diffX',true); %(true, false)
decoderParams.diffType                        = getInputField(baseField,'diffType','intermediate'); % (causal, standard, intermediate)
decoderParams.zscoreZ                         = getInputField(baseField,'zscoreZ',true);
decoderParams.demeanX                         = getInputField(baseField,'demeanX',true);
decoderParams.demeanZ                         = getInputField(baseField,'demeanZ',false);
decoderParams.preProcessForSignificance       = getInputField(baseField,'preProcessForSignificance',true);
decoderParams.preProcessThreshold             = getInputField(baseField,'preProcessThreshold',.03); % threshold on R2
% general fitting
decoderParams.modelSmoothVal                  = getInputField(baseField,'modelSmoothVal',0.85);
decoderParams.lags2Process                    = getInputField(baseField,'lags2Process',-4:4:8);
decoderParams.trainINDXS                      = getInputField(baseField,'trainINDXS',[]);
decoderParams.fitType                         = getInputField(baseField,'fitType','lasso'); % standard standardQuick robust lasso crossValQuick

% crossvalidation options
if ~isfield(baseField,'cvOptions'),baseField.cvOptions=[];end
decoderParams.cvOptions.nFolds                = getInputField(baseField.cvOptions,'nFolds',10);
decoderParams.cvOptions.minTrainSize          = getInputField(baseField.cvOptions,'minTrainSize',2400); % 2500 allows filter to converge
decoderParams.cvOptions.minTestSize           = getInputField(baseField.cvOptions,'minTestSize',200);  % a reasonable amount to test

% arguements to the lasso function
decoderParams.lassoPlot          = getInputField(baseField ,'lassoPlot',true); %
if ~isfield(baseField,'lassoOptions'),baseField.lassoOptions=[];end

decoderParams.lassoOptions.Alpha                     = getInputField(baseField.lassoOptions ,'Alpha',1); %
decoderParams.lassoOptions.CV                        = getInputField(baseField.lassoOptions ,'CV',5); %
decoderParams.lassoOptions.NumLambda                 = getInputField(baseField.lassoOptions ,'NumLambda',50); %


% preSmoothingOptions (smoothing preformed prior to fit)
if ~isfield(baseField,'preSmoothOptions'),baseField.preSmoothOptions=[];end
decoderParams.preSmoothOptions.smoothTrainingData            = getInputField(baseField.preSmoothOptions,'smoothTrainingData',true); % exponential smoothing param
decoderParams.preSmoothOptions.filterType                    = getInputField(baseField.preSmoothOptions,'filterType','exp'); % type of filter
decoderParams.preSmoothOptions.expKernel                    = getInputField(baseField.preSmoothOptions,'expKernel',.85); % exponential smoothing kernel
decoderParams.preSmoothOptions.maxSamples                    = getInputField(baseField.preSmoothOptions,'maxSamples',50); % max samples
decoderParams.preSmoothOptions.plotFilter                    = getInputField(baseField.preSmoothOptions,'plotFilter',false); % plot filter
decoderParams.preSmoothOptions.lineSpec                    = getInputField(baseField.preSmoothOptions,'lineSpec','k.-'); % plot look



% kalman filter specific parameters (only assign if filterType==kalman)
if strcmp(decoderParams.filterType,'kalman')
    if ~isfield(baseField,'kalman'),baseField.kalman=[];end
    
    decoderParams.kalman.AW_A_type                = getInputField(baseField.kalman,'AW_A_type','autoRegressDamping');
    decoderParams.kalman.AW_W_type                = getInputField(baseField.kalman,'AW_W_type','shenoy');
    decoderParams.kalman.AW_W_weighting           = getInputField(baseField.kalman,'AW_W_weighting',12);
    decoderParams.kalman.AW_W_velSetting          = getInputField(baseField.kalman,'AW_W_velSetting',[]);
    decoderParams.kalman.velocityKF               = getInputField(baseField.kalman,'velocityKF',false);
    decoderParams.kalman.PK_type                  = getInputField(baseField.kalman,'PK_type','shenoy');
    decoderParams.kalman.HQ_H_FitMethod           = getInputField(baseField.kalman,'H_FitMethod','standard');
    decoderParams.kalman.HQ_lassoAlpha            = getInputField(baseField.kalman,'lassoAlpha',1); % Lasso fit option
    decoderParams.kalman.HQ_plotLasso             = getInputField(baseField.kalman,'plotLasso',false);% Lasso fit option
    decoderParams.kalman.HQ_augmentedForm         = getInputField(baseField.kalman,'augmentedForm',false);
end

obj.decoderParams=decoderParams;

%% runtimeParams
baseField=localParams.runtimeParams;

runtimeParams.adaptNeuralMean                   = getInputField(baseField,'adaptNeuralMean',0);
runtimeParams.adaptNeuralRate                   = getInputField(baseField,'adaptNeuralRate',4); % in minutes
runtimeParams.outputGain                        = getInputField(baseField,'outputGain',[1 1]);
runtimeParams.outputMax                         = getInputField(baseField,'outputMax',[inf inf]); 
runtimeParams.outputMin                         = getInputField(baseField,'outputMin',[-inf -inf]);
runtimeParams.assistLevel                       = getInputField(baseField,'assistLevel',0);
runtimeParams.assistType                        = getInputField(baseField,'assistType','WeightedAverage'); % (WeightedAverage,Projection)
runtimeParams.adhoc_smooth                      = getInputField(baseField,'adhoc_smooth',[]);
runtimeParams.bufferCapacity                    = getInputField(baseField,'bufferCapacity',10000);

obj.runtimeParams=runtimeParams;

%% idealAgentParams
baseField=localParams.idealAgentParams;

idealAgentParams.make                               = getInputField(baseField,'make',true); % make predictions using ideal agent
idealAgentParams.type                               = getInputField(baseField,'type','mjOptAgent'); % (WeightedCombination,Projection)
idealAgentParams.mvmntDuration                      = getInputField(baseField,'mvmntDuration',1500); % (WeightedCombination,Projection)

obj.idealAgentParams=idealAgentParams;