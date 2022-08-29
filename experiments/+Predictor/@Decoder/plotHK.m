function plotHK(obj, validChannels)

% ploit preferred directions and force direction.  if channels is
% specified, only plot for those channels.
% 
% [n_str,FL]=obj.getFeatureNames;  
% K=obj.K;
% H=obj.H;
% 
% if length(K(1,:))~=length(n_str)
%     if ~isempty(n_str)
%         warning('dimensionality of features and K are not compatible, using indices to label Features ')
%         
%     end
%     
%     % if feature list was not provided and thus we do not know channel ids,
%     % just use indexes
%     for i=1:size(K,2);
%         n_str{i}=['i',num2str(i) ];
%         channel=i;
%     end
% else
%     channel=[FL.channel];  
% end
% 
% if nargin>1
% % use only validChannels
% inds2use=ismember(channel,validChannels);
% 
% H=H(inds2use,:);
% K=K(:,inds2use);
% n_str=n_str(inds2use);
% end
% 
% n_features=size(K,2);
% % Featureids=STREAMDATA.USER.FeatureList.ContinuousFeatures(:,1);

decodeFeatures=obj.decoders(obj.currentDecoderINDX).decoderProps.decodeFeatures;
decodeFeaturesINDX=find(decodeFeatures);
Bcf=obj.decoders(obj.currentDecoderINDX).decoderProps.Bcf(:,1:end-1);
n_features=size(Bcf,2);
x1=[zeros(n_features,1) Bcf(1,:)']';
x2=[zeros(n_features,1) Bcf(2,:)']';

indx=1;
for i=decodeFeaturesINDX(:)'
    n_str{indx}=num2str(i);
    indx=indx+1;
end


h=figure;
set(h,'name',obj.decoders(obj.currentDecoderINDX).name)
clf
subplot(1,2,1)
plot(x1,x2)
text(x1(2,:),x2(2,:),n_str,'FontSize',8)
title('Force Vectors')
m=max(abs([x1(:);x2(:) ]));
axis square
ylim([-m m])
xlim([-m m])



H=obj.decoders(obj.currentDecoderINDX).PopVec.H(decodeFeatures,1:end-1)';
n_features=size(H,2);
x1=[zeros(n_features,1) H(1,:)']';
x2=[zeros(n_features,1) H(2,:)']';




subplot(1,2,2)
plot(x1,x2)

% indx=1;
% for i=decodeFeaturesINDX
%     n_str{indx}=num2str(i);
%     indx=indx+1;
% end
text(x1(2,:),x2(2,:),n_str,'FontSize',8)

title('Preferred Directions')
m=max(abs([x1(:);x2(:) ]));
axis square
ylim([-m m])
xlim([-m m])





% text(K(1,:),K(2,:),n_str)
% tmp=max(max(abs(obj.K(1:2,:))));
% tmp=max([tmp .05]);
% xlim([-tmp tmp]);ylim([-tmp tmp])

% subplot(2,2,2)
% plot(x3,x4)
% title('Velocity FD')
% axis equal; axis square;
% text(K(3,:),K(4,:),n_str)
% tmp=max(max(abs(obj.K(3:4,:))));
% tmp=max([tmp .05]);
% xlim([-tmp tmp]);ylim([-tmp tmp])

% 
% x1=[zeros(n_features,1) H(:,1)]';
% x2=[zeros(n_features,1) H(:,2)]';
% 
% x3=[zeros(n_features,1) H(:,3)]';
% x4=[zeros(n_features,1) H(:,4)]';
% 
% 
% subplot(2,2,3)
% plot(x1,x2)
% title('Position PD')
% axis equal; axis square;
% text(H(:,1),H(:,2),n_str)
% tmp=max(max(abs(obj.H(:,1:2))));
% tmp=max([tmp .05]);
% xlim([-tmp tmp]);ylim([-tmp tmp])
% 
% subplot(2,2,4)
% plot(x3,x4)
% title('Velocity PD')
% axis equal; axis square;
% text(H(:,3),H(:,4),n_str)
% tmp=max(max(abs(obj.H(:,3:4))));
% tmp=max([tmp .05]);
% xlim([-tmp tmp]);ylim([-tmp tmp])
