clear; close all; clc;

%###### STEP 3: FILTER, FASTICA2 #####

ID = {'001';'002';'003';'004';'005';'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};
con = {'C1';'C2'};
site = {'pfc';'ppc'};
tms = 'tms';
tr = {'t0';'t1'};
u = '_';

% Location of 'sound_final' file
pathIn = 'I:\nmda_tms_eeg\RAW\';
pathOut = 'I:\nmda_tms_eeg\CLEAN_ICA\';

eeglab

for a = 1:size(ID,1)
    for c = 1:size(con,1)
        for b = 1:size(site,1)
            
            %Load data
            EEG = pop_loadset('filename', [ID{a,1} u con{c,1} u tms u site{b,1} u 'ep_bc_ds_clean_ica1_clean.set'], 'filepath', [pathOut ID{a,1} filesep con{c,1} filesep]);
            
            %Interpolate removed data
            EEG = pop_tesa_interpdata( EEG, 'cubic', [3,3]);

            %Bandpass (1-100 Hz) and bandstop (48-52 Hz) filter data
            EEG = pop_tesa_filtbutter( EEG, 1, 100, 4, 'bandpass' ); 
            EEG = pop_tesa_filtbutter( EEG, 48, 52, 4, 'bandstop' );
            
            %Remove TMS pulse artifact 
            EEG = pop_tesa_removedata( EEG, [-2 10] );
            
            %Run FastICA (round 2)
            EEG = pop_tesa_fastica( EEG, 'approach', 'symm', 'g', 'tanh', 'stabilization', 'off' );
            
            %Save point
            EEG = pop_saveset( EEG, 'filename', [ID{a,1} u con{c,1} u tms u site{b,1} u 'ep_bc_ds_clean_ica1_clean_ica2'], 'filepath', [pathOut ID{a,1} filesep con{c,1} filesep]);
            
        end
    end
end