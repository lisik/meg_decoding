function convert_to_raster(brainstorm_db, protocol, behave_file, raster_folder)
% convert pre-processed brainstorm files to raster format for decoding
% brainstorm_db - filepath for brainstorm databse (e.g.'~/brainstorm/brainstorm_db')
% protocol - name of brainstorm protocol 
% subject name - name of brainstorm subject 
% behave_file - name of file with behavioral data
% raster_folder - folder where rasters will be saved 
% convert_to_raster('~/brainstorm/brainstorm_db', 'test', '~/MEG/MEG_data/behavior_resp/05_08_12/exp_CBCL_05_08_12_exp_info.mat', '~/MEG_decoding_2013/raster_data/test')

if brainstorm_db(end)~='/'
    brainstorm_db = [brainstorm_db '/'];
end
if raster_folder(end)~='/'
    raster_folder = [raster_folder '/'];
end

if exist(raster_folder,'dir')~=7
    eval(['mkdir ' raster_folder])
end

load(behave_file)
nchannels = 1:306; % 306 MEG channels
time = 1:801;%time range -200:600 ms (used in Isik et al., 2014)

full_dir_name = [brainstorm_db,protocol,'/data/test/1/'];

%% reorder brainstorm file list in order of stimulus presentation -- probably a better way to do this
all_files = dir([full_dir_name 'data*bandpass.mat']);
all_files = {all_files.name};
files{1} = all_files;
file_breaks = sum(cellfun(@str2num,regexp([all_files{:}], '\d{3,}', 'match'))==1);

for i = file_breaks:-1:2
files_tmp = dir([full_dir_name 'data*_' sprintf('%02d',i) '_bandpass.mat']);
files{2} = {files_tmp.name};
file_inds{2} = cellfun(@str2num,regexp([files{2}{:}], '\d{3,}', 'match'));
[~,ind{2}] = sort(file_inds{2});
files{1} = setdiff(files{1}, files{i});
end
 
file_inds{1} = cellfun(@str2num,regexp([files{1}{:}], '\d{3,}', 'match'));
[~,ind{1}] = sort(file_inds{1});

file_list = [];
for i = 1:file_breaks
    file_list = [file_list files{i}(ind{i})];
end

rasters = zeros(length(nchannels), length(file_list), length(time));

for i = 1:length(file_list)
    
    eval(['load ' full_dir_name file_list{i}])
    rasters(ChannelFlag==1,i,1:size(F,2)) = F(ChannelFlag==1,:);%omit "bad channels"
    clear F ChannelFlag
  
end

rasters = rasters(nchannels,:,:);

% stimuli = {'basketball', 'bowlingball', 'football', 'hat', 'child', 'man'};
sizes = {'large', 'medium', 'small'};
pos = {'center', 'up', 'down'};
% stim_ID = images_info(:,1);
stim_names = stimuli([stim_ID]);
size_pos_stim_ID = str2num([num2str(stim_size) num2str(stim_pos) num2str(stim_ID)]);
size_pos_stim_names = strcat(sizes(stim_size), '_',  pos(stim_pos), '_' ,stimuli(stim_ID));

raster_labels = struct('stim_ID', stim_ID, 'stim_names', stim_names, ...
    'size_pos_stim_ID', size_pos_stim_ID, 'size_pos_stim_names', size_pos_stim_names);

for i = 1:size(rasters,1)
    
    raster_data = squeeze(rasters(i,:,:));
    raster_site_info = struct('recording_channel', i);
    
    save([raster_folder '/raster_ch'  sprintf('%03d', i) '.mat'], ...
         'raster_labels', 'raster_data', 'raster_site_info');

end
% 
% 
% 
