function plotForceVector(obj, validChannels)

% plots the force vector in 1,2, or 3d


% ploit preferred directions and force direction.  if channels is
% specified, only plot for those channels.

[n_str,FL]=obj.getFeatureNames;

Bc=obj.decoderProps.Bc;


if length(Bc(1,:))~=length(n_str)
    if ~isempty(n_str)
        warning('dimensionality of features and Bc are not compatible, using indices to label Features ')
    end
    
    % if feature list was not provided and thus we do not know channel ids,
    % just use indexes
    for i=1:size(Bc,2);
        n_str{i}=['i',num2str(i) ];
        channel=i;
    end
else
    channel=[FL.channel];
end

if nargin>1
    % use only validChannels
    inds2use=ismember(channel,validChannels);
    
    H=H(inds2use,:);
    Bc=Bc(:,inds2use);
    n_str=n_str(inds2use);
end

n_features=size(Bc,2);

if obj.decoderParams.nDOF==1
    
    x1=[zeros(n_features,1) Bc(2,:)']';
    bar(x1)
    text( n_str)
elseif obj.decoderParams.nDOF==2
    x1=[zeros(n_features,1) Bc(2,:)']';
    x2=[zeros(n_features,1) Bc(4,:)']';
    plot(x1,x2)
    axis tight; axis equal
    text(Bc(2,:),Bc(4,:),n_str)
    
elseif obj.decoderParams.nDOF==3
    x1=[zeros(n_features,1) Bc(2,:)']';
    x2=[zeros(n_features,1) Bc(4,:)']';
    x3=[zeros(n_features,1) Bc(6,:)']';
    plot3(x1,x2,x3)
    text(Bc(2,:),Bc(4,:),Bc(6,:),n_str)
end

title('Velocity FD')

axis equal; axis equal; axis square;

% tmp=max(max(abs(obj.Bc(3:4,:))));
% tmp=max([tmp .05]);
% xlim([-tmp tmp]);ylim([-tmp tmp])
