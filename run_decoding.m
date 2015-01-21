function run_decoding(file_ID, toolbox_path, raster_path, bin_path, results_path, results_fileName, ...
    labels, train_inds, test_inds, num_cv_splits, reps_per_split, ...
    step_size, bin_width, nAvg, nFeat, decoding_runs, plot_flag)

% run_decoding('test', '~/toolboxes/neural-decoding-toolbox-read-only/ndt.1.0.1/', '~/MEG_decoding_2013/raster_data', '~/MEG_decoding_2013/binned_data', ...
%     '~/MEG_decoding_2013/results', 'up_large', 'size_pos_stim_ID', ...
% [111,112,113,114,115,116], [111,112,113,114,115,116], 5, 10, ...
%     50, 50, 10, 25, 2, 1)
%% to change:
% train_inds/test_inds (labels instead of numbers)
% make results_fileName based on training/testing labels
% change names 'file_ID', do we need toolbox path?

if raster_path(end)~='/'
    raster_path = [raster_path '/'];
end
if bin_path(end)~='/'
    bin_path = [bin_path '/'];
end
if results_path(end)~='/'
    results_path = [results_path '/'];
end

%% add paths
addpath(toolbox_path);
addpath([toolbox_path 'datasources/']);
%addpath([toolbox_basedir_name 'feature_preprocessors/']);
addpath([toolbox_path 'feature_preprocessors/']);
addpath([toolbox_path 'classifiers/']);
addpath([toolbox_path 'cross_validators/']);
addpath([toolbox_path 'helper_functions/']);
addpath([toolbox_path 'tools/']);


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

%% 
results_folder = [results_path file_ID];
if exist(results_folder, 'dir')~=7
    eval(['mkdir ' results_folder])
end


the_labels_to_use = labels;

%% create a feature preprocessor that z-score noramlizes each neuron
% note that the FP objects are stored in a cell array since multiple FP
% which allows mutliple FP objects to be used in one analysis
the_feature_preprocessors{1} = zscore_normalize_FP;
% select significant p-values in preprocessing
the_feature_preprocessors{2}=select_or_exclude_top_k_features_FP;
the_feature_preprocessors{2}.num_features_to_use = nFeat;
the_feature_preprocessors{2}.save_extra_info = 1;


if train_inds==test_inds % without generalization
   ds = avg_DS(bin_file_name, the_labels_to_use, num_cv_splits, nAvg);
   ds.label_names_to_use = train_inds;
else % with generalization
   ds = avg_generalization_DS(bin_file_name, the_labels_to_use,...
        num_cv_splits, {train_inds}, ...
        {test_inds}, nAvg);
end


%% DS properties to include for each pe of DS
ds.create_simultaneously_recorded_populations = 1;
ds.num_times_to_repeat_each_label_per_cv_split = reps_per_split;

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
    

save(save_file_name, 'DECODING_RESULTS', 'DATASOURCE_PARAMS');

%% plot data
if plot_flag==1

figure

plot_obj = plot_standard_results_object({{save_file_name}});

plot_obj.errorbar_file_names = ({{save_file_name}});
    
%%create the correct timescale to display results over
plot_obj.plot_time_intervals.bin_width = bin_width;
plot_obj.plot_time_intervals.sampling_interval = step_size;
plot_obj.plot_time_intervals.alginment_event_time = 226;

%%put a line at the time when the stimulus was shown
plot_obj.significant_event_times = 0;

plot_obj.plot_results;
   
end
end
%end

%