clear; close all; clc;

%###### STEP 2: REMOVE TMS-EVOKED MUSCLE, DECAY COMPONENTS #####

ID = {'001';'002';'003';'004';'005';'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};
con = {'C1';'C2'};
site = {'pfc';'ppc'};
tms = 'tms';
tr = {'t0';'t1'};
u = '_';

% Return which computer is running
currentComp = getenv('computername');

% Location of 'sound_final' file
pathIn = 'I:\nmda_tms_eeg\RAW\';
pathOut = 'I:\nmda_tms_eeg\CLEAN_ICA\';

eeglab

for a = 1:size(ID,1)
    for c = 1:size(con,1)
        for b = 1:size(site,1)
            
            %Load data
            EEG = pop_loadset('filename', [ID{a,1} u con{c,1} u tms u site{b,1} u 'ep_bc_ds_clean_ica1.set'], 'filepath', [pathOut ID{a,1} filesep con{c,1} filesep]);
            
            %Remove 
            EEG = pop_tesa_compselect( EEG,'comps',10,'figSize','small','plotTimeX',[-200 500],'plotFreqX',[1 100],'tmsMuscle','on','tmsMuscleThresh',8,'tmsMuscleWin',[16 30],'tmsMuscleFeedback','off','blink','off','blinkThresh',2.5,'blinkElecs',{'Fp1','Fp2'},'blinkFeedback','off','move','off','moveThresh',2,'moveElecs',{'F7','F8'},'moveFeedback','off','muscle','off','muscleThresh',0.6,'muscleFreqWin',[30 100],'muscleFeedback','off','elecNoise','off','elecNoiseThresh',4,'elecNoiseFeedback','off' );
            
            %Save point
            EEG = pop_saveset( EEG, 'filename', [ID{a,1} u con{c,1} u tms u site{b,1} u 'ep_bc_ds_clean_ica1_clean'], 'filepath', [pathOut ID{a,1} filesep con{c,1} filesep]);
            
        end
    end
end