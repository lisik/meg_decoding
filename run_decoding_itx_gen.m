null = 0;
file_ID = 's14';
toolbox_path = '/mindhive/nklab3/users/lisik/Toolboxes/ndt.1.0.2/';
raster_path = '/mindhive/nklab3/users/lisik/socialInteraction_meg/raster_data/';
bin_path = '/mindhive/nklab3/users/lisik/socialInteraction_meg/binned_data/';
results_path = '/mindhive/nklab3/users/lisik/socialInteraction_meg/decoding_results/';

%% add pathsl
addpath(toolbox_path);
addpath([toolbox_path 'datasources/']);
%addpath([toolbox_basedir_name 'feature_preprocessors/']);
addpath([toolbox_path 'feature_preprocessors/']);
addpath([toolbox_path 'classifiers/']);
addpath([toolbox_path 'cross_validators/']);
addpath([toolbox_path 'helper_functions/']);
addpath([toolbox_path 'tools/']);


step_size =10;
bin_width = 10;

nFeat = 25;
decoding_runs = 20;
plot_flag = 0;
reps_per_split = 6;
num_cv_splits = 5;
nAvg = reps_per_split;

for t = 1:11
    
results_fileName=['interaction_invariant_' num2str(t)];

test_inds = {[t, t+1, t+12, t+13], [t+24, t+25, t+36, t+37]};
train_inds = {setdiff(1:24, test_inds{1}), setdiff(25:48, test_inds{2})};

%% Bin data
bin_folder = [bin_path file_ID '/'];
if exist(bin_folder, 'dir') ~=7
    eval(['mkdir ' bin_folder])
end
bin_file_name = [bin_folder file_ID '_' num2str(bin_width) ...
    'ms_bins_' num2str(step_size) 'ms_sampled.mat'];
if exist(bin_file_name, 'file')~=2
    create_binned_data_from_raster_data([raster_path file_ID], [bin_folder file_ID], bin_width, step_size);
end 
load(bin_file_name);

% binned_data = cellfun(@(x) x(1:1240,:), binned_data, 'UniformOutput', 0);
% binned_labels.real_stability_ID = cellfun(@(x) x(1:1240), binned_labels.real_stability_ID, 'UniformOutput', 0);
% %% 
results_folder = [results_path file_ID];
if exist(results_folder, 'dir')~=7
    eval(['mkdir ' results_folder])
end


the_labels_to_use = 'stim_ID';

%% create a feature preprocessor that z-score noramlizes each neuron
% note that the FP objects are stored in a cell array since multiple FP
% which allows mutliple FP objects to be used in one analysis
the_feature_preprocessors{1} = zscore_normalize_FP;
% select significant p-values in preprocessing
the_feature_preprocessors{2}=select_or_exclude_top_k_features_FP;
the_feature_preprocessors{2}.num_features_to_use = nFeat;

% the_feature_preprocessors{2}=select_pvalue_significant_features_FP;
% the_feature_preprocessors{2}.pvalue_threshold = .05;
% the_feature_preprocessors{2}.save_extra_info = 1;
%keyboard

ds = avg_generalization_DS(bin_file_name, the_labels_to_use,...
        num_cv_splits, train_inds, ...
        test_inds, nAvg);



%% DS properties to include for each pe of DS
ds.create_simultaneously_recorded_populations = 1;
ds.num_times_to_repeat_each_label_per_cv_split = reps_per_split;
if null==1
	ds.randomly_shuffle_labels_before_running=1;
end
%% create classifier
the_classifier = max_correlation_coefficient_CL;
    
%% create the CV object
the_cross_validator = standard_resample_CV(ds, the_classifier, the_feature_preprocessors);

% set how many times the outer 'bootstrap' loop is run
% generally we use more than 2 bootstrap runs which will give more accurate results
% but to save time in this tutorial we are using a small number.
the_cross_validator.num_resample_runs = decoding_runs;
the_cross_validator.test_only_at_training_times = 1;

%% run the decoding analysis
DECODING_RESULTS = the_cross_validator.run_cv_decoding;

%% Save data
% save the datasource parameters for our records
DATASOURCE_PARAMS = ds.get_DS_properties;
    
save_file_name = [results_folder '/' results_fileName '_avg', ...
        num2str(nAvg) '_top' num2str(nFeat) 'feat_' ,  ...
        num2str(bin_width), 'ms_bins_', num2str(step_size) ,'ms_sampled'];
if null==1
eval(['mkdir ' results_folder '/null'])
save_file_name = [results_folder '/null/' results_fileName '_avg', ...
        num2str(nAvg(t)) '_top' num2str(nFeat) 'feat_' ,  ...
        num2str(bin_width), 'ms_bins_', num2str(step_size) ,'ms_sampled_null' num2str(n)];
end    
% %keyboard
save(save_file_name, 'DECODING_RESULTS', 'DATASOURCE_PARAMS');

%% plot data
if plot_flag==1

figure

plot_obj = plot_standard_results_object({save_file_name});

plot_obj.errorbar_file_names = ({save_file_name});
%plot_obj = plot_standard_results_TCT_object(save_file_name);
    
%%create the correct timescale to display results over
plot_obj.plot_time_intervals.bin_width = bin_width;
plot_obj.plot_time_intervals.sampling_interval = step_size;
plot_obj.plot_time_intervals.alginment_event_time = 226;

%%put a line at the time when the stimulus was shown
plot_obj.significant_event_times = 0;

plot_obj.plot_results;
   
end
end

%
