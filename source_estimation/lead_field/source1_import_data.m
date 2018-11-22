clear; clc;

% ##### STEP 1: IMPORT THE FREESURFER DATA AND EEGLAB FILES #####

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

% Data path
pathData = 'I:\nmda_tms_eeg\CLEAN_ICA\';

% Anatomy path
pathAnat = 'I:\nmda_tms_eeg\FREESURFER\';

% % Electrode path
% pathElec = 'I:\TMS-EEG_hubs\data\';
% % Electrode file suffix
% sufElec = '_electrode_positions.xlsx';

% Brainstorm data path
pathBS = 'F:\brainstorm_db\TMS-EEG_NMDA\data\';

% ##### INITIATE BRAINSTORM #####

% Initiate Brainstorm GUI
if ~brainstorm('status')
    brainstorm nogui
end

% The protocol name has to be a valid folder name (no spaces, no weird characters...)
ProtocolName = 'TMS-EEG_NMDA';

% Delete the protocol?
deleteProt = 'no'; % 'yes' | 'no'

% If starting from the first subject: delete the protocol
if strcmp(deleteProt,'yes')
    % Delete existing protocol
    gui_brainstorm('DeleteProtocol', ProtocolName);
    % Create new protocol
    gui_brainstorm('CreateProtocol', ProtocolName, 0, 0);
else
    % Get the protocol index
    iProtocol = bst_get('Protocol', ProtocolName);
    if isempty(iProtocol)
        error(['Unknown protocol: ' ProtocolName]);
    end
    % Select the current procotol
    gui_brainstorm('SetCurrentProtocol', iProtocol);
end

% ##### RUN SCRIPT #####

for iSubj = iSubjStart:length(SubjectNames)
    
    % Start a new report (one report per subject)
    bst_report('Start');

    % If subject already exists: delete it
    [sSubject, iSubject] = bst_get('Subject', SubjectNames{iSubj});
    if ~isempty(sSubject)
        db_delete_subjects(iSubject);
    end

    % ===== IMPORT ANATOMY =====
    AnatDir = [pathAnat,ID{iSubj,1},filesep];
    % Process: Import anatomy folder
    bst_process('CallProcess', 'process_import_anatomy', [], [], ...
    'subjectname', SubjectNames{iSubj}, ...
    'mrifile',     {AnatDir, 'FreeSurfer'}, ...
    'nvertices',   15000);

    % =====  Compute MNI transformation ===== 
    % Input files
    sFilesMNI = [];
    sFilesMNI = bst_process('CallProcess', 'process_mni_affine', sFilesMNI, [], ...
        'subjectname', SubjectNames{iSubj});
    
    % ===== IMPORT EEGLAB FILE =====
    for conx = 1:size(con,1)
        for sitex = 1:size(site,1)
            for trx = 1:size(tr,1)
                DataFile = [pathData,ID{iSubj,1},filesep,con{conx},filesep,ID{iSubj,1},'_',con{conx},'_tms_',site{sitex},'_FINAL_',tr{trx},'_avref.set'];
                % Import file
                sFileEp.(con{conx}).(site{sitex}).(tr{trx}) = bst_process('CallProcess', 'process_import_data_epoch', [], [], ...
                    'subjectname',    SubjectNames{iSubj}, ...
                    'datafile',       {DataFile, 'EEG-EEGLAB'}, ...
                    'baseline', []);
            end
        end
    end
    
    save([pathData,ID{iSubj,1},filesep,'bs_settings'],'sFileEp');
    
    fprintf('%s complete\n',ID{iSubj,1})
    
end

