clear; close all; clc;

%##### STEP 7: FILTER, INTERPOLATE CHANNELS, SPLIT CONDITIONS, AVERAGE REFERENCE #####

ID = {'001';'002';'003';'004';'005';'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};
con = {'C1';'C2'};

site = {'pfc';'ppc'};
tms = 'tms';
tr = {'t0';'t1'};
u = '_';
pathIn = 'D:\nmda_tms_eeg\RAW\';
pathOut = 'D:\nmda_tms_eeg\CLEAN4\';

eeglab
for a = 1:size(ID,1)
    for c = 1:size(con,1);
        for b = 1:size(site,1)     

            %Load point
            EEG = pop_loadset( 'filename', [ID{a,1} u con{c,1} u tms u site{b,1} u 'ep_ds_mark_clean_ica1_clean_ica2_clean.set'], 'filepath', [pathOut ID{a,1} filesep con{c,1} filesep]);
            
            %Interpolate removed data
            EEG = pop_tesa_interpdata( EEG, 'linear' );

            %Bandpass (1-100 Hz) and bandstop (48-52 Hz) filter data
            EEG = pop_tesa_filtbutter( EEG, 1, 100, 4, 'bandpass' ); 
            EEG = pop_tesa_filtbutter( EEG, 48, 52, 4, 'bandstop' );
            
            %Save point
            EEG = pop_saveset( EEG, 'filename', [ID{a,1} u con{c,1} u tms u site{b,1} u 'ep_ds_mark_clean_ica1_clean_ica2_clean_filt'], 'filepath', [pathOut ID{a,1} filesep con{c,1} filesep]);

            %Interpolate missing channels
            EEG = pop_interp(EEG, EEG.allchan, 'spherical');

            %Extract time 0
            EEG1 = pop_selectevent( EEG, 'type',{'t0'},'deleteevents','on','deleteepochs','on','invertepochs','off');
            EEG1 = pop_saveset( EEG1, 'filename', [ID{a,1} u con{c,1} u tms u site{b,1} u 'FINAL_T0'],'filepath',[pathOut ID{a,1} filesep con{c,1} filesep]);

            %Reference to average
            EEG1av = pop_reref( EEG1, []);
            EEG1av = pop_saveset( EEG1av, 'filename', [ID{a,1} u con{c,1} u tms u site{b,1} u 'FINAL_T0_avref'],'filepath',[pathOut ID{a,1} filesep con{c,1} filesep]);

            %Extract time 1
            EEG2 = pop_selectevent( EEG, 'type',{'t1'},'deleteevents','on','deleteepochs','on','invertepochs','off');
            EEG2 = pop_saveset( EEG2, 'filename', [ID{a,1} u con{c,1} u tms u site{b,1} u 'FINAL_T1'],'filepath',[pathOut ID{a,1} filesep con{c,1} filesep]);

            %Rereference to average
            EEG2av = pop_reref( EEG2, []);
            EEG2av = pop_saveset( EEG2av, 'filename', [ID{a,1} u con{c,1} u tms u site{b,1} u 'FINAL_T1_avref'],'filepath',[pathOut ID{a,1} filesep con{c,1} filesep]);

        end
    end
end