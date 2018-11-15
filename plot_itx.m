clear all
addpath('/mindhive/nklab3/users/lisik/Toolboxes/graphics_copy/')
results_path = '/om/user/lisik/socialInteraction_meg/decoding_results/';
results_fileName = {'im_ID', 'interaction', 'gaze', 'watch_v_social', 'watch_v_non'};
subj = {'s16', 's18', 's19', 's22', 's23', 's24'};
subj = {'s33', 's33'};%19,22
%subj = {'s16', 's16'};
step_size = 10;
bin_width =step_size;
nFeat = 25;
nAvg = [6 24 24 24 24];

%nAvg = [4 13 13 10 10];
%nAvg = [6 16];


%mean_decoding = zeros(2, 120,length(subj));
for s = 1:length(subj)
if str2num(subj{s}(2:3))==6
    nAvg = [4 13 13 13 13];
elseif str2num(subj{s}(2:3)) < 14
    nAvg = [5 13 13 13 13];
else
    nAvg = [6 24 24 24 24 ];
end
for cond = 1:2
results_folder = [results_path subj{s}];
results_file = [results_folder '/' results_fileName{cond} '_avg', ...
        num2str(nAvg(cond)) '_top' num2str(nFeat) 'feat_' ,  ...
        num2str(bin_width), 'ms_bins_', num2str(step_size) ,'ms_sampled'];
load(results_file);
if size(DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results,2) > 1
mean_decoding(cond,:,s) = diag(DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results);
 else
mean_decoding(cond,:,s) = DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results;
end
end
end

t = -225:step_size:step_size*(size(mean_decoding,2)-1)-225;

figure; plot(t, squeeze(mean(mean_decoding(1,:,:),3)), 'k', 'LineWidth', 2)
% figure; shadedErrorBar(t, squeeze(mean(mean_decoding(1,:,:),3)), ...
%     std(squeeze(mean_decoding(1,:,:))')/sqrt(size(mean_decoding,1)));
hold on; plot([0 0], [0 0.2], 'k'); 
plot([-225+round(bin_width/2) 1000-bin_width], [1/60, 1/60], 'k')
xlim([-200 1000])
ylabel('Classification Accuracy')
xlabel('Time from stimulus onset (ms) ')
title('Image identity')
set(gca, 'FontSize', 14)

figure; plot(t, squeeze(mean(mean_decoding(2,:,:),3)), 'k', 'LineWidth', 2)
% figure; shadedErrorBar(t, squeeze(mean(mean_decoding(2,:,:),3)), ...
%     std(squeeze(mean_decoding(2,:,:))')/sqrt(size(mean_decoding,1)));
hold on; plot([0 0], [0.4 0.7], 'k'); 
plot([-225+round(bin_width) 990-bin_width], [1/2, 1/2], 'k')
xlim([-200 1000])
ylim([0.45 0.65])
ylabel('Classification Accuracy')
xlabel('Time from stimulus onset (ms) ')
title('Social interaction')
set(gca, 'FontSize', 14)

% figure; shadedErrorBar(t, squeeze(mean(mean_decoding(3,:,:),3)), ...
%     std(squeeze(mean_decoding(3,:,:))')/sqrt(size(mean_decoding,1)));
% hold on; plot([0 0], [0.4 0.7], 'k'); 
% plot([-225+round(bin_width/2) 1000-bin_width], [1/2, 1/2], 'k')
% xlim([-200 1000])
% ylim([0.4 0.7])
% ylabel('Classification Accuracy')
% xlabel('Time from stimulus onset (ms) ')
% title('Mutual gaze vs. joint attention')
% set(gca, 'FontSize', 14)
