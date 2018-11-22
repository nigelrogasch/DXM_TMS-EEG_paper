clear; clc;

% ##### STEP 3: UPDATE THE ELECTRODE POSITIONS FOR ALL OTHER CONDITIONS #####
% Note: this step is a little redundant as we use the head model from the
% first condition only (the head model is identical for all conditions)

% ##### SETTINGS #####

% Subject ID
ID = {'001';'002';'004';'005';'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};

% Full list of subjects to process
for x = 1:length(ID)
    SubjectNames{x,1} = ['sub',ID{x,1}];
end

% Subject to start
iSubjStart = 1;

% Conditions
con = {'C1';'C2'};
site = {'pfc';'ppc'};
tms = 'tms';
tr = {'T0';'T1'};
u = '_';

% Use default or individual electrode positions?
elecUse = 'individual'; % default | individual

% Set fiducials on MRI?
setFid = 'no'; % 'yes' | 'no'

% Automatically project on head?
setAlign = 'no'; % 'yes' | 'no'

% Data path
pathData = 'I:\nmda_tms_eeg\CLEAN_ICA\';

% Electrode path
pathElec = 'I:\nmda_tms_eeg\ELECTRODE_POSITIONS\';

% Brainstorm data path
pathBS = 'F:\brainstorm_db\TMS-EEG_NMDA\data\';

% Brainstorm data path
pathBSanat = 'F:\brainstorm_db\TMS-EEG_NMDA\anat\';

% ##### INITIATE BRAINSTORM #####

% Initiate Brainstorm GUI
if ~brainstorm('status')
    brainstorm nogui
end

% The protocol name has to be a valid folder name (no spaces, no weird characters...)
ProtocolName = 'TMS-EEG_NMDA';

% Get the protocol index
iProtocol = bst_get('Protocol', ProtocolName);
if isempty(iProtocol)
    error(['Unknown protocol: ' ProtocolName]);
end
% Select the current procotol
gui_brainstorm('SetCurrentProtocol', iProtocol);

% ##### RUN SCRIPT #####

for iSubj = iSubjStart:length(SubjectNames)
        
    % Load sFileEp
    load([pathData,ID{iSubj,1},filesep,'bs_settings.mat']);
    
        % Update all other conditions
    for i = 1:length(con)
        for j = 1:length(site)
            for k = 1:length(tr)
                
                if i ~=1 || j ~= 1 || k ~= 1
                
                    %Set condition to automatically alter electrodes
                    OutputFile = [pathBS,SubjectNames{iSubj,1},filesep,ID{iSubj,1},'_',con{1},'_tms_',site{1},'_FINAL_',tr{1},'_avref',filesep,'channel.mat'];

                    RawFiles = {OutputFile};
                    sFiles = sFileEp.(con{i,1}).(site{j,1}).(tr{k,1});
                    sFiles = bst_process('CallProcess', 'process_channel_addloc', sFiles, [], ...
                        'channelfile', {RawFiles{1}, 'BST'}, ...
                        'usedefault',  1);  %

                    % Process: Remove head points
                    sFiles = sFileEp.(con{i,1}).(site{j,1}).(tr{k,1});
                    sFiles = bst_process('CallProcess', 'process_headpoints_remove', sFiles, [], 'zlimit', []);
                    
                    % Update channel.mat files
                    delete([pathBS,SubjectNames{iSubj,1},filesep,ID{iSubj,1},'_',con{i},'_tms_',site{j},'_FINAL_',tr{k},'_avref',filesep,'channel.mat'])
                    load([pathBS,SubjectNames{iSubj,1},filesep,ID{iSubj,1},'_',con{1},'_tms_',site{1},'_FINAL_',tr{1},'_avref',filesep,'channel.mat'])
                    save([pathBS,SubjectNames{iSubj,1},filesep,ID{iSubj,1},'_',con{i},'_tms_',site{j},'_FINAL_',tr{k},'_avref',filesep,'channel.mat'])
                    Channel=[];
                    
                end
            end
        end
    end
    
end