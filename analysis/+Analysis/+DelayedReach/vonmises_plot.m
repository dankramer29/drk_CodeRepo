function [ vmrho, vmtheta, H ] = vonmises_plot( targetmean, task )
%UNTITLED6 Summary of this function goes here
%   right now target_mean_full is just one channel (i think)


nmes=lower(task.phaseNames);
% Von Mises fit
%data(:,1)=bin centers
%get the results of the histogram (fixed to current histogram), probably
%the data in data(:,2) and the values of the histogram (how many times it
%occurs) in 1.
H=histogram(target_mean_full,10); %=[data(:,2),data(:,1) 
[C Imax] = max(H.Values); %get the value and the row that it appears in for the bin
[C Imin] = min(H.Values);
%[C Imax] = max(data(:,2)); %get the value and the row that it appears in for the bin
%[C Imin] = min(data(:,2));
bin_centers=(H.BinEdges(2:end)+H.BinEdges(1:end-1))/2;
beta_in = [0.5; bin_centers(Imax); H.Values(Imax)-H.Values(Imin); H.Values(Imin)];
%beta_in = [0.5; data(Imax,1); data(Imax,2)-data(Imin,2); data(Imin,2)];

[beta_out,resid,j] = nlinfit(bin_centers, H.Values,'vonmises',beta_in);
%[beta_out,resid,j] = nlinfit(data(:,1),data(:,2),'vonmises',beta_in);
vmtheta=(0:pi/180:2*pi-pi/180)';
vmrho = vonmises(beta_out,vmtheta);

figure;
for ii=1:length(nmes) %roll through the phases
    %nmes = the phase names
rose(theta, targetmean.(nmes{ii})(:,ch(jj)),10);

end
%repeat for this down here
polar(vmtheta,vmrho,'r');
title('Propagation Direction','FontWeight','bold');
end

% [data(:,2),data(:,1)]=hist(prop_direction,10);
% [C Imax] = max(data(:,2));
% [C Imin] = min(data(:,2));
% beta_in = [0.5; data(Imax,1); data(Imax,2)-data(Imin,2); data(Imin,2)];
% [beta_out,resid,j] = nlinfit(data(:,1),data(:,2),'vonmises',beta_in);
% vmtheta=(0:pi/180:2*pi-pi/180)';
% vmrho = vonmises(beta_out,vmtheta);
% 
% figure(histogram_fig);
% rose(prop_direction,10);
% hold on;
% polar(vmtheta,vmrho,'r');
% title('Propagation Direction','FontWeight','bold');