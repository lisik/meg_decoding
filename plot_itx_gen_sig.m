addpath('/mindhive/nklab3/users/lisik/Toolboxes/graphics_copy/')

%file_IDs = {'s06', 's07', 's08', 's09', 's10',  's12'};
file_IDs = {'s16', 's18','s19', 's22', 's23', 's24', 's25', 's26', 's27', 's28', 's29'}; %check s25 preproc

%file_IDs = {'s01', 's02', 's03', 's04', 's05', 's06', 's07' 's08', 's10'};

nFeat = 25;
bin_width = 25;
step_size = bin_width;

time = -225:step_size:1000-25-step_size;
null_runs = 20;
null = zeros(null_runs,12,length(time), length(file_IDs));
mean_decoding = zeros(12,length(time),length(file_IDs));

for s = 1:length(file_IDs)
if str2num(file_IDs{s}(end-1:end))>13
    nAvg =6;    
elseif str2num(file_IDs{s}(end-1:end))==6
    nAvg = 4;
else
    nAvg = 5;
end
    
results_folder = ['/mindhive/nklab3/users/lisik/socialInteraction_meg/decoding_results/' file_IDs{s}];

for t = 1:12
results_fileName=['interaction_invariant_' num2str(t)];

results_file = [results_folder '/' results_fileName '_avg', ...
        num2str(nAvg) '_top' num2str(nFeat) 'feat_' ,  ...
        num2str(bin_width), 'ms_bins_', num2str(step_size) ,'ms_sampled'];
load(results_file);
mean_decoding(t,:,s) = DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results;

% for n = 1:null_runs
%     load([results_folder '/null/' results_fileName '_avg', ...
%         num2str(nAvg) '_top' num2str(nFeat) 'feat_' ,  ...
%         num2str(bin_width), 'ms_bins_', num2str(step_size) ,'ms_sampled_null' num2str(n)]);
%     null(n,t,:,s) = DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results;
%     
% end

end
end
md = squeeze(mean(mean_decoding));

% tmp = squeeze(mean(null,2));
% tmp = sort(tmp);
% tmp2 = (tmp(end-1,:,:));
% soc_null = mean(squeeze(tmp2),2);
% 
% md2 = mean(md,2);
% tmp2 = squeeze(mean(tmp,3));
% for i = 1:length(tmp)
% p(i) = sum(md2(i) < tmp(:,i));
% end
% p = p/size(null,1);

time = -225:step_size:step_size*(size(md,1)-1)-225;

data = md'-0.5;
[SignificantTimes, clusters,clustersize,StatMapPermPV] = permutation_cluster_1sample(data, 1000, .05, .05);

%figure; shadedErrorBar(time, squeeze(mean(md,2)), ...
%    std(md')/sqrt(s));
figure; plot(time, squeeze(mean(md,2)), 'k', 'LineWidth', 2)
hold on; plot([0 0], [0.4 0.7], 'k'); 
%plot(time, soc_null)
plot([-225+round(bin_width/2) 1000-bin_width], [1/2, 1/2], 'k')
xlim([-200 1000])
ylim([0.45 0.6])
ylabel('Classification Accuracy')
xlabel('Time from stimulus onset (ms) ')
title('Social interaction')
set(gca, 'FontSize', 14)