function run_decoding_itx(subj_num)
null = 0;
null_ind = 1;
%file_ID = ['s' num2str(subj_num)];
file_ID = sprintf('s%02d', subj_num);
eyelink = 0;
om = 1;
TCT = 1;
if om 
    root = '/om/user/lisik/socialInteraction_meg/';
else
    root = '/mindhive/nklab3/users/lisik/socialInteraction_meg';
end
toolbox_path = '/mindhive/nklab3/users/lisik/Toolboxes/ndt.1.0.4_exported/';

raster_path = [root 'raster_data/'];
bin_path = [root 'binned_data/'];
results_path = [root 'decoding_results/'];

results_fileName_all = {'im_ID','interaction', 'gaze', ...
    'watch_v_social', 'watch_v_non'};
labels = {'stim_ID', 'social_ID', 'gaze_ID', 'social_ID', 'social_ID'};
train_inds_all = {1:60, 1:2, 1:2, [1,4], [2,4]};
test_inds_all = {1:60, 1:2, 1:2, [1,4], [2,4]};
reps_per_split =[6,144,72,72,72]; %[4,104, 52, 52,4];%
nAvg = [6 24 24 24 24];
num_cv_splits = 5;

step_size =10;
bin_width = 10;
%nAvg = [6 24 24 24 24];

if subj_num>13
reps_per_split =[6,144,72,72,72]; %[4,104, 52, 52,4];%
nAvg = [6 24 24 24 24];
      
elseif subj_num==6
train_inds_all = {1:52, 1:2, 1:2, [1,4], [2,4]};
test_inds_all = {1:52, 1:2, 1:2, [1,4], [2,4]};  
reps_per_split = [4,104, 52, 52,52];
    nAvg = [4 13 13 13 13];
    else
train_inds_all = {1:52, 1:2, 1:2, [1,4], [2,4]};
test_inds_all = {1:52, 1:2, 1:2, [1,4], [2,4]};
reps_per_split =[5,130,65,50,50];
    nAvg = [5 13 13 13 13];
end

nFeat = 25;
if eyelink 
    file_ID = [file_ID '_eyelink'];
    nFeat = 8;
end

decoding_runs = 5;
plot_flag = 0;
null_runs = 1;
if null
null_runs = null_ind:null_ind+9;
end

for n = null_runs
for t =1:5
results_fileName = results_fileName_all{t};
train_inds = train_inds_all{t};
test_inds = test_inds_all{t};

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

results_folder = [results_path file_ID];
if exist(results_folder, 'dir')~=7
    eval(['mkdir ' results_folder])
end


the_labels_to_use = labels{t};

%% create a feature preprocessor that z-score noramlizes each neuron
% note that the FP objects are stored in a cell array since multiple FP
% which allows mutliple FP objects to be used in one analysis
the_feature_preprocessors{1} = zscore_normalize_FP;

% select significant p-values in preprocessing
the_feature_preprocessors{2}=select_or_exclude_top_k_features_FP;
the_feature_preprocessors{2}.num_features_to_use = nFeat;
the_feature_preprocessors{2}.save_extra_info = 1;

if ~iscell(train_inds) % without generalization
ds = avg_DS(bin_file_name, the_labels_to_use, num_cv_splits, nAvg(t));
ds.label_names_to_use = train_inds;
else % with generalization
   ds = avg_generalization_DS(bin_file_name, the_labels_to_use,...
        num_cv_splits, train_inds, ...
        test_inds, nAvg(t));
end


%% DS properties to include for each pe of DS
ds.create_simultaneously_recorded_populations = 1;
ds.num_times_to_repeat_each_label_per_cv_split = reps_per_split(t);
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
the_cross_validator.test_only_at_training_times = ~TCT;

%% run the decoding analysis
DECODING_RESULTS = the_cross_validator.run_cv_decoding;

%% Save data
% save the datasource parameters for our records
DATASOURCE_PARAMS = ds.get_DS_properties;
    
save_file_name = [results_folder '/' results_fileName '_avg', ...
        num2str(nAvg(t)) '_top' num2str(nFeat) 'feat_' ,  ...
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
results_filename{1}{1} = save_file_name;
plot_obj = plot_standard_results_object(results_filename);

plot_obj.errorbar_file_names{1}{1} = (save_file_name);
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
end
%
end
