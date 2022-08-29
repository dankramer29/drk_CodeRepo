function obj=Keck(obj,varargin)

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
import util.getInputField

TaskInformation.targetDistance=.2; 
TaskInformation.targetSize=.1;
frameworkParams.name='Keck';

decoderParams.minFiringRate =2;

frameworkParams.BufferFunction=@Predictor.FWBufferFunc.test;
% frameworkParams.BufferFunction=[];

decoderParams.preSmoothKinematics=0;
decoderParams.preSmoothOptions.deTrendVelocity=0;
decoderParams.PredictFunction=  @PredictContinuous;
decoderParams.batchTrainScript={@Predictor.BatchTrainScripts.Rancho_Obs,...
                                @Predictor.BatchTrainScripts.Rancho_ReTrain};
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

%% featureProps
% featureProps.featType=[2*ones(87,1);ones(14,1)];
featureProps.featType=[];
obj.featureProps=featureProps;



decoderParams.saveTrainingData=1;




%% decoderParams
baseField=localParams.decoderParams;

decoderParams.asynchronous=0;
decoderParams.popVecDispersion=0;

% warning('Only using spikes!');
decoderParams.useSpiking=1;
decoderParams.useLFP=1;

decoderParams.fitType                         = getInputField(baseField,'fitType','lasso'); % standard standardQuick robust lasso crossValQuick
decoderParams.filterType                      = getInputField(baseField,'filterType','direct'); % inversion


decoderParams.adaptNeuralMean                   = getInputField(baseField,'adaptNeuralMean',0);
decoderParams.adaptNeuralRate                   = getInputField(baseField,'adaptNeuralRate',10);
decoderParams.applySpeedAdaptiveFilter        = getInputField(baseField,'applySpeedAdaptiveFilter',0);

decoderParams.useCov                          = getInputField(baseField,'useCov',1);



% general properties
if ~isempty(obj.hFramework)
    decoderParams.nDOF                        = getInputField(baseField,'nDOF',obj.hFramework.options.nDOF);
else
    decoderParams.nDOF                        = getInputField(baseField,'nDOF',2);
end
decoderParams.dofLabels                       = getInputField(baseField,'dofLabels',{'X','Y'});
decoderParams.samplePeriod                    = getInputField(baseField,'samplePeriod',.05);
decoderParams.trainingTarget                  = getInputField(baseField,'trainingTarget','AssistedPrediction'); % 'IdealPrediction', 'Kinematics' 'AssistedPrediction'


% preprocess

decoderParams.updateSignalStatisticsOnTrain   = getInputField(baseField,'updateSignalStatisticsOnTrain',true); % update signal statistics on each train
decoderParams.validFeatures                   = getInputField(baseField,'validFeatures',[]); % determine which features are considered for the decode model.
decoderParams.diffX                           = getInputField(baseField,'diffX',true); %(true, false)
decoderParams.diffType                        = getInputField(baseField,'diffType','intermediate'); % (causal, standard, intermediate)
decoderParams.zscoreZ                         = getInputField(baseField,'zscoreZ',true);
decoderParams.demeanX                         = getInputField(baseField,'demeanX',false);
decoderParams.demeanZ                         = getInputField(baseField,'demeanZ',false);

decoderParams.preProcessForSignificance       = getInputField(baseField,'preProcessForSignificance',true);
decoderParams.preProcessThreshold             = getInputField(baseField,'preProcessThreshold',.1); % threshold on R2


% general fitting
decoderParams.modelSmoothVal                  = getInputField(baseField,'modelSmoothVal',0.75);
decoderParams.lags2Process                    = getInputField(baseField,'lags2Process',[0]);
decoderParams.trainINDXS                      = getInputField(baseField,'trainINDXS',[]);
decoderParams.velocityMatchingPercentiles     = getInputField(baseField,'velocityMatchingPercentiles',[.8 .95]);


% Population vector fitting
decoderParams.TuningFeatures                  = getInputField(baseField,'TuningFeatures','dx');


% crossvalidation options
if ~isfield(baseField,'cvOptions'),baseField.cvOptions=[];end
decoderParams.cvOptions.nFolds                = getInputField(baseField.cvOptions,'nFolds',10);
decoderParams.cvOptions.minTrainSize          = getInputField(baseField.cvOptions,'minTrainSize',2400); % 2500 allows filter to converge
decoderParams.cvOptions.minTestSize           = getInputField(baseField.cvOptions,'minTestSize',200);  % a reasonable amount to test

% arguements to the lasso function
decoderParams.lassoPlot          = getInputField(baseField ,'lassoPlot',false); %
if ~isfield(baseField,'lassoOptions'),baseField.lassoOptions=[];end

decoderParams.lassoOptions.Alpha                     = getInputField(baseField.lassoOptions ,'Alpha',.05); %
decoderParams.lassoOptions.CV                        = getInputField(baseField.lassoOptions ,'CV',8); %
decoderParams.lassoOptions.NumLambda                 = getInputField(baseField.lassoOptions ,'NumLambda',15); %
decoderParams.lassoOptions.optINDX                   = getInputField(baseField.lassoOptions ,'optINDX','IndexMinMSE'); % 'mid' 'IndexMinMSE' 'Index1SE'

% preSmoothingOptions (smoothing preformed prior to fit)
if ~isfield(baseField,'preSmoothOptions'),baseField.preSmoothOptions=[];end

decoderParams.PosFB=.05;

decoderParams.preSmoothOptions.smoothTrainingData            = getInputField(baseField.preSmoothOptions,'smoothTrainingData',true); % 
decoderParams.preSmoothOptions.SmoothType               = 'exp';
decoderParams.preSmoothOptions.causal               = 1;
switch decoderParams.preSmoothOptions.SmoothType
    case 'exp'
        if decoderParams.preSmoothOptions.causal  
            decoderParams.preSmoothOptions.params=[1.5 .75]; % also mj, 2pt, exp
        else
            decoderParams.preSmoothOptions.params=[.2 .2]; % also mj, 2pt, exp
        end
    case '2pt'
        decoderParams.preSmoothOptions.params=[1 .2]; % also mj, 2pt, exp
    case 'mj'
        decoderParams.preSmoothOptions.params=250;
end


decoderParams.modelSmoothOptions.SmoothType='exp'; % also mj, 2pt, exp
decoderParams.modelSmoothOptions.causal               = 1;
switch decoderParams.modelSmoothOptions.SmoothType
    case 'exp'
        decoderParams.modelSmoothOptions.params=[1.5 .75]; % also mj, 2pt, exp
    case '2pt'
        decoderParams.modelSmoothOptions.params=[1 .1]; % also mj, 2pt, exp
    case 'mj'
        decoderParams.modelSmoothOptions.params=750;
end

% kalman filter specific parameters (only assign if filterType==kalman)
% if strcmp(decoderParams.filterType,'kalman')
if ~isfield(baseField,'kalman'),baseField.kalman=[];end

decoderParams.kalman.A_type                = getInputField(baseField.kalman,'A_type','standard'); % autoRegressDamping , standard
decoderParams.kalman.W_type                = getInputField(baseField.kalman,'W_type','standard'); % standard , shenoy
decoderParams.kalman.W_weighting           = getInputField(baseField.kalman,'W_weighting',1); % 12
decoderParams.kalman.PK_type               = getInputField(baseField.kalman,'PK_type','standard'); % shenoy, standard
decoderParams.kalman.kalmanErrorWeight     = getInputField(baseField.kalman,'kalmanErrorWeight',.999);
decoderParams.kalman.errorTC               = getInputField(baseField.kalman,'errorTC',6);
decoderParams.kalman.robustWeight          = getInputField(baseField.kalman,'robustWeight',1);
decoderParams.kalman.kalmanType            = getInputField(baseField.kalman,'kalmanType','standard'); % 'standard'


% SpeedAdaptiveParams
decoderParams.SAF.smoothingParamsPercentile= [.2 1 -.05 .9]; %[minVal maxVal percentSpeedMin percentSpeedMin]
decoderParams.SAF.smoothingParamsPercentile= [0 1 0 .9]; %[minVal maxVal percentSpeedMin percentSpeedMin]
decoderParams.SAF.gainParamsPercentile = [0.5000 1.200 0 0.8]; %[minVal maxVal percentSpeedMin percentSpeedMin]
decoderParams.SAF.speedPercentile=95;
a=Kinematics.MakeExpFilter(.5,decoderParams.samplePeriod,.85);
a(1)=a(2); a=a/sum(a);
a=Kinematics.MinJerkKernel(850,50,1)';
decoderParams.SAF.detectionFilter=a;



decoderParams.movementDelay=0;
decoderParams.removeOutliers=0;


% for single unit control - allows scaling of force vector
% This should be set by the task
% decoderParams.SingUnitControl.targetDistance=TaskInformation.targetDistance;
% decoderParams.SingUnitControl.desiredDuration=1;

decoderParams.intentionOptions.useIntention=0;
decoderParams.intentionOptions.targetzone_thresh=TaskInformation.targetSize;
decoderParams.intentionOptions.targetAppearDelay=4;
decoderParams.intentionOptions.targetAppearDelay2=6;

obj.decoderParams=decoderParams;

%% runtimeParams
baseField=localParams.runtimeParams;

 % in seconds
runtimeParams.outputGain                        = getInputField(baseField,'outputGain',repmat(1,1,decoderParams.nDOF));
runtimeParams.outputMax                         = getInputField(baseField,'outputMax',repmat(1,1,decoderParams.nDOF));
runtimeParams.outputMin                         = getInputField(baseField,'outputMin',repmat(-1,1,decoderParams.nDOF));

% runtimeParams.outputMax                         = getInputField(baseField,'outputMax',repmat(12,1,decoderParams.nDOF));
% runtimeParams.outputMin                         = getInputField(baseField,'outputMin',repmat(-12,1,decoderParams.nDOF));

runtimeParams.assistLevel                       = getInputField(baseField,'assistLevel',0);
runtimeParams.assistType                        = getInputField(baseField,'assistType','WeightedAverage'); % (WeightedAverage,Projection,ErrorRail)
runtimeParams.adhoc_smooth                      = getInputField(baseField,'adhoc_smooth',[]);
runtimeParams.bufferCapacity                    = getInputField(baseField,'bufferCapacity',10000);
runtimeParams.plotCursor=1;
runtimeParams.showPopResponse=0;

runtimeParams.trialTimer=0;
runtimeParams.movementDelay=10;
runtimeParams.reactionTimeDelay=6;

runtimeParams.secondaryAssist.apply=0;
runtimeParams.secondaryAssist.assistIncrement=.02;
runtimeParams.secondaryAssist.assistValue=0; % gets to 
runtimeParams.secondaryAssist.waitPeriod=3/decoderParams.samplePeriod;

runtimeParams.adaptAssistanceLevel  =0; % whether to adapt assistance or not
runtimeParams.errorTC = 15; % time constant of error estimate
runtimeParams.assistStep = .01; % amount to adjust assistance level by on update
runtimeParams.targetError = 15 ;
runtimeParams.assistAdaptationType = 'angularError';
runtimeParams.angularError=0; % initialize error
% runtimeParams.angularError - averge angular error
% runtimeParams.RHM=ResidualHeatMap('heat','Y:\data\Spenser\SN1025-001022.cmp')
runtimeParams.plotResiduals=0;

runtimeParams.removeVelocityBias=0;

obj.runtimeParams=runtimeParams;

%% idealAgentParams
baseField=localParams.idealAgentParams;

idealAgentParams.make                               = getInputField(baseField,'make',true); % make predictions using ideal agent
idealAgentParams.type                               = getInputField(baseField,'type','mjOptAgentV2'); % (WeightedCombination,Projection)
idealAgentParams.dampingRadius                      = getInputField(baseField,'dampingRadius',TaskInformation.targetSize); % (WeightedCombination,Projection)
idealAgentParams.mvmntDuration                      = getInputField(baseField,'mvmntDuration',.5); % (WeightedCombination,Projection)

% idealAgentParams.make                               = getInputField(baseField,'make',true); % make predictions using ideal agent
% idealAgentParams.type                               = getInputField(baseField,'type','mjOptAgent'); % (WeightedCombination,Projection)
% % idealAgentParams.dampingRadius                      = getInputField(baseField,'dampingRadius',TaskInformation.targetSize); % (WeightedCombination,Projection)
% idealAgentParams.mvmntDuration                      = getInputField(baseField,'mvmntDuration',.8); % (WeightedCombination,Projection)

obj.idealAgentParams=idealAgentParams;


%% guiParams
baseField=localParams.guiParams;
guiParams.enableGUI                                 = getInputField(baseField,'enableGUI',true); % whether to enable the GUI
obj.guiParams=guiParams;