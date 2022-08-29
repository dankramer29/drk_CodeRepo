function bodePlot(obj, options)

if nargin==1; options=[]; end

options.plotPhase=getInputField(options,'plotPhase', true);
options.seperatePlots=getInputField(options,'seperatePlots', false);

% check to see if the Linear Control Form representation exists, it it
% does, plot it.

if isprop(obj, 'LCF') && isfield(obj.LCF, 'Sys')
    sys=obj.LCF.Sys;
    
    if options.seperatePlots
        figure
        h = bodeplot(sys);
        setoptions(h,'FreqUnits','Hz','PhaseVisible','off');
        figure
        h = bodeplot(sys);
        setoptions(h,'FreqUnits','Hz','MagVisible','off');
    else
        figure
        h = bodeplot(sys);
        if ~options.plotPhase
            setoptions(h,'FreqUnits','Hz','PhaseVisible','off');
        else
            setoptions(h,'FreqUnits','Hz');
        end
    end
end