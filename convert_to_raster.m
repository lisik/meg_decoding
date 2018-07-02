%function convert_to_raster(brainstorm_db, protocol, subject_name, raster_labels_file, raster_folder, time, triggers)
% convert pre-processed brainstorm files to raster format for decoding
% brainstorm_db - filepath for brainstorm databse (e.g.'~/brainstorm/brainstorm_db')
% protocol - name of brainstorm protocol 
% subject name - name of brainstorm subject 
% raster_labels_file - name of file with struct raster_labels containing stimulus labels for each trial
% raster_folder - folder where rasters will be saved
% time - length of epoch time used in brainstorm - 801 (-200:600ms) is value used in Isik et al., 2014)
% triggers - a vector of the trigger ID's used in the experiment
% convert_to_raster('~/brainstorm/brainstorm_db', 'test', 'NewSubject', '~/MEG/MEG_data/behavior_resp/05_08_12/exp_CBCL_05_08_12_exp_info.mat', '~/MEG_decoding_2013/raster_data/test', 801,1)
subjID = '14';
date = '180608';
eyelink = 1;
brainstorm_db = '/mindhive/nklab3/users/lisik/brainstorm/brainstorm_db';
protocol = sprintf('soc_meg_%s', subjID);
subject_name = 'NewSubject';
%protocol = sprintf('meg_soc_%s', subjID);
ntrials = 1800;%1550;%1300;%1040;
raster_labels_file = sprintf('/mindhive/nklab3/users/lisik/socialInteraction_meg/raw_data/%s/s%s_results.mat', ...
    date, subjID);
time = 1200;
triggers = [1,2,4];
channels = 1:306; % 306 MEG channels
raster_add = [];
if eyelink 
    channels = 311:318;
    raster_add = '_eyelink';
end
raster_folder = sprintf('/mindhive/nklab3/users/lisik/socialInteraction_meg/raster_data/s%s%s', subjID, raster_add);


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

full_dir_name = [brainstorm_db,protocol,'/data/' subject_name '/Default/'];
rasters = [];
count = 0;
<<<<<<< HEAD
=======

>>>>>>> origin
for trigID = triggers
%% reorder brainstorm file list in order of stimulus presentation -- probably a better way to do this
%all_files = dir([full_dir_name num2str(trigID) '/data*bandpass.mat']);
all_files = dir([full_dir_name '/data_' num2str(trigID) '*band.mat']); %*band.mat
%all_files = dir([full_dir_name '/data_' num2str(trigID) '*low.mat']);
all_files = {all_files.name};

file_breaks = sum(cellfun(@str2num,regexp([all_files{:}], '\d{3,}', 'match'))==1);
for i = 1:file_breaks-1
files{1} = all_files;
end    

for i = file_breaks:-1:2
files_tmp = dir([full_dir_name '/data_' num2str(trigID) '*_' sprintf('%02d',i) '*band.mat']);%*band.mat
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

rasters = [rasters zeros(length(channels), length(file_list{trigID}), time)];
<<<<<<< HEAD
%for i = 1:length(file_list{trigID})
%rasters = zeros(length(nchannels), 1200, time);
% keyboard
% file_list{trigID} = file_list{trigID}([1:600, length(file_list{trigID})-600:length(file_list{trigID})-1]);
% keyboard
for i = 1:length(file_list{trigID})
    count = count+1;
    eval(['load ' full_dir_name '/' file_list{trigID}{i}])
    
    if size(F,2) < time
    rasters(:,count,1:size(F,2)) = F(channels,:);%omit "bad channels"
    else
    rasters(:,count,1:time) = F(channels,1:time);%omit "bad channels"
    end
    
=======

for i = 1:length(file_list{trigID})
    count = count+1;
    eval(['load ' full_dir_name num2str(trigID) '/' file_list{trigID}{i}])
    
    rasters(ChannelFlag==1,count,1:size(F,2)) = F(ChannelFlag==1,:);%omit "bad channels"
>>>>>>> origin
    clear F ChannelFlag
    
    % print a message the the data is being loaded
    curr_string = [' \nLoading trigger: ' num2str(trigID) ...
        '\n trial: ' num2str(i) ' of ' num2str(length(file_list{trigID}))];
    if i == 1
        disp(curr_string); 
    else
        fprintf([repmat(8,1,length(curr_string)) curr_string]);         
    end
   % fprintf('Loading trial  %s', num2str(i))

  
end
end
%rasters = rasters(nchannels,1:ntrials,:);

%raster_labels = labels;
% stim_names = {exp_params.image_list.name};
% animacy_map = [1 1 0 1 0 1 1 1 0 1 1 0 0 0 1 1 0 0 0 0];
% size_map = [1 2 2 1 2 2 1 1 1 1 2 2 1 2 1 2 2 1 2 2];
% animacy_map = [1 1 0 1 0 1 1 1 0 1 1 0 0 0];
% sdgender_map = [1 1 2 2 2 1 2 2 1 2 2 1 1 2 1 1 ...
%     1 1 1 2 2 2 2 1 1 2 2 1 1 1 2 2];
present_order1 = exp_params.present_order;
present_order = [present_order1(present_order1<25) present_order1(present_order1>24 & present_order1<49) ...
    present_order1(present_order1 > 48)];
% %keyboard
stim_ID = present_order;
social_ID = exp_params.interact_code(present_order);
gaze_ID = ceil(present_order/12);
%sdgender_ID = sdgender_map(present_order);

raster_labels = struct('stim_ID', stim_ID, 'social_ID', social_ID, ...
    'gaze_ID', gaze_ID);
%keyboard
%raster_labels2 = raster_labels;
%keyboard
for i = channels
    
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
