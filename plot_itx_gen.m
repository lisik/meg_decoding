clear all
addpath('/mindhive/nklab3/users/lisik/Toolboxes/graphics_copy/')
addpath('/mindhive/nklab3/users/lisik/Toolboxes/Functions_stat/')
file_IDs = {'s16','s19', 's22', 's23', 's24', 's26', 's27', ...
    's28',  's30', 's32'};
%file_IDs = {'s33'};
%file_IDs = {'s32'};
%file_IDs = {'s06', 's10'};

nFeat = 25;
bin_width = 10;
step_size = 10;

for s = 1:length(file_IDs)
if str2num(file_IDs{s}(end-1:end))<6 || str2num(file_IDs{s}(end-1:end))> 13
    nAvg =6;    
elseif str2num(file_IDs{s}(end-1:end))==6
    nAvg = 4;
else
    nAvg = 5;
end
nAvg = nAvg*5;
%nAvg = 120;
results_folder = ['/om/user/lisik/socialInteraction_meg/decoding_results/' file_IDs{s}];

for t = 1:24 % bad inds: 3:6, 8
results_fileName=['interaction_invariant_' num2str(t)]; 
% results_fileName=['watch_v_social_invariant_' num2str(t)]; 
% results_fileName=['watch_v_non_invariant_' num2str(t)]; 

%
%results_fileName=['gaze_invariant_' num2str(t)];
%results_fileName=['genderMF_bal_invariant_' num2str(t)]; 


results_file = [results_folder '/' results_fileName '_r_avg', ...
        num2str(nAvg) '_top' num2str(nFeat) 'feat_' ,  ...%num2str(nAvg) '_05pv_feat_' ,  ...
        num2str(bin_width), 'ms_bins_', num2str(step_size) ,'ms_sampled'];
load(results_file);
mean_decoding(t,s,:) = DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results;
%mean_decoding(t,s,:)=filter(1/2*ones(1,2), 1, DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results);

end
end

md = reshape(mean_decoding, [size(mean_decoding,1)* size(mean_decoding,2), size(mean_decoding,3)]);
md = squeeze(mean(mean_decoding));
%md = squeeze(mean_decoding(2,:,:));

% figure; plot(md)
% figure; plot(mean(md,2))


time = -225:step_size:step_size*(size(md,2)-1)-225;

data = md-0.5;
[SignificantTimes, clusters,clustersize,StatMapPermPV] = permutation_cluster_1sample(data, 1000, .05, .05);

SEM = std(md)/sqrt(s);
ts = tinv([0.05 0.95], size(md,1)-1);
CI = mean(md) + ts'*SEM;
figure; shadedErrorBar(time, mean(md), SEM);
%figure; plot(time, mean(md), 'k', 'LineWidth', 2)
hold on; plot([0 0], [0.3 0.7], 'k'); 
plot([-225+round(bin_width/2) 1000-bin_width], [1/2, 1/2], 'k')
xlim([-200 1000])
ylim([.45 0.65])
ylabel('Classification Accuracy')
xlabel('Time from stimulus onset (ms) ')
title('Social interaction (generalization)')
set(gca, 'FontSize', 14)

for i = 1:length(SignificantTimes)
    plot([time(SignificantTimes(i))-round(bin_width/2) time(SignificantTimes(i))+round(bin_width/2)], ...
        [0.46 0.46], 'k', 'LineWidth', 2)
end