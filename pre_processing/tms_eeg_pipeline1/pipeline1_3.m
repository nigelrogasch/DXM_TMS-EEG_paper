% scriptForBatch.m
% This script here makes it so that we can save some stuff for the batch script

% Set up for MASSIVE (super computer)
wes = getenv('number');
wes = str2num(wes);
% wes = 1;

%###### STEP 3: RUN SOUND (REPLACE MISSING CHANNELS), RUN ICA #####

ID = {'001';'002';'004';'005';'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};
con = {'C1';'C2'};
site = {'pfc';'ppc'};
tms = 'tms';
tr = {'t0';'t1'};
u = '_';

% SET UP PATHS FOR DATA
pathData = '/projects/kg98/Nigel/TMS-EEG_NMDA/data/';
pathIn = '/projects/kg98/Nigel/TMS-EEG_NMDA/data/step2/';
pathOut = '/projects/kg98/Nigel/TMS-EEG_NMDA/data/step3/';
pathLfData = '/projects/kg98/Nigel/TMS-EEG_NMDA/data/ANAT/';

%Makes a path folder
if ~isequal(exist(pathOut, 'dir'),7)
    mkdir(pathOut);
end

%% PREP FOR PARFOR LOOP
for a = 1:size(ID,1) % Loop over participants
    for c = 1:size(con,1) % Loop over conditions
        
        %Makes a subject folder
        if ~isequal(exist([pathOut,ID{a,1}], 'dir'),7)
            mkdir(pathOut,ID{a,1});
        end
        
        %Makes a condition folder
        if ~isequal(exist([pathOut,ID{a,1},filesep,con{c,1}], 'dir'),7)
            mkdir([pathOut,ID{a,1},filesep],con{c,1});
        end
        
        for b = 1:size(site,1) % Loop over open/closed
            for x = 1:size(tr,1)  % Loop over time points
                
                tempFilePathIn{a,c,b,x} = [pathIn ID{a,1} filesep con{c,1} filesep];
                tempFileNameIn{a,c,b,x} = [ID{a,1} u con{c,1} u tms u site{b,1} u tr{x,1} u 'ep_bc_ica1_clean.set'];
                tempFilePathOut{a,c,b,x} = [pathOut ID{a,1} filesep con{c,1} filesep];
                tempFileNameOut{a,c,b,x} = [ID{a,1} u con{c,1} u tms u site{b,1} u tr{x,1} u 'ep_bc_ica1_clean_sound_ica2.set'];
                templfPathIn{a,c,b,x} = [pathLfData,ID{a,1},filesep];
                
            end
        end
    end
end

% Reshape name structures for loop
filePathIn = reshape(tempFilePathIn,1,[]);
fileNameIn = reshape(tempFileNameIn,1,[]);
filePathOut = reshape(tempFilePathOut,1,[]);
fileNameOut = reshape(tempFileNameOut,1,[]);
lfPathIn = reshape(templfPathIn,1,[]);

% Load all channel file
load([pathData,'allChan.mat']);

%% RUN PIPELINE
tic;

restCleaningStep2(filePathIn{wes},fileNameIn{wes},filePathOut{wes},fileNameOut{wes},lfPathIn{wes},allChan,allChanLocs);
fprintf('%s complete\n',fileNameOut{wes});

timeForAnalysis = toc/60;

%% FUNCTION FOR PARFOR LOOP

function restCleaningStep2(filePathIn,fileNameIn,filePathOut,fileNameOut,lfPathIn,allChan,allChanLocs)

    
    % Load EEG data
    EEG = pop_loadset('filename', fileNameIn, 'filepath', filePathIn);
    
    % Load individual leadfield matrix
    load([lfPathIn,'headmodel_surf_openmeeg_02.mat']);
    
    % Load leadfield matrix channel order
    load([lfPathIn,'channel.mat']);
    
    % Work out good and bad channels
    EEG.allChan = allChan;
    currentChan = {EEG.chanlocs.labels};
    EEG.goodC = ismember(allChan,currentChan);
    EEG.badC = EEG.goodC == 0;
    EEG.badCName = allChan(EEG.badC);
    
    % Reorder the leadfield matrix to match the EEGLAB data
    eeglabChan = allChan;
    brainstormChan = {Channel.Name};
    for i = 1:size(allChan,2)
        [~,chanIndex(i)] = ismember(lower(eeglabChan{i}),lower(brainstormChan));
    end
    LFM_ind = Gain(chanIndex,:);
    
    % Calculate the leadfields
    LFM_ind_2_ICA = LFM_ind(EEG.goodC,:); % With bad channel removed
    LFM_ind_ave = ref_ave(LFM_ind); % With all channels
    
    % Average the data across trials
    EEG_tmp = mean(EEG.data,3);
    
    % Re-reference the data and the lead field to the channel with the least noise
    [~, sigmas] = DDWiener(EEG_tmp);
    [~,bestC] = min(sigmas);
    [datatmp] = ref_best(EEG_tmp, bestC);
    [LFM_ind_tmp] = ref_best(LFM_ind_2_ICA, bestC);
    
    % Run the SOUND algorithm:
    iter = 5;
    lambda_value = 0.1;
    chans = setdiff(1:size(EEG_tmp,1),bestC);
    [~, xL, sigmas] = SOUND(datatmp(chans,:), LFM_ind_tmp(chans,:), iter, lambda_value);
    EEG_tmp_correct = LFM_ind_ave*xL;
    
    % Clean up
    clear xL;
    
    [LFM_ind_tmp] = ref_best(LFM_ind_2_ICA, bestC);
    EEG_tmp_trials = zeros(size(LFM_ind,1),size(EEG.data,2),size(EEG.data,3));
    fprintf('Applying SOUND to single trials\n');
    % Apply to single trials
    for k = 1:size(EEG.data,3)
        [datatmp] = ref_best(EEG.data(:,:,k), bestC);
        [corrected_data, x] = correct_with_known_noise(datatmp(setdiff(1:size(datatmp,1),bestC),:),...
            LFM_ind_tmp(setdiff(1:size(datatmp,1),bestC),:), lambda_value,  sigmas);
        EEG_tmp_trials(:,:,k) = LFM_ind_ave*x;
    end
    
    % Clean up after SOUND
    clear LFM_ind LFM_ind2_ICA LFM_ind_ave LFM_ind_tmp x 
    
    % Change EEGLAB data file with new data
    EEG.data = EEG_tmp_trials;
    EEG.nbchan = size(EEG.data,1);
    EEG.chanlocs = allChanLocs;
    
    %Reshapes 3D matrix to 2D
    inMat=reshape(EEG.data,size(EEG.data,1),[],1);
    
    %Checks that number of dimensions is larger than compression value
    covarianceMatrix = cov(inMat', 1);
    [E, D] = eig (covarianceMatrix);
    rankTolerance = 1e-7;
    rankMat = sum (diag (D) > rankTolerance);
    
    EEG.icaact = [];
    EEG.icawinv = [];
    EEG.icasphere = [];
    EEG.icaweights = [];
    EEG.icachansind = [];
    
    % Clean up
    clear inMat
    
    % Run ICA
    EEG = ICA_analysis(EEG,EEG.data,rankMat);% run ICA using the runica method from EEGlab
    
    % Save data
    EEG = pop_saveset( EEG, 'filename', fileNameOut,'filepath',filePathOut);
    
end

function [corrected_data, x] = correct_with_known_noise(data, LFM,lambda0,  sigmas)
% This function corrects a data segment when the noise distribution is already known.
%
% .........................................................................
% 24 September 2017: Tuomas Mutanen, NBE, Aalto university  
% .........................................................................
    chanN = length(sigmas);
    W = diag(1./sigmas);
    WL = W*LFM;
    clear LFM;
    WLLW = WL*WL';
    x = WL'*((WLLW + lambda0*trace(WLLW)/chanN*eye(chanN))\(W*data));
    corrected_data = [];

end
