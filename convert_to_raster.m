%function convert_to_raster(brainstorm_db, protocol, raster_labels_file, raster_folder, time, triggers)
% convert pre-processed brainstorm files to raster format for decoding
% brainstorm_db - filepath for brainstorm databse (e.g.'~/brainstorm/brainstorm_db')
% protocol - name of brainstorm protocol 
% subject name - name of brainstorm subject 
% raster_labels_file - name of file with struct raster_labels containing stimulus labels for each trial
% raster_folder - folder where rasters will be saved
% time - length of epoch time used in brainstorm - 801 (-200:600ms) is value used in Isik et al., 2014)
% triggers - a vector of the trigger ID's used in the experiment
% convert_to_raster('~/brainstorm/brainstorm_db', 'test', '~/MEG/MEG_data/behavior_resp/05_08_12/exp_CBCL_05_08_12_exp_info.mat', '~/MEG_decoding_2013/raster_data/test', 801,1)

brainstorm_db = '/mindhive/nklab3/users/lisik/brainstorm/brainstorm_db';
protocol = 'subject06';
raster_labels_file = '/mindhive/nklab3/users/lisik/IARPA/MEG_data/160908/subject06_results.mat';
raster_folder = '/mindhive/nklab3/users/lisik/IARPA/MEG_data/raster_data/sub06';

brainstorm_db = '/mindhive/nklab3/users/lisik/brainstorm/brainstorm_db';
protocol = 'IARPA11_tsss';
%raster_labels_file = '/mindhive/nklab3/users/lisik/IARPA/MEG_data/160908/subject06_results.mat';
raster_folder = '/mindhive/nklab3/users/lisik/IARPA/MEG_data/raster_data/IARPA11_tsss';

time = 5001;
triggers = 1;

if brainstorm_db(end)~='/'
    brainstorm_db = [brainstorm_db '/'];
end
if raster_folder(end)~='/'
    raster_folder = [raster_folder '/'];
end

if exist(raster_folder,'dir')~=7
    eval(['mkdir ' raster_folder])
end

load(raster_labels_file)
nchannels = 1:306; % 306 MEG channels
%nchannels = 12:317;
%time = 1:801;%time range -200:600 ms (used in Isik et al., 2014)

full_dir_name = [brainstorm_db,protocol,'/data/test/'];
bad_files = {'data_1_trial116_03_bandpass.mat'};
%6:bad_files = {'data_1_trial028_04_bandpass.mat', 'data_1_trial038_04_bandpass.mat'};
%5:bad_files = {'data_1_trial078_bandpass.mat', 'data_1_trial082_bandpass.mat', ...
%    'data_1_trial184_bandpass.mat', 'data_1_trial202_02_bandpass.mat'};
%4:bad_files = {'data_1_trial159_03_bandpass.mat', 'data_1_trial224_02_bandpass.mat', 'data_1_trial325_02_bandpass.mat'};
for i = 1:length(bad_files)
    unix(['rm ' full_dir_name '1/' bad_files{i}])
end
% keyboard
for trigID = 1:triggers
%% reorder brainstorm file list in order of stimulus presentation -- probably a better way to do this
all_files = dir([full_dir_name num2str(trigID) '/data*bandpass.mat']);
all_files = {all_files.name};
files{1} = all_files;
file_breaks = sum(cellfun(@str2num,regexp([all_files{:}], '\d{3,}', 'match'))==1);

for i = file_breaks:-1:2
files_tmp = dir([full_dir_name num2str(trigID) '/data*_' sprintf('%02d',i) '_bandpass.mat']);
files{i} = {files_tmp.name};
file_inds{i} = cellfun(@str2num,regexp([files{i}{:}], '\d{3,}', 'match'));
[~,ind{i}] = sort(file_inds{i});
files{1} = setdiff(files{1}, files{i});
end
 
file_inds{1} = cellfun(@str2num,regexp([files{1}{:}], '\d{3,}', 'match'));
[~,ind{1}] = sort(file_inds{1});

file_list{trigID} = [];
for i = 1:file_breaks
   % keyboard
    file_list{trigID} = [file_list{trigID} files{i}(ind{i})];
end
end
rasters = zeros(length(nchannels), length(file_list{trigID}), time);
%for i = 1:length(file_list{trigID})

%keyboard

for i = 1:length(file_list{trigID})
    
    eval(['load ' full_dir_name num2str(trigID) '/' file_list{trigID}{i}])
    rasters(ChannelFlag==1,i,1:size(F,2)) = F(ChannelFlag==1,:);%omit "bad channels"
    clear F ChannelFlag
    
    % print a message the the data is being loaded
    curr_string = [' \nLoading trial: ' num2str(i) ' of ' num2str(length(file_list{trigID}))];
    if i == 1
        disp(curr_string); 
    else
        fprintf([repmat(8,1,length(curr_string)) curr_string]);         
    end
   % fprintf('Loading trial  %s', num2str(i))

  
end

rasters = rasters(nchannels,:,:);

% %raster_labels = labels;
% stim_names = {exp_params.image_list.name};
% animacy_map = [1 1 0 1 0 1 1 1 0 1 1 0 0 0 1 1 0 0 0 0];
% size_map = [1 2 2 1 2 2 1 1 1 1 2 2 1 2 1 2 2 1 2 2];
% 
% %% for 16 words
% animacy_map = [1 1 0 1 0 1 1 1 1 0 0 0 0 0 0 1];
% size_map = [1 2 2 1 2 2 1 1 2 2 1 1 1 2 1 2 ];
% if strcmp(protocol, 'subject05')
%     animacy_map = [1 1 0 1 0 1 1 1 0 1 1 0 0 0 0 0 0 1 1 0 0 0 0];
%     size_map = [1 2 2 1 2 2 1 1 1 1 2 2 1 1 1 2 1 2 2 1 2 2];
% end
% % animacy_map = [1 1 0 1 0 1 1 1 0 1 1 0 0 0];
% % size_map = [1 2 2 1 2 2 1 1 1 1 2 2 1 2];
% %keyboard
% stim_ID = cell2mat(exp_params.im_order);
% responses_ID = cell2mat(responses);
% size_ID = cell2mat(exp_params.size_factors);
% 
% if strcmp(protocol, 'subject01')
% stim_ID = stim_ID([1:600,  2000-639:2000-40]);
% size_ID = size_ID([1:600,  2000-639:2000-40]);
% responses_ID = responses_ID(1:1200);
% elseif strcmp(protocol, 'subject05')
% stim_ID = stim_ID([1:1152]);
% size_ID = size_ID([1:1152]);
% %responses_ID = responses_ID(1:1152);    
% end
% animacy_ID = animacy_map(stim_ID);
% perc_size_ID = size_map(stim_ID);
% 
% size_ID(size_ID==.25)=1;
% size_ID(size_ID==.5) = 2;
% type_ID = [ones(1,length(stim_ID)/2), 2*ones(1,length(stim_ID)/2)];
% if strcmp(protocol, 'subject05') || strcmp(protocol, 'subject06')
%     type_ID = [ones(1,length(stim_ID))];
% end
% type_stim_ID = zeros(1,length(stim_ID));
% type_size_stim_ID = type_stim_ID;
% type_animacy_ID = type_stim_ID;
% type_perc_size_ID = type_stim_ID;
% for i = 1:length(stim_ID)
% type_stim_ID(i) = str2num(sprintf('%d%02d', type_ID(i), stim_ID(i)));
% type_size_stim_ID(i) = str2num(sprintf('%d%d%02d', type_ID(i), size_ID(i), stim_ID(i)));
% 
% type_animacy_ID(i) = str2num(sprintf('%d%02d', type_ID(i), animacy_ID(i)));
% type_perc_size_ID(i) =  str2num(sprintf('%d%02d', type_ID(i), perc_size_ID(i)));
% end
% raster_labels = struct('stim_ID', stim_ID, 'stim_names', stim_names, ...
%     'size_ID', size_ID, 'type_ID', type_ID, 'type_stim_ID', type_stim_ID, ...
%     'type_size_stim_ID', type_size_stim_ID, 'type_animacy_ID', type_animacy_ID, ...
%     'type_perc_size_ID', type_perc_size_ID, 'animacy_ID', animacy_ID, ...
%     'perc_size_ID', perc_size_ID, 'responses_ID', responses_ID);
% %keyboard
% raster_labels2 = raster_labels;
% %keyboard
raster_labels = [];
for i = 1:306
    
    raster_data = squeeze(rasters(i,:,:));
    raster_site_info = struct('recording_channel', i);
%     load([raster_folder '/raster_ch'  sprintf('%03d', i) '.mat'])
   % raster_labels = raster_labels2;
    save([raster_folder '/raster_ch'  sprintf('%03d', i) '.mat'], ...
         'raster_labels', 'raster_data', 'raster_site_info');
i
end
% 
% 
% 
