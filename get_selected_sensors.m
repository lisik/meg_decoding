clear all
results_path = '/mindhive/nklab3/users/lisik/socialInteraction_meg/decoding_results/';
results_fileName = {'im_ID', 'interaction', 'gaze', 'watch_v_social', 'watch_v_non'};
subj = {'s14', 's14'};

step_size = 10;
bin_width =10;
nFeat = 25;
nAvg = [6 24 24 24 24];



for s = 1
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
prop_sel = zeros(size(sorted_sensors,3), size(sorted_sensors,4));
%loop through resample runs and CV splits
for i = 1:size(selected_sensors,1)
for j = 1:size(selected_sensors,2)
for t = 1:size(selected_sensors,3)
    prop_sel(t,squeeze(selected_sensors(i,j,t,:))) = prop_sel(t,squeeze(selected_sensors(i,j,t,:)))+1; 
end
end
end

prop_sel = prop_sel/(size(selected_sensors,1)*size(selected_sensors,2));

end
end

%% to load into brainstorm format
% export a data file to Matlab call variable "data", downsample time
% load('sensor_data_file.mat')
% data.F(1:306,:) = prop_sel';

