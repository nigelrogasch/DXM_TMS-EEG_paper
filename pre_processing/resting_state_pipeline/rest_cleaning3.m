clear; close all; clc;

%##### STEP 3: RUN ICA #####

%% SETTINGS AND FILE PATHS/NAMES

% Participant IDs
ID = {'001';'002';'003';'004';'005';'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};

% Conditions
con = {'C1';'C2'};

% Underscore
u = '_';

% Paths
pathIn = 'I:\nmda_tms_eeg\REST_CLEAN1\';
pathOut = 'I:\nmda_tms_eeg\REST_CLEAN1\';

% Create cell array with file paths and names
for a = 1:size(ID,1)
    for c = 1:size(con,1)
        
        filePathTemp{a,c} = [pathIn ID{a,1} filesep con{c,1} filesep];
        fileNameTemp{a,c} = [ID{a,1} u con{c,1} 'ds_filt_ep_clean.set'];
        fileIDTemp{a,c} = ID{a,1};
        fileConTemp{a,c} = con{c,1};
        
    end
end

% Reshape file paths and names in to 1xN cell array
filePath = reshape(filePathTemp,1,[]);
fileName = reshape(fileNameTemp,1,[]);
fileID = reshape(fileIDTemp,1,[]);
fileCon = reshape(fileConTemp,1,[]);

%% RUN PARFOR LOOP FOR ICA

parfor x = 1:length(filePath)
    restCleaningStep3(filePath{x},fileName{x});
    fprintf('%s %s is finished\n',fileID{x},fileCon{x});
end

%% FUNCTION FOR LOADING DATA, RUNNING ICA
function restCleaningStep3(filePath,fileName)

    % Load data
    EEG = pop_loadset('filename', fileName, 'filepath', filePath);

    % Run FastICA
    EEG = pop_tesa_fastica( EEG, 'approach', 'symm', 'g', 'tanh', 'stabilization', 'off' );

    % Create save name
    saveName = strrep(fileName,'clean.set','clean_ica');
    
    % Save point
    EEG = pop_saveset( EEG, 'filename', saveName, 'filepath', filePath);

end
