clear; clc;

% ##### SETTINGS #####

% Subject ID
ID = {'001';'002';'003';'004';'005';'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};

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
pathData = 'I:\nmda_tms_eeg\CLEAN_ICA1\';

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
    
    % ===== LOAD ELECTRODE POSITIONS =====
    
    %Set condition to manually alter electrodes
    manCon = con{1};
    manSite = site{1};
    manTr = tr{1};
    sFiles = sFileEp.(manCon).(manSite).(manTr);
        
    % ===== REMOVE FT9, FT10 =====

    % Open brainstorm channel file
    load([pathBS,SubjectNames{iSubj,1},filesep,ID{iSubj,1},'_',manCon,'_tms_',manSite,'_FINAL_',manTr,'_avref',filesep,'channel.mat']);

    % Generate text file
    fid = fopen([pathElec,ID{iSubj,1},'_electrode_pos.txt'],'w');

    % fprintf(fid,'%d\n',62);

    k = 1;
    for i = 1:length(Channel)
        if strcmp(Channel(i).Name,'FT9') || strcmp(Channel(i).Name,'FT10')
        else
            eName{k} = Channel(i).Name;
            chanLocLocalite(k,1) = Channel(i).Loc(1,1);
            chanLocLocalite(k,2) = Channel(i).Loc(2,1);
            chanLocLocalite(k,3) = Channel(i).Loc(3,1);
            k = k+1;
        end
    end

    % Flip the z value
    for i = 1:length(eName)
        fprintf(fid,'%s\t%d\t%d\t%d\n',eName{i},chanLocLocalite(i,1),...
            chanLocLocalite(i,2),chanLocLocalite(i,3));
    end

    fclose(fid);

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
        
