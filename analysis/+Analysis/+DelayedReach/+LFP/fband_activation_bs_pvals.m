function [pvals, signific] = fband_activation_bs_pvals(dataset1, dataset2)
%{ 
concat em
repeat 10k times:
    randperm trial dimension
    take first half as group 1
    take second half as group 2
    get activations
    
plot hist of activations to check?
sort activations chx10k
get actualactivations
for each actualactivation check the sign, 
    if negative, find first activation its bigger than and divide that index number/10,000
    if positive find first activation thats bigger than it and divide (10k - that index number)/10,000
%}
num_perms = 10000;
group_ds = [dataset1 dataset2];
first_dim = size(group_ds, 1);
num_tri = size(group_ds, 2);
num_ds1 = size(dataset1, 2);
num_ds2 = size(dataset2, 2);
new_activations = zeros(first_dim, num_perms);
pvals = zeros(first_dim, 1);
signific = zeros(first_dim, 1);
for i = 1:num_perms
    perm_ds = group_ds(:,randperm(num_tri));
    new_ds1 = perm_ds(:, 1:num_ds1);
    new_ds2 = perm_ds(:,num_ds1+1:end);
    assert(size(new_ds2, 2) == num_ds2, 'new groups dont match size of original groups')
    new_activations(:,i) = Analysis.DelayedReach.LFP.fband_activation(new_ds1, new_ds2);
end
sort_activations = sort(new_activations, 2);
actual_activations = Analysis.DelayedReach.LFP.fband_activation(dataset1, dataset2);

for c = 1:first_dim
    if actual_activations(c) < 0 %sign negative
        [found, indx] = find(sort_activations(c,:) < actual_activations(c), 1, 'last');
        if isempty(found)
            indx = 1;
        end
    elseif actual_activations(c) > 0 %sign positive
        [found, indx] = find(sort_activations(c,:) > actual_activations(c), 1, 'first');
        if isempty(found)
            indx = num_perms - 1;
        end
        indx = num_perms - indx;
    end
    pvals(c) = indx / num_perms;
    signific(c) = pvals(c) < 0.05;
end