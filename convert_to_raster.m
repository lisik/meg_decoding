function convert_to_raster(brainstorm_db, protocol, subject_name, raster_labels_file, ...
    raster_folder, time, triggers, channels)
% convert pre-processed brainstorm files to raster format for decoding
% brainstorm_db - filepath for brainstorm databse (e.g.'~/brainstorm/brainstorm_db')
% protocol - name of brainstorm protocol 
% subject_name - name of brainstorm subject 
% raster_labels_file - name of file with struct raster_labels containing stimulus labels for each trial
% raster_folder - folder where rasters will be saved
% time - length of epoch time used in brainstorm - 801 (-200:600ms) is value used in Isik et al., 2014)
% triggers - a vector of the trigger ID's used in the experiment
% chanels the indices of the MEG channels
% convert_to_raster('~/brainstorm/brainstorm_db', 'test', 'NewSubject', ...
% '~/MEG/MEG_data/behavior_resp/05_08_12/exp_CBCL_05_08_12_exp_info.mat', ...
% '~/MEG_decoding_2013/raster_data/test', 801,1, 1:306)


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
%channels = 1:306; % 306 MEG channels
%time = 1:801;%time range -200:600 ms (used in Isik et al., 2014)

full_dir_name = [brainstorm_db,protocol,'/data/' subject_name '/Default/'];
rasters = [];
count = 0;

for trigID = triggers
%% reorder brainstorm file list in order of stimulus presentation and deal with their number/naming convention
all_files = dir([full_dir_name '/data_' num2str(trigID) '*band.mat']);
all_files = {all_files.name};
files{1} = all_files;
file_breaks = sum(cellfun(@str2num,regexp([all_files{:}], '\d{3,}', 'match'))==1);

for i = file_breaks:-1:2
files_tmp = dir([full_dir_name '/data_' num2str(trigID) '*_' sprintf('%02d',i) '_band.mat']);
files{i} = {files_tmp.name};
file_inds{i} = cellfun(@str2num,regexp([files{2}{:}], '\d{3,}', 'match'));
[~,ind{i}] = sort(file_inds{2});
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

for i = 1:length(file_list{trigID})
    count = count+1;
    eval(['load ' full_dir_name num2str(trigID) '/' file_list{trigID}{i}])
    
    rasters(ChannelFlag==1,count,1:size(F,2)) = F(ChannelFlag==1,:);%omit "bad channels"
    clear F ChannelFlag
    
    % print a message the the data is being loaded
    curr_string = ['\nLoading trigger: ' num2str(trigID) ...
        '\nLoading trial: ' num2str(i) ' of ' num2str(length(file_list{trigID}))];
    if i == 1
        disp(curr_string); 
    else
        fprintf([repmat(8,1,length(curr_string)) curr_string]);         
    end
   % fprintf('Loading trial  %s', num2str(i))

  
end
end
% 
% % stimuli = {'basketball', 'bowlingball', 'football', 'hat', 'child', 'man'};
% sizes = {'large', 'medium', 'small'};
% pos = {'center', 'up', 'down'};
% % stim_ID = images_info(:,1);
% stim_names = stimuli([stim_ID]);
% size_pos_stim_ID = str2num([num2str(stim_size) num2str(stim_pos) num2str(stim_ID)]);
% size_pos_stim_names = strcat(sizes(stim_size), '_',  pos(stim_pos), '_' ,stimuli(stim_ID));
% 
% raster_labels = struct('stim_ID', stim_ID, 'stim_names', stim_names, ...
%     'size_pos_stim_ID', size_pos_stim_ID, 'size_pos_stim_names', size_pos_stim_names);

%raster_labels = labels;

%keyboard
for i = 1:size(rasters,1)
    
    raster_data = squeeze(rasters(i,:,:));
    raster_site_info = struct('recording_channel', i);
    
    save([raster_folder '/raster_ch'  sprintf('%03d', i) '.mat'], ...
         'raster_labels', 'raster_data', 'raster_site_info');

end
% 
% 
% 
