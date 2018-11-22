clear; close all; clc;

%##### STEP 2: REMOVE BAD TRIALS & ELECTRODES #####

ID = {'001';'002';'003';'004';'005';'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};
con = {'C1';'C2'};
u = '_';
pathIn = 'I:\nmda_tms_eeg\REST_CLEAN1\';
pathOut = 'I:\nmda_tms_eeg\REST_CLEAN1\';

eeglab

for a = 1:size(ID,1)
    for c = 1:size(con,1)
        
        %Load point
        EEG = pop_loadset( 'filename', [ID{a,1} u con{c,1} 'ds_filt_ep.set'], 'filepath', [pathIn ID{a,1} filesep con{c,1} filesep]);

        %Remove bad trials
%             EEG = pop_rejkurt(EEG,1,[1:EEG.nbchan] ,5,5,2,0);
        pop_rejmenu( EEG, 1);
        R1=input('Highlight bad trials, update marks and then press enter');
        EEG.BadTr=unique([find(EEG.reject.rejkurt==1) find(EEG.reject.rejmanual==1)]);

        %Reject bad trials
        EEG=pop_rejepoch(EEG,EEG.BadTr,0);

        %Check and remove bad channels
        answer = inputdlg('Enter bad channels', 'Bad channel removal', [1 50]);
        str = answer{1};
        EEG.badChan = strsplit(str);
        close all;
        EEG = pop_select( EEG,'nochannel',EEG.badChan);

        %Save point
        EEG = pop_saveset( EEG, 'filename', [ID{a,1} u con{c,1} 'ds_filt_ep_clean'], 'filepath', [pathOut ID{a,1} filesep con{c,1} filesep]);
        
        fprintf('%s %s complete\n',ID{a,1},con{c,1});
        
        close all;      
           
    end
end