function run_decoding_itx_gen(subj_num, eyelink)

file_ID = sprintf('s%02d', subj_num);
root = '/om/user/lisik/socialInteraction_meg/';

raster_path = [root 'raster_data/'];
bin_path = [root 'binned_data/'];
results_path = [root 'decoding_results/'];
toolbox_path = '/om/user/lisik/ndt.1.0.4_exported/';

%% add paths
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
decoding_runs = 2;
num_cv_splits = 2;

% Make eyelink an argument
null = 0;

if eyelink
    nFeat = 4;
    file_ID = [file_ID '_eyelink'];
end

reps_per_split = 30;
nAvg = reps_per_split;
nAvg = 24;

scenarios = [randperm(12) randperm(12)];
%scenarios = [scenarios scenarios(1)];

results_fileName_all={'interaction', 'gaze', 'watch_v_social', 'watch_v_non'};

%test_inds = {[t, t+1, t+12, t+13], [t+24, t+25, t+36, t+37]};
inds = {[0 12; 24 36], [0;12], [12;48], [24;48]};
train_inds_all = {[1:24; 25:48], [1:12;13:24], [13:24; 49:60], [25:36; 49:60]};
for j = 1:4
for t = 1:20
results_fileName = [results_fileName_all{j} '_invariant_' num2str(t)];

%test_inds = {[scenarios(t), scenarios(t+1), scenarios(t)+12, scenarios(t+1)+12], ...
%    [scenarios(t)+24, scenarios(t+1)+24, scenarios(t)+36, scenarios(t+1)+36]};

test_inds = {[scenarios(t)+inds{j}(1,:), scenarios(t+1)+inds{j}(1,:)], ...
    [scenarios(t)+inds{j}(2,:), scenarios(t+1)+inds{j}(2,:)]};
train_inds = {setdiff(train_inds_all{j}(1,:), test_inds{1}), ...
    setdiff(train_inds_all{j}(2,:), test_inds{2})};

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
the_feature_preprocessors{2}.save_extra_info = 1;
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
the_cross_validator.test_only_at_training_times = 0;

%% run the decoding analysis
DECODING_RESULTS = the_cross_validator.run_cv_decoding;

%% Save data
% save the datasource parameters for our records
DATASOURCE_PARAMS = ds.get_DS_properties;
    
save_file_name = [results_folder '/' results_fileName '_avg', ...
        num2str(nAvg) '_top' num2str(nFeat) 'feat_' ,  ...
        num2str(bin_width), 'ms_bins_', num2str(step_size) ,'ms_sampled'];
    
% save_file_name = [results_folder '/' results_fileName '_avg', ...
%         num2str(nAvg) '_05pv_feat_' ,  ...
%         num2str(bin_width), 'ms_bins_', num2str(step_size) ,'ms_sampled'];  
% %keyboard
save(save_file_name, 'DECODING_RESULTS', 'DATASOURCE_PARAMS');


end
end
end
%
