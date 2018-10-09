cdclear all
addpath('/mindhive/nklab3/users/lisik/Toolboxes/graphics_copy/')
addpath('Functions_stat/')
file_IDs = {'s16', 's18', 's19', 's22'};
%file_IDs = {'s14'};
%file_IDs = {'s19'};
%file_IDs = {'s06', 's10'};

nFeat = 25;
bin_width = 10;
step_size = bin_width;

for s = 1:length(file_IDs)
if str2num(file_IDs{s}(end-1:end))<6 || str2num(file_IDs{s}(end-1:end))> 13
    nAvg =6;    
elseif str2num(file_IDs{s}(end-1:end))==6
    nAvg = 4;
else
    nAvg = 5;
end
nAvg = nAvg*5;
results_folder = ['/om/user/lisik/socialInteraction_meg/decoding_results/' file_IDs{s}];

for t = 1:11
results_fileName=['interaction_invariant_' num2str(t)];

results_file = [results_folder '/' results_fileName '_ag_avg', ...
        num2str(nAvg) '_top' num2str(nFeat) 'feat_' ,  ...
        num2str(bin_width), 'ms_bins_', num2str(step_size) ,'ms_sampled'];
load(results_file);
mean_decoding(t,s,:) = DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results;
mean_decoding(t,s,:)=filter(1/3*ones(1,3), 1, DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results);

end
end

md = reshape(mean_decoding, [size(mean_decoding,1)* size(mean_decoding,2), size(mean_decoding,3)]);


% figure; plot(md)
% figure; plot(mean(md,2))


time = -225:step_size:step_size*(size(md,2)-1)-225;

data = md-0.5;
[SignificantTimes, clusters,clustersize,StatMapPermPV] = permutation_cluster_1sample(data, 1000, .05, .05);

%figure; shadedErrorBar(time, squeeze(mean(md,2)), ...
%    std(md')/sqrt(s));
figure; plot(time, mean(md), 'k', 'LineWidth', 2)
hold on; plot([0 0], [0.4 0.7], 'k'); 
plot([-225+round(bin_width/2) 1000-bin_width], [1/2, 1/2], 'k')
xlim([-200 1000])
ylim([0.46 0.57])
ylabel('Classification Accuracy')
xlabel('Time from stimulus onset (ms) ')
title('Social interaction')
set(gca, 'FontSize', 14)

for i = 1:length(SignificantTimes)
    plot([time(SignificantTimes(i))-round(bin_width/2) time(SignificantTimes(i))+round(bin_width/2)], ...
        [0.47 0.47], 'k', 'LineWidth', 2)
end