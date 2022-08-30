function test(this,init)

str='CD_';

% initialize framework buffers
if nargin==2 && init==1
    
    this.msgName('Initialize Buffering to Framework');
    
    register(this.hFramework.buffers,[str 'assistLevel'],   'r');
    register(this.hFramework.buffers,[str 'assistType'],    'r');
    register(this.hFramework.buffers,[str 'gain'],          'r');
    register(this.hFramework.buffers,[str 'decINDX'],       'r');
    register(this.hFramework.buffers,[str 'secAssist'],     'r');
    
    return
end

add(this.hFramework.buffers,[str 'assistLevel'],this.getAssistLevel);
add(this.hFramework.buffers,[str 'assistType'],this.getAssistINDX);
% add(this.hFramework.buffers,[str 'gain'],this.getOutputGain);
% cIDX=this.currentDecoderINDX; if isempty(cIDX); cIDX=nan; end
% add(this.hFramework.buffers,[str 'decINDX'],cIDX(:)');
% add(this.hFramework.buffers,[str 'secAssist'],this.Params.secondaryAssist.assistValue(:)');
