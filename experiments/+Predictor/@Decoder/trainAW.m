function [A,W]=trainAW(obj,x,trainINDXS)

% A=bmi_trainA(INPUT) returns an the system dynamics given options INPUT
% example : A=bmi_trainA(x,struct('damping',.4,'A_type','particle))
% x should have dimensions [nstates,ntime_points]
%
% Note that in this function I regress out offsets and thus the input data
% does not need to be zero mean, however, in the framework we should have
% zero mean position data.  While in theory this does not need to be the
% case as we could incorporate it into the matrix algebra, it would be
% awkward to do things like specify "ideal" A's such as the damped
% particle.  So use zero mean position data.


% options
% INPUT.A_type = {'standard', 'robust', 'particle', 'dampedParticle'}
% INPUT.x = kinematic data used to fit A (note : not all A types require fitting)
% INPUT.trainINDXS = optionally specify subset of x to use for training
% INPUT.samplePeriod = specify timesampling for a priori system types (e.g. 'particle')
% INPUT.damping = specify damping for a priori system types (e.g. 'dampedParticle')

%% parse input struct
% note : isfield_hasval(STRUCT,FIELDNAME,DEFAULTVALUE)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
options=obj.decoderParams.kalman;
[options.A,default_A]=Utilities.getInputField(options,'A',[]);
[options.W,default_W]=Utilities.getInputField(options,'W',[]);

if ~default_A
    A=options.A;
    warning(' ''A'' was provided in the options struct : passing options.A as output, hope this is what you wanted.')
    options.A_type='pass';
end

if ~default_W
    W=options.W;
    warning(' ''A'' was provided in the options struct : passing options.A as output, hope this is what you wanted.')
    options.W_type='pass';
end

if ~default_A & ~default_A
    return
end

options.W_weighting = Utilities.getInputField(options,'AW_W_weighting',1);
if length(trainINDXS)>=size(x,2);trainINDXS=trainINDXS(1:size(x,2)-1); end

% if any(isnan(x(:)))
%     nan_inds=isnan(sum(x(:,trainINDXS),1));
%     x=x(:,~nan_inds);
%     warning('NaN values found at %d timepoints in x.  Removing these values.', sum(nan_inds))
% end


%% Check inputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if any(strcmp(options.A_type, {'particle','dampedParticle'})) & default_deltaT
    warning('samplePeriod not specified - assuming samplePeriod = .1')
end

if strcmp(options.A_type, {'dampedParticle'}) & default_damping
    warning(sprintf('damping for A_type ''dampedParticle'' not specified, using a default value %0.2f',damping))
end

if any(strcmp(options.A_type, {'robust','standard','shenoy'})) & isempty(x)
    error('The chosen A_type requires that you specify kinematics (''x'') to fit A.  Please specify x or choose an A_type that does not require x (e.g. ''particle'')')
end

%% Calculate A
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
M=length(trainINDXS);

switch options.A_type
    
    case 'robust'
        for i=1:size(x,1)
            mdl = LinearModel.fit(x(:,trainINDXS)',x(i,trainINDXS+1)','Robust','on');
            b(i,:)=mdl.Coefficients.Estimate';
            %             [b(i,:)] = regress(x(i,trainINDXS+1)', x2fx(x(:,trainINDXS)'));
        end
        A=b(:,2:end);
        
        
    case 'standard'
        for i=1:size(x,1)
            mdl = LinearModel.fit(x(:,trainINDXS)',x(i,trainINDXS+1)');
            b(i,:)=mdl.Coefficients.Estimate';
            %             [b(i,:)] = regress(x(i,trainINDXS+1)', x2fx(x(:,trainINDXS)'));
        end
        
        A=b(:,2:end);
        
        
    case 'perfectIntegrator'
        % use autoregression model to compute damping.
        indx=1;
        for i=2:2:size(x,1)
            [b] = regress(x(i,trainINDXS+1)', x2fx(x(:,trainINDXS)'));
            %            A{indx}=[1 obj.samplePeriod; 0 b(i+1)];
            %            A{indx}=[1 obj.samplePeriod; b(i:i+1)'];
            A{indx}=[1 obj.decoderParams.samplePeriod; b(i) b(i+1)];
            indx=indx+1;
        end
        A=Utilities.blkdiagCell(A);
        
    case 'perfectIntegratorIdeal'
        samplePeriod=obj.decoderParams.samplePeriod;
        nDOF=obj.decoderParams.nDOF;
        A=Utilities.blkdiagCell(repmat({[1 samplePeriod; -.1 .95]},1,nDOF));
        
    case 'shenoy'
        % sheony method
        
        for i=2:2:size(x,1)
            mdl = LinearModel.fit(x(:,trainINDXS)',x(i,trainINDXS+1)');
            foo=mdl.Coefficients.Estimate'; foo(2:2:end)=0;
            b(i,:)=foo(2:end)
        end
        samplePeriod=obj.decoderParams.samplePeriod;
        nDOF=obj.decoderParams.nDOF;
        A=b+Utilities.blkdiagCell(repmat({[1 samplePeriod; 0 0]},1,nDOF));
        
        
    case 'shenoy2'
        % same as shenoy, but includes positional feedback to avoid
        % unstable system.
        for i=2:2:size(x,1)
            mdl = LinearModel.fit(x(:,trainINDXS)',x(i,trainINDXS+1)');
            foo=mdl.Coefficients.Estimate'; foo(2:2:end)=-.1;
            b(i,:)=foo(2:end)
        end
        samplePeriod=obj.decoderParams.samplePeriod;
        nDOF=obj.decoderParams.nDOF;
        A=b+Utilities.blkdiagCell(repmat({[1 samplePeriod; 0 0]},1,nDOF));
        

        
    case 'particle'
        A=[1 obj.samplePeriod; 0 1];
        A=Utilities.blkdiagCell(repmat({A},1,obj.nDOF));
        
        
    case 'dampedParticle'
        A=[1 obj.samplePeriod; 0 obj.options.AW_damping ];
        A=Utilities.blkdiagCell(repmat({A},1,obj.nDOF));
    case 'pass'
        
    otherwise
        error(['unknown A_type : ' , options.AW_A_type, '.  Choose something else.' ])
        
end



M=length(trainINDXS);

switch options.W_type
    
    case 'standard'
        
        %         The Wu form of calculating W is applicable only for least squares estimation of A
        %         W1=x(:,trainINDXS+1)*x(:,trainINDXS+1)';
        %         W2=x(:,trainINDXS)*x(:,trainINDXS+1)';
        %         W=(1/(M-1))*(W1-A*W2);
        
        %        more generally, for arbitary A,
        residuals=x(:,trainINDXS+1)-A*x(:,trainINDXS);
        W=(1/(M-1))*(residuals)*(residuals)';
        
    case 'shenoy'
        residuals=x(:,trainINDXS+1)-A*x(:,trainINDXS);
        Wp=(1/(M-1))*(residuals)*(residuals)';
        W=zeros(size(x,1));
        
        VelocityInds=2:2:obj.decoderParams.nDOF*2;
        [tmpA,tmpB]=ndgrid(VelocityInds,VelocityInds);
        PositionFeedbackINDXS=[tmpA(:),tmpB(:)];
        
        %         PositionFeedbackINDXS=[2:2:obj.decoderParams.nDOF*2 ; 2:2:obj.decoderParams.nDOF*2];
        
        for i=1:size(PositionFeedbackINDXS,1)
            INDX=PositionFeedbackINDXS(i,:);
            W(INDX(1),INDX(2))=Wp(INDX(1),INDX(2));
        end
        
         case 'velOnly'
        residuals=x(:,trainINDXS+1)-A*x(:,trainINDXS);
        Wp=(1/(M-1))*(residuals)*(residuals)';
        W=zeros(size(x,1));
        
        PositionFeedbackINDXS=[2:2:obj.decoderParams.nDOF*2 ; 2:2:obj.decoderParams.nDOF*2]';
        
        for i=1:size(PositionFeedbackINDXS,1)
            INDX=PositionFeedbackINDXS(i,:);
            W(INDX(1),INDX(2))=Wp(INDX(1),INDX(2));
        end
           
    case 'pass'
        
end




