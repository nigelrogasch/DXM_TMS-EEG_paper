clear; close all; clc;

%##### STEP 4: REMOVE BAD COMPONENTS #####

ID = {'001';'002';'003';'004';'005';'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};
con = {'C1';'C2'};
u = '_';
pathIn = 'I:\nmda_tms_eeg\REST_CLEAN1\';
pathOut = 'I:\nmda_tms_eeg\REST_CLEAN1\';

eeglab

for a = 1:size(ID,1)
    for c = 1:size(con,1)
        
        %Load point
        EEG = pop_loadset( 'filename', [ID{a,1} u con{c,1} 'ds_filt_ep_clean_ica.set'], 'filepath', [pathIn ID{a,1} filesep con{c,1} filesep]);
        
        %Remove bad components
        EEG = pop_tesa_compselect( EEG,'comps',[],'figSize','small','plotTimeX',[0 1999],'plotFreqX',[1 100],'tmsMuscle','off','tmsMuscleThresh',8,'tmsMuscleWin',[11 30],'tmsMuscleFeedback','off','blink','on','blinkThresh',2.5,'blinkElecs',{'Fp1','Fp2'},'blinkFeedback','off','move','on','moveThresh',2,'moveElecs',{'F7','F8'},'moveFeedback','off','muscle','on','muscleThresh',0.6,'muscleFreqWin',[30 100],'muscleFeedback','off','elecNoise','off','elecNoiseThresh',6,'elecNoiseFeedback','off' );

        %Save point
        EEG = pop_saveset( EEG, 'filename', [ID{a,1} u con{c,1} 'ds_filt_ep_clean_ica_clean'], 'filepath', [pathOut ID{a,1} filesep con{c,1} filesep]);
        
        fprintf('%s %s complete\n',ID{a,1},con{c,1});
        
    end
end