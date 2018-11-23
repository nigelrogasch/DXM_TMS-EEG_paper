clear; close all; clc;

%##### STEP 3: RUN FASTICA ROUND 1 #####

ID = {'001';'002';'003';'004';'005';'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};
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
            EEG = pop_loadset('filename', [ID{a,1} u con{c,1} u tms u site{b,1} u 'ep_ds_mark_clean.set'], 'filepath', [pathOut ID{a,1} filesep con{c,1} filesep]);
            
            %Remove TMS pulse artifact 
            EEG = pop_tesa_removedata( EEG, [-2 15] );
            
            %Run FastICA (round 1)
            EEG = pop_tesa_fastica( EEG, 'approach', 'symm', 'g', 'tanh', 'stabilization', 'off' );
            
            %Save point
            EEG = pop_saveset( EEG, 'filename', [ID{a,1} u con{c,1} u tms u site{b,1} u 'ep_ds_mark_clean_ica1'], 'filepath', [pathOut ID{a,1} filesep con{c,1} filesep]);
            
        end
    end
end