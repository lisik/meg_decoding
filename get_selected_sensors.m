clear all
results_path = '/om/user/lisik/socialInteraction_meg/decoding_results/';
results_fileName = {'im_ID', 'interaction', 'gaze', 'watch_v_social', 'watch_v_non'};
subj = {'s16','s18','s19', 's22', 's23', 's24', 's25', 's26', 's27', 's28', 's29', 's30'}; %check s25 preproc


step_size = 10;
bin_width =10;
nFeat = 25;
nAvg = [6 24 24 24 24];



for s = 1:length(subj)
for cond = 1
results_folder = [results_path subj{s}];
results_file = [results_folder '/' results_fileName{cond} '_avg', ...
        num2str(nAvg(cond)) '_top' num2str(nFeat) 'feat_' ,  ...
        num2str(bin_width), 'ms_bins_', num2str(step_size) ,'ms_sampled'];
load(results_file);

pv = DECODING_RESULTS.FP_INFO{2}.the_p_values_org_order;
[~,sorted_sensors] = sort(pv,4);
% get the top N significant sensors that were used in decoding
selected_sensors = sorted_sensors(:,:,:,1:nFeat);

%get the proprtion of times each sensor was selected
prop_sel(s,:,:) = zeros(size(sorted_sensors,3), size(sorted_sensors,4));
%loop through resample runs and CV splits
for i = 1:size(selected_sensors,1)
for j = 1:size(selected_sensors,2)
for t = 1:size(selected_sensors,3)
    prop_sel(s,t,squeeze(selected_sensors(i,j,t,:))) = prop_sel(s,t,squeeze(selected_sensors(i,j,t,:)))+1; 
end
end
end

prop_sel(s,:,:) = prop_sel(s,:,:)/(size(selected_sensors,1)*size(selected_sensors,2));

end
end

keyboard
mean_sel = squeeze(mean(prop_sel));
%% to load into brainstorm format
% export a data file to Matlab call variable "data", downsample time
load('/mindhive/nklab3/users/lisik/brainstorm/brainstorm3/sensor_data_file_new.mat')
data.F = zeros(320, 120);
data.Time = -210:10:980;
data.F(1:306,:) = mean_sel';
save(['/mindhive/nklab3/users/lisik/brainstorm/brainstorm_db/sensor_data_file_id.mat'], 'data')
%% Load in matlab and then in brainstorm load data from matlab