clear all
addpath('/mindhive/nklab3/users/lisik/Toolboxes/graphics_copy/')
addpath('/mindhive/nklab3/users/lisik/Toolboxes/Functions_stat/')
file_IDs = {'s16','s18', 's19', 's22', 's23', 's24', 's25', 's26', 's27', ...
    's28', 's29', 's30', 's31', 's32', 's33', 's34'};
%file_IDs = {'s33'};
%file_IDs = {'s32'};
%file_IDs = {'s06', 's10'};

nFeat = 25;
bin_width = 10;
step_size = bin_width;

for s = 1:length(file_IDs)

nAvg = 24;
%nAvg = 24;
results_folder = ['/om/user/lisik/socialInteraction_meg/decoding_results/' file_IDs{s}];
results_fileName=['interaction']; 

%% load gen files
for t = 1:24 % bad inds: 3:6, 8

results_file = [results_folder '/' results_fileName '_invariant_' ...
    num2str(t) '_r_avg', ...
        '120_top' num2str(nFeat) 'feat_' ,  ...%num2str(nAvg) '_05pv_feat_' ,  ...
        num2str(bin_width), 'ms_bins_', num2str(step_size) ,'ms_sampled'];
load(results_file);
mean_decoding(t,s,:) = DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results;
%mean_decoding(t,s,:)=filter(1/2*ones(1,2), 1, DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results);
end

%% load non-gen file
results_file = [results_folder '/' results_fileName '_avg', ...
        num2str(nAvg) '_top' num2str(nFeat) 'feat_' ,  ...
        num2str(bin_width), 'ms_bins_', num2str(step_size) ,'ms_sampled'];
load(results_file);
md2(s,:) = diag(DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results);

end

md = reshape(mean_decoding, [size(mean_decoding,1)* size(mean_decoding,2), size(mean_decoding,3)]);
md = squeeze(mean(mean_decoding));

time = -225:step_size:step_size*(size(md,2)-1)-225;

%% Plot invariant
data = md-0.5;
[SignificantTimes, clusters,clustersize,StatMapPermPV] = permutation_cluster_1sample(data, 1000, .05, .05);

SEM = std(md)/sqrt(s);
%figure; shadedErrorBar(time, mean(md), SEM);
figure; plot(time, mean(md), 'k', 'LineWidth', 2)
hold on; plot([0 0], [0.4 0.8], 'k'); 
plot([-225+round(bin_width/2) 1000-bin_width], [1/2, 1/2], 'k')
xlim([-200 1000])
ylim([.45 0.65])
ylabel('Classification Accuracy')
xlabel('Time from stimulus onset (ms) ')
title('Social interaction')
set(gca, 'FontSize', 14)

for i = 1:length(SignificantTimes)
    plot([time(SignificantTimes(i))-round(bin_width/2) time(SignificantTimes(i))+round(bin_width/2)], ...
        [0.465 0.465], 'k', 'LineWidth', 2)
end

%% Plot non-invariant
data2 = md2-0.5;
[SignificantTimes2, clusters,clustersize,StatMapPermPV] = permutation_cluster_1sample(data2, 1000, .05, .05);

SEM2 = std(md2)/sqrt(s);
%hold on; shadedErrorBar(time, mean(md2), SEM2);
plot(time, mean(md2), 'r', 'LineWidth', 2)

for i = 1:length(SignificantTimes2)
    plot([time(SignificantTimes2(i))-round(bin_width/2) time(SignificantTimes2(i))+round(bin_width/2)], ...
        [0.47 0.47], 'r', 'LineWidth', 2)
end

md1 = md;


%% Plot non-invariant Dimitrios
load('/mindhive/nklab3/users/lisik/Toolboxes/fusionlab_demo/rsa_decoding_inv.mat')
md4 = squeeze(mean(md))/100;
data4 = md4-0.5;
[SignificantTimes4, clusters,clustersize,StatMapPermPV] = permutation_cluster_1sample(data4, 1000, .05, .05);

SEM4 = std(md4)/sqrt(s);
%hold on; shadedErrorBar(time, mean(md2), SEM2);
plot(time, mean(md4), 'g', 'LineWidth', 2)

for i = 1:length(SignificantTimes4)
    plot([time(SignificantTimes4(i))-round(bin_width/2) time(SignificantTimes4(i))+round(bin_width/2)], ...
        [0.475 0.475], 'g', 'LineWidth', 2)
end

%% Plot non-invariant Dimitrios
load('/mindhive/nklab3/users/lisik/Toolboxes/fusionlab_demo/rsa_decoding_2cond.mat')
md3 = md/100;
data3 = md3-0.5;
[SignificantTimes3, clusters,clustersize,StatMapPermPV] = permutation_cluster_1sample(data3, 1000, .05, .05);

SEM3 = std(md3)/sqrt(s);
%hold on; shadedErrorBar(time, mean(md2), SEM2);
plot(time, mean(md3), 'b', 'LineWidth', 2)

for i = 1:length(SignificantTimes3)
    plot([time(SignificantTimes3(i))-round(bin_width/2) time(SignificantTimes3(i))+round(bin_width/2)], ...
        [0.48 0.48], 'b', 'LineWidth', 2)
end


%legend({'Invariant', 'Non-invariant', 'Invariant-Dimitrios', 'Non-invariant-Dimitrios'})

for subj = 1:s
    figure; plot(md1(subj,:), 'k', 'LineWidth', 2)
    hold on
    plot(md2(subj,:), 'r', 'LineWidth', 2)
    plot(md3(subj,:), 'b', 'LineWidth', 2)
    plot(md4(subj,:), 'g', 'LineWidth', 2)
    title(file_IDs{subj})
    keyboard
end
    
    
    