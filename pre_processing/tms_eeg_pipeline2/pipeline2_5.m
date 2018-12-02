clear; close all; clc;

%###### STEP 5: EXTRACT TIME EPOCHS, REREFERENCE TO AVERAGE #####

ID = {'001';'002';'003';'004';'005';'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};
con = {'C1';'C2'};
site = {'pfc';'ppc'};
tms = 'tms';
tr = {'t0';'t1'};
u = '_';

pathIn = 'I:\nmda_tms_eeg\RAW\';
pathOut = 'I:\nmda_tms_eeg\CLEAN_ICA\';

eeglab

for a = 1:size(ID,1)
    for c = 1:size(con,1)
        for b = 1:size(site,1)
            
            %Load data
            EEG = pop_loadset('filename', [ID{a,1} u con{c,1} u tms u site{b,1} u 'ep_bc_ds_clean_ica1_clean_ica2_clean.set'], 'filepath', [pathOut ID{a,1} filesep con{c,1} filesep]);
            
            %Interpolate removed data
            EEG = pop_tesa_interpdata( EEG, 'cubic', [3,3]);
            
            %Interpolate missing channels
            EEG = pop_interp(EEG, EEG.allchan, 'spherical');

            %Extract time 0
            EEG1 = pop_selectevent( EEG, 'type',{'t0'},'deleteevents','on','deleteepochs','on','invertepochs','off');

            %Reference to average
            EEG1av = pop_reref( EEG1, []);
            EEG1av = pop_saveset( EEG1av, 'filename', [ID{a,1} u con{c,1} u tms u site{b,1} u 'FINAL_T0_avref'],'filepath',[pathOut ID{a,1} filesep con{c,1} filesep]);

            %Extract time 1
            EEG2 = pop_selectevent( EEG, 'type',{'t1'},'deleteevents','on','deleteepochs','on','invertepochs','off');

            %Rereference to average
            EEG2av = pop_reref( EEG2, []);
            EEG2av = pop_saveset( EEG2av, 'filename', [ID{a,1} u con{c,1} u tms u site{b,1} u 'FINAL_T1_avref'],'filepath',[pathOut ID{a,1} filesep con{c,1} filesep]);
            
        end
    end
end