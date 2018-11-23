clear; clc;

% ##### SETTINGS #####

% Subject ID
% ID = {'001';'002';'003';'004';'005';'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};
ID = {'007';'008';'009';'010';'011';'012';'013';'014';'015'};


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
    
    sFilesAv = [];
    sFilesTs = [];
    
    for conx = 1:size(con,1)
        for sitex = 1:size(site,1)
            for trx = 1:size(tr,1)        
                % Process: Compute covariance (noise or data)
                sFileEp.(con{conx}).(site{sitex}).(tr{trx}) = bst_process('CallProcess', 'process_noisecov', sFileEp.(con{conx}).(site{sitex}).(tr{trx}), [], ...
                    'baseline',       [-1, -0.01], ...
                    'datatimewindow', [0, 1], ...
                    'sensortypes',    'EEG', ...
                    'target',         1, ...  % Noise covariance     (covariance over baseline time window)
                    'dcoffset',       1, ...  % Block by block, to avoid effects of slow shifts in data
                    'identity',       0, ...
                    'copycond',       0, ...
                    'copysubj',       0, ...
                    'replacefile',    1);  % Replace
                
                % Process: Average: By trial group (subject average)
                sFileAv.(con{conx}).(site{sitex}).(tr{trx}) = bst_process('CallProcess', 'process_average', sFileEp.(con{conx}).(site{sitex}).(tr{trx}), [], ...
                    'avgtype',    6, ...  % By trial group (subject average)
                    'avg_func',   1, ...  % Arithmetic average:  mean(x)
                    'weighted',   0, ...
                    'keepevents', 0);
                
                % Process: Compute sources [2016]
                sFileAvSrc.(con{conx}).(site{sitex}).(tr{trx}) = bst_process('CallProcess', 'process_inverse_2016', sFileAv.(con{conx}).(site{sitex}).(tr{trx}), [], ...
                    'output',  1, ...  % Kernel only: shared
                    'inverse', struct(...
                    'Comment',        'MN: EEG', ...
                    'InverseMethod',  'minnorm', ...
                    'InverseMeasure', 'amplitude', ...
                    'SourceOrient',   {{'fixed'}}, ...
                    'Loose',          0.2, ...
                    'UseDepth',       1, ...
                    'WeightExp',      0.5, ...
                    'WeightLimit',    10, ...
                    'NoiseMethod',    'reg', ...
                    'NoiseReg',       0.1, ...
                    'SnrMethod',      'fixed', ...
                    'SnrRms',         1e-06, ...
                    'SnrFixed',       3, ...
                    'ComputeKernel',  1, ...
                    'DataTypes',      {{'EEG'}}));
                               
                % Process: Z-score normalization: [-300ms,-10ms]
                sFileZ.(con{conx}).(site{sitex}).(tr{trx}) = bst_process('CallProcess', 'process_baseline_norm',  sFileAvSrc.(con{conx}).(site{sitex}).(tr{trx}), [], ...
                    'baseline',   [-0.300, -0.01], ...
                    'source_abs', 0, ...
                    'method',     'zscore' );   % Z-score transformation:    x_std = (x - ?) / ?
                
                % Process: Project on default anatomy
                sProjSrc.(con{conx}).(site{sitex}).(tr{trx}) = bst_process('CallProcess', 'process_project_sources', sFileZ.(con{conx}).(site{sitex}).(tr{trx}), [], ...
                    'headmodeltype', 'surface');  % Cortex surface
                
                % Process: Spatial smoothing (3.00,abs)
                sProjSrcSmooth.(con{conx}).(site{sitex}).(tr{trx}) = bst_process('CallProcess', 'process_ssmooth_surfstat', sProjSrc.(con{conx}).(site{sitex}).(tr{trx}), [], ...
                    'fwhm',       3, ...
                    'overwrite',  1, ...
                    'source_abs', 1);
                
            end
        end
    end
    
    save([pathData,ID{iSubj,1},filesep,'bs_settings4'],'sFileEp','sFileAv','sFileAvSrc','sFileZ','sProjSrc','sProjSrc');
end
   
                 