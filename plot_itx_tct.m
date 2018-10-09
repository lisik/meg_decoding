clear all
addpath('/mindhive/nklab3/users/lisik/Toolboxes/graphics_copy/')
addpath('/mindhive/nklab3/users/lisik/Toolboxes/Functions_stat/')
results_path = '/om/user/lisik/socialInteraction_meg/decoding_results/';
results_fileName = {'im_ID', 'interaction', 'gaze', 'watch_v_social', 'watch_v_non'};
subj = {'s06', 's07', 's08', 's09', 's10',  's12', 's13',...
    's16', 's18', 's19', 's22'}; %bad subj 4,9, 11*,12
%subj = {'s06', 's07', 's08', 's09', 's10',  's12', 's13'}; %bad subj 4,9, 11*,12
%subj = {'s11', 's11'};
%subj = {'s06', 's07', 's08', 's09', 's10', 's13'};
%subj = {'s01', 's02', 's03', 's04', 's05'};
subj = {'s16', 's18','s19', 's22', 's23', 's24', 's25', 's26', 's27', 's28', 's29'}; %check s25 preproc

%subj = {'s09', 's10'};
%subj = {'s09', 's09'};
step_size = 10;
bin_width =10;
nFeat = 25;
%nAvg = [4 13 13 10 10];
%nAvg = [6 16];


%mean_decoding = zeros(2, 120,length(subj));
for s = 1:length(subj)
if str2num(subj{s}(end-1:end))<6 
    nAvg = [6 16 16 16 16];    
elseif str2num(subj{s}(end-1:end))==6
    nAvg = [4 13 13 13 13];
elseif str2num(subj{s}(end-1:end))> 13
    nAvg = [6 24 24 24 24];
else
    nAvg = [5 13 13 13 13];
end

for cond = 1:2
results_folder = [results_path subj{s}];
results_file = [results_folder '/' results_fileName{cond} '_avg', ...
        num2str(nAvg(cond)) '_top' num2str(nFeat) 'feat_' ,  ...
        num2str(bin_width), 'ms_bins_', num2str(step_size) ,'ms_sampled'];
load(results_file);
mean_decoding(cond,s,:,:) = DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results;
end
end

t = -225+round(bin_width):step_size:990-bin_width;
t = -225:step_size:step_size*(size(mean_decoding,2)-1)-225;

figure; imagesc(squeeze(mean(mean_decoding(1,:,:,:),2)))
data = squeeze(mean_decoding(1,:,:,:))-1/52;

[SignificantTimes1, clusters,clustersize,StatMapPermPV] = permutation_cluster_1sample_2dim(data, 1000, 0.05, 0.05);

% figure; shadedErrorBar(t, squeeze(mean(mean_decoding(1,:,:),3)), ...
%     std(squeeze(mean_decoding(1,:,:))')/sqrt(size(mean_decoding,1)));
% hold on; plot([0 0], [0 0.2], 'k'); 
% %plot([-225+round(bin_width/2) 1000-bin_width], [1/52, 1/52], 'k')
% plot([-225+round(bin_width/2) 1000-bin_width], [0.026 0.026], 'k')
% xlim([-200 1000])
% ylabel('Classification Accuracy')
% xlabel('Time from stimulus onset (ms) ')
% title('Image identity')
% set(gca, 'FontSize', 14)

figure; imagesc(squeeze(mean(mean_decoding(2,:,:,:),2)))
data = squeeze(mean_decoding(2,:,:,:))-0.5;

[SignificantTimes, clusters,clustersize,StatMapPermPV] = permutation_cluster_1sample_2dim(data, 1000, 0.05, 0.05);
%figure; imagesc(squeeze(mean(mean_decoding(2,:,:,:),2)).*SignificantTimes)