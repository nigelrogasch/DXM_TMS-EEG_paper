clear; close all; clc;

%##### STEP 6: REMOVE ALL OTHER ARTIFACTS #####

% ID = {'001';'002';'003';'004';'005';'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};
ID = {'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};
con = {'C1';'C2'};

site = {'pfc';'ppc'};
tms = 'tms';
tr = {'t0';'t1'};
u = '_';
pathIn = 'H:\nmda_tms_eeg\RAW\';
pathOut = 'H:\nmda_tms_eeg\CLEAN4\';

eeglab

for a = 1:size(ID,1)
    for c = 1:size(con,1);
        for b = 1:size(site,1)
            
            %Load data
            EEG = pop_loadset('filename', [ID{a,1} u con{c,1} u tms u site{b,1} u 'ep_ds_mark_clean_ica1_clean_ica2.set'], 'filepath', [pathOut ID{a,1} filesep con{c,1} filesep]);
            
            %Run FastICA (round 1)
            EEG = pop_tesa_compselect( EEG,'comps',[],'figSize','small','plotTimeX',[-200 500],'plotFreqX',[1 100],'tmsMuscle','on','tmsMuscleThresh',8,'tmsMuscleWin',[11 30],'tmsMuscleFeedback','off','blink','on','blinkThresh',2.5,'blinkElecs',{'Fp1','Fp2'},'blinkFeedback','off','move','on','moveThresh',2,'moveElecs',{'F7','F8'},'moveFeedback','off','muscle','on','muscleThresh',0.6,'muscleFreqWin',[30 100],'muscleFeedback','off','elecNoise','on','elecNoiseThresh',4,'elecNoiseFeedback','off' );
            
            %Save point
            EEG = pop_saveset( EEG, 'filename', [ID{a,1} u con{c,1} u tms u site{b,1} u 'ep_ds_mark_clean_ica1_clean_ica2_clean'], 'filepath', [pathOut ID{a,1} filesep con{c,1} filesep]);
            
        end
    end
end