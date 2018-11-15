function run_decoding_gender(subj_num)
null = 0;
%file_ID = 's14';
file_ID = sprintf('s%02d', subj_num);
%om = 1;
%if om 
    root = '/om/user/lisik/socialInteraction_meg/';
%else
%    root = '/mindhive/nklab3/users/lisik/socialInteraction_meg';
%end
%toolbox_path = '/mindhive/nklab3/users/lisik/Toolboxes/ndt.1.0.4_exported/';

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
bin_width = step_size;

nFeat = 25;
decoding_runs = 10;
plot_flag = 0;
reps_per_split = 10;
num_cv_splits = 2;

if subj_num > 13
reps_per_split = 6;
elseif subj_num ==6
  reps_per_split = 4;
 else
   reps_per_split = 5;
end
reps_per_split = reps_per_split*5
nAvg = reps_per_split;

%% Both female/both male
class1=  [1,0,0,0,0,0,0,1,1,0,0,0]; % both female
class2 = [0,0,0,1,0,1,0,0,0,0,0,1]; % both male
all_class1 = find(class1(repmat(1:12,[1 5])));
all_class2 = find(class2(repmat(1:12,[1 5])));
class1 = find(class1);
class2 = find(class2);
class2 = [4 12 6];

%% Same different gender
% class1=[1, 0,0,1,0,1,0,1,1,0,0,1];
% class2 = ~[1, 0,0,1,0,1,0,1,1,0,0,1];
% all_class1 = find(class1(repmat(1:12,[1 5])));
% all_class2 = find(class2(repmat(1:12,[1 5])));
% class1 = find(class1);
% class2 = find(class2);

% class1 = [class1(randperm(length(class1))) class1(randperm(length(class1))) ...
%     class1(randperm(length(class1))) class1(randperm(length(class1)))];
% class2 = [class2(randperm(length(class2))) class2(randperm(length(class2))) ...
%     class2(randperm(length(class2))) class2(randperm(length(class2)))];

for t = 1:length(class1)
    
results_fileName=['genderMF_bal_invariant_' num2str(t) '_ag'];

test_inds = {(class1(t)-1)+[1,13,25,37,49], (class2(t)-1)+[1,13,25,37,49]};
train_inds = {setdiff(all_class1, test_inds{1}), setdiff(all_class2, test_inds{2})};

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
end
%
