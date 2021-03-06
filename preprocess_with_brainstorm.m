function preprocess_with_brainstorm(RawFilePath, fileNames, epochTime)
% Script generated by Brainstorm v3.2 (14-Nov-2014)
% To run script, you must first open brainstorm and create new protocol
% RawFilePath - file path for folder with raw MEG .fif data
% fileNames - cell of names of raw MEG .fif file names
% time interval in seconds relative to stimulus onset. [-.2, .6] used in (Isik et al, 2014)

SubjectNames = {'test'}; % default subject name
%epochTime = [-0.2, .6]; % time interval relative to stimulus onset used in (Isik et al, 2014)

% Input files
sFiles = [];

if RawFilePath(end)~='/'
    RawFilePath = [RawFilePath '/'];
end

RawFiles = strcat(RawFilePath, fileNames);
%for i = 1:length(RawFiles)
for i = 1:length(fileNames)

% Process: Create link to raw file
sFiles = bst_process('CallProcess', 'process_import_data_raw', ...
    sFiles, [], ...
    'subjectname', SubjectNames{1}, ...
    'datafile', {RawFiles{i}, 'FIF'}, ...
    'channelreplace', 1, ...
    'channelalign', 1);

% Process: Read from channel
sFiles = bst_process('CallProcess', 'process_evt_read', ...
    sFiles, [], ...
    'stimchan', 'STI101', ...
    'trackmode', 1, ...  % Value: detect the changes of channel value
    'zero', 0);

% Process: Import MEG/EEG: Events
sFiles = bst_process('CallProcess', 'process_import_data_event', ...
    sFiles, [], ...
    'subjectname', SubjectNames{1}, ...
    'condition', '1', ...
    'eventname', '1', ...
    'timewindow', [], ...
    'epochtime', epochTime, ...
    'createcond', 1, ...
    'ignoreshort', 0, ...
    'usectfcomp', 1, ...
    'usessp', 1, ...
    'freq', [], ...
    'baseline', []);

% Process: Band-pass:0.01Hz-100Hz
sFiles = bst_process('CallProcess', 'process_bandpass', ...
    sFiles, [], ...
    'highpass', 0.01, ...
    'lowpass', 100, ...
    'mirror', 1, ...
    'sensortypes', 'MEG, EEG', ...
    'overwrite', 0);
% Save and display report
% ReportFile = bst_report('Save', sFiles);
% bst_report('Open', ReportFile);

end
end
