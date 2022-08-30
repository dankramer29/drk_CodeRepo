function stats = testSpecGroups(spec,ecog,params,varargin)
%{
    STATS = TESTSPECGROUPS(SPEC,ECOG,PARAMS,VARARGIN)

    First run of statistical test to compare frequency spectrum groups, it
    can take spectrogram data (3D matrix) or power density spectrums (2D
    matrix). Can take normalized/standarized data, or absolute power
    values.

    1) TESTSPECGROUPS(SPEC,ECOG):

    2) TESTSPECGROUPS(SPEC,ECOG,PARAMS):

    3) STATS = TESTSPECTGROUPS(...):

TODO: Finish documentation, and include case for frequency spectrum groups

%}
% input error check
narginchk(2,5);

if nargin == 2 || ismpety(params)
    params = Parameters.Dynamic(@Parameters.Config.BasicAnalysis);
end

% Initialize output variable
stats = struct; 

names = fieldnames(spec);
if any(strcmpi(names,'power'))
    chans = length(spec(1).power);
    spectype = true;
else
    chans = length(names);
    spectype = false;
end


for kk = 1:chans % will compare the channels across conditions
    s = []; gp = {}; hnull = []; ptst = [];
    for ff = 1:length(spec)     % loop through the events (stim type)
        if spectype % we have time x freq x trials (spectrogram case)
            s = [s squeeze(nanmean(spec(ff).power{kk},1))];
            gp = [gp;cellstr(repmat(ecog.evtNames{ff}(1:5),size(spec(ff).power{kk},3),1))];
            if strcmpi(spec(ff).norm,'true') || spec(ff).norm % will test for deviation from zero
                [h,p] = ttest(squeeze(nanmean(spec(ff).power{kk},1))',[],'alpha',params.st.alpha);
                hnull = [hnull;h];
                ptst = [ptst;p];
            end % case of power density spectrum
        else % spectrum density case
            s = [s spec(ff).(names{kk})];
            gp = [gp;cellstr(ecog.evtNames{ff}(1:5))];
        end
    end
    if ~isempty(hnull); stats(kk).tst = {hnull,ptst}; end
    [p,tbl,st] = anova1(s,gp,'off');
    stats(kk).anovast = [p,tbl{2,5}];
    stats(kk).anovameans = st.means;
    stats(kk).anovadf = [tbl{2,2},tbl{3,2}];
    figure(kk); multcompare(st); 
    if ecog.bipolar
        title(['Chan. ',num2str(ecog.elecPairs(kk,1)),'-',num2str(ecog.elecPairs(kk,2))]);
    else
        title(['Channel ',num2str(ecog.readChan(kk))]);
    end
end

end % END of testSpecgram function