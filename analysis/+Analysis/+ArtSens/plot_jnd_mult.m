function  plot_jnd_mult(fitresults, statsT, varargin)
%plot_jnd_mult easy way to plot multiple best fit curves together into one
%subplot
%   ArtSens.plot_jnd_mult(fitresults, statsT, 'fitresults2',
%   fitresultsEG, 'statsT2',  statsTEG);


[varargin,fitresults2] = util.argkeyval('fitresults2',varargin,[]);
[varargin,fitresults3] = util.argkeyval('fitresults3',varargin,[]);
[varargin,fitresults4] = util.argkeyval('fitresults4',varargin,[]);
[varargin,statsT2] = util.argkeyval('statsT2',varargin,[]);
[varargin,statsT3] = util.argkeyval('statsT3',varargin,[]);
[varargin,statsT4] = util.argkeyval('statsT4',varargin,[]);

if nargin==12

    fr_tot{1}=fitresults{1};
    fr_tot{2}=fitresults2{1};
    fr_tot{3}=fitresults3{1};
    fr_tot{4}=fitresults4{1};
    st_tot.Category(:,1)=statsT.Category; st_tot.Percent_correct(:,1)=statsT.Percent_correct;
    st_tot.Category(:,2)=statsT2.Category; st_tot.Percent_correct(:,2)=statsT2.Percent_correct;
    st_tot.Category(:,3)=statsT3.Category; st_tot.Percent_correct(:,3)=statsT3.Percent_correct;
    st_tot.Category(:,4)=statsT4.Category; st_tot.Percent_correct(:,4)=statsT4.Percent_correct;
elseif nargin==9
  
    fr_tot{1}=fitresults{1};
    fr_tot{2}=fitresults2{1};
    fr_tot{3}=fitresults3{1};
    st_tot.Category(:,1)=statsT.Category; st_tot.Percent_correct(:,1)=statsT.Percent_correct;
    st_tot.Category(:,2)=statsT2.Category; st_tot.Percent_correct(:,2)=statsT2.Percent_correct;
    st_tot.Category(:,3)=statsT3.Category; st_tot.Percent_correct(:,3)=statsT3.Percent_correct;
elseif nargin==6
   
    fr_tot{1}=fitresults{1};
    fr_tot{2}=fitresults2{1};
    st_tot.Category(:,1)=statsT.Category; st_tot.Percent_correct(:,1)=statsT.Percent_correct;
    st_tot.Category(:,2)=statsT2.Category; st_tot.Percent_correct(:,2)=statsT2.Percent_correct;
elseif nargin==2
        
    fr_tot{1}=fitresults{1};   
    st_tot.Category(:,1)=statsT.Category; st_tot.Percent_correct(:,1)=statsT.Percent_correct;   
else
    error('must include the fitresults and statsT of any added subjects')
end


figure
for ii=1:length(fr_tot)
    subplot(length(fr_tot),1,ii)
    plot(fr_tot{ii}, st_tot.Category(:,ii), st_tot.Percent_correct(:,ii), 'o')
    title(['Subject S0', num2str(ii)]);
    if ii==round(length(fr_tot)/2)
        ylabel('Correct Responses (%)')
        xlabel(' ')
    end
    if ii==length(fr_tot)
        xlabel('Difference in first and second frequencies (Hz)')
        ylabel(' ')
    end
    
end

end

