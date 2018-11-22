clear; clc;

% ##### STEP 2: IMPORT THE INDIVIDUALISED ELECTRODE POSITIONS AND ALIGN WITH ANATOMY #####

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
setFid = 'yes'; % 'yes' | 'no'

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
    
    % ===== MANUALLY ALIGN THE FIDUCIALS =====
    if strcmp(setFid,'yes')    
        view_mri([pathBSanat,SubjectNames{iSubj,1},filesep,'subjectimage_T1.mat'], 'EditMri');
        uiwait(msgbox('This message will pause execution until you click OK'));
    end

    % ===== LOAD ELECTRODE POSITIONS =====
    
    %Set condition to manually alter electrodes
    manCon = con{1};
    manSite = site{1};
    manTr = tr{1};
    sFiles = sFileEp.(manCon).(manSite).(manTr);
    
    if strcmp(elecUse,'individual')
        
        % ===== CONVERT LOCALITE FILE TO .TXT FORMAT =====
        convertLocaliteBrainstorm(pathElec,ID{iSubj,1},'_electrode_pos.xml','_electrode_pos.txt')
        
        % ===== IMPORT LOCALITE CHANNEL POSITION FILE =====
        % Process: Add EEG positions
       
        % Use individual electrode positions
        RawFiles = {[pathElec,ID{iSubj,1},'_electrode_pos.txt']};

        % Process: Add EEG positions
        sFiles = bst_process('CallProcess', 'process_import_channel', sFiles, [], ...
        'channelfile', {RawFiles{1}, 'ASCII_NXYZ'}, ...
        'usedefault',  60, ...  % ICBM152: BrainProducts EasyCap 128
        'fixunits',    1, ...
        'vox2ras',     1);
    
    else

        % Use default electrode positions
        RawFiles = {...
        'C:\Users\Nigel\Documents\brainstorm3\defaults\eeg\ICBM152\channel_BrainProducts_EasyCap_128.mat'};

        % Process: Add EEG positions
        sFiles = bst_process('CallProcess', 'process_channel_addloc', sFiles, [], ...
        'channelfile', {RawFiles{1}, 'BST'}, ...
        'usedefault',  60, ...  % ICBM152: BrainProducts EasyCap 128
        'fixunits',    1, ...
        'vox2ras',     1);
    end

    % Process: Remove head points
    sFiles = sFileEp.(manCon).(manSite).(manTr);
    sFiles = bst_process('CallProcess', 'process_headpoints_remove', sFiles, [], 'zlimit', []);
    
    if strcmp(setAlign,'yes')
        % Process: Project electrodes on scalp
        sFiles = bst_process('CallProcess', 'process_channel_project', sFiles, []);
    end
    
    happy = 0;
    
    while happy == 0
    
        % Edit good/bad channel for current file
        channel_align_manual( sFileEp.(manCon).(manSite).(manTr)(1).ChannelFile, 'EEG', 1, 'scalp' );
        uiwait(msgbox('This message will pause execution until you click OK'));

        % Check sensor positions
        % View sensors
        sSubject = bst_get('Subject', SubjectNames{iSubj,1});
        HeadFile = sSubject.Surface(sSubject.iScalp).FileName;
        hFig = view_surface(HeadFile);
        hFig = view_channels(sFiles(1).ChannelFile, 'EEG', 1 , 1 , hFig , 1);

        uiwait(msgbox('This message will pause execution until you click OK'));
        
        if ishandle(hFig)
            close(hFig);
        end
        
        % Construct a questdlg with two options
        choice = questdlg('Are you happy with alignment?', ...
            'Electrode alignment', ...
            'Yes','No','Yes');
        % Handle response
        switch choice
            case 'Yes'
                happy = 1;
            case 'No'
                happy = 0;
        end
        
        
    end
    
%     % Update all other conditions
%     for i = 1:length(con)
%         for j = 1:length(site)
%             for k = 1:length(tr)
%                 
%                 if i ~=1 || j ~= 1 || k ~= 1
%                 
%                     %Set condition to automatically alter electrodes
%                     OutputFile = [pathBS,SubjectNames{iSubj,1},filesep,ID{iSubj,1},'_',con{1},'_tms_',site{1},'_FINAL_',tr{1},'_avref',filesep,'channel.mat'];
% 
%                     RawFiles = {OutputFile};
%                     sFiles = sFileEp.(con{i,1}).(site{j,1}).(tr{k,1});
%                     sFiles = bst_process('CallProcess', 'process_channel_addloc', sFiles, [], ...
%                         'channelfile', {RawFiles{1}, 'BST'}, ...
%                         'usedefault',  1);  %
% 
%                     % Process: Remove head points
%                     sFiles = sFileEp.(con{i,1}).(site{j,1}).(tr{k,1});
%                     sFiles = bst_process('CallProcess', 'process_headpoints_remove', sFiles, [], 'zlimit', []);
%                     
%                 end
%             end
%         end
%     end
        
end
        
