%this is a dumb script so i can show figures and just cycle through them

%just write iii = whatever number you want and then put write showfig
%you may need to be in the parent folder, if so, add this to the current
%folder so save as a version into Analysis.
figs = findall(0, 'Type', 'figure');
for jj = 1:length(figs)
    figNumber(jj) = figs(jj).Number;
end
locF = find(figNumber == iii);

figure(figs(locF))