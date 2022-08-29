function imagesc_xlabel( ax, t, pre, varargin )
%imagesc_xlabel label the x axis of an imagesc ax
%   The imagesc outputs, after changing to axis xy;, has the labels off if
%   your graph starts before time 0 of some event, this corrects that
% % Input:
%         ax= output of imagesc in the form of: ax=gca;
% 
%         t=  t of the second output from
%         [S,t,f,Serr]=mtspecgramc(data,movingwin,params). Since the time
%         output doesn't start at the beginning or end at the end depending
%         on params.win and pads
% 
%         pre= how much time before the 0 event does the data go (from the
%         original data, not the beginning of t from mtspecgramc
%         
%         varargin
%         step= how much you want the labels to step by

%TO DO: the rounding goes to the first dec place to avoid having the labels
%be 4 dec long, possibly want to adjust that based on step, but should be
%ok

[varargin,step] = util.argkeyval('step',varargin,0.1);



ax.XTick=(round(t(1),1):step:round(t(end),1));
ax.XTickLabel=(round(t(1),1)-pre(1):step:round(t(end),1)-pre(1));

end

