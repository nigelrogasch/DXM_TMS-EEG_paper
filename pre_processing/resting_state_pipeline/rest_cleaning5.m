clear; close all; clc;

%##### STEP 5: EXTRACT TIME POINTS, RE-REFERENCE #####

%% SETTINGS AND FILE PATHS/NAMES

% Participant IDs
ID = {'001';'002';'003';'004';'005';'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};

% Conditions
con = {'C1';'C2'};
triggers = {'t0_open';'t0_closed';'t1_open';'t1_closed'};

% Underscore
u = '_';

% Paths
pathIn = 'I:\nmda_tms_eeg\REST_CLEAN1\';
pathOut = 'I:\nmda_tms_eeg\REST_CLEAN1\';

% Create cell array with file paths and names
for a = 1:size(ID,1)
    for c = 1:size(con,1)
        
        filePathTemp{a,c} = [pathIn ID{a,1} filesep con{c,1} filesep];
        fileNameTemp{a,c} = [ID{a,1} u con{c,1} 'ds_filt_ep_clean_ica_clean.set'];
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
    restCleaningStep5(filePath{x},fileName{x},triggers);
    fprintf('%s %s is finished\n',fileID{x},fileCon{x});
end

%% FUNCTION FOR LOADING DATA, RUNNING ICA
function restCleaningStep5(filePath,fileName,triggers)

    % Load data
    EEG = pop_loadset('filename', fileName, 'filepath', filePath);
    
    for x = 1:length(triggers)
        %Extract time points
        EEG1 = pop_selectevent( EEG, 'type',{triggers{x,1}},'deleteevents','on','deleteepochs','on','invertepochs','off');
        
        %Create save name
        saveName1 = strrep(fileName,'ds_filt_ep_clean_ica_clean.set',['_',triggers{x,1},'_final_fcz']);
        EEG1 = pop_saveset( EEG1, 'filename', saveName1,'filepath',filePath);

        %Reference to average
        EEG1av = pop_reref( EEG1, []);
        saveName2 = strrep(fileName,'ds_filt_ep_clean_ica_clean.set',['_',triggers{x,1},'_final_av']);        
        EEG1av = pop_saveset( EEG1av, 'filename', saveName2,'filepath',filePath);

    end

end

            