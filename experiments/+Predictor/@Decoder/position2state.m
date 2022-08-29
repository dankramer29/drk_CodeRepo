function xOut=position2state(obj,x)


samplePeriod=obj.decoderParams.samplePeriod;
diffType=obj.decoderParams.diffType;

if ~any(strcmp(diffType,{'causal','traditional','intermediate'}))
    warning('Unsupported differentation type %s ; using "intermediate" instead',diffType);
    diffType = 'intermediate';
end


% calculate stuff.
%%


% save the indices of the different differential orders
nd=size(x,1);
pdX=x(:,1)*0; % xzero pad

switch lower(diffType)
    case 'causal'
        dx=[diff(x,1,2)/samplePeriod,pdX];
    case 'traditional'
        dx=[pdX,diff(x,1,2)/samplePeriod];
    case 'intermediate'
        dx=diff(x,1,2)/samplePeriod;
        dx_pad1=[pdX,dx];
        dx_pad2=[dx,pdX];
        dx=(dx_pad1+dx_pad2)/2;
    otherwise
        error('Unsupported diffType : Acceptable options are "causal" , "traditional", or "intermediate" ')
end

xOut(1:2:nd*2,:)=x;
xOut(2:2:nd*2,:)=dx;

