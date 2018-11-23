clear; close all; clc;

%##### STEP 2: REMOVE BAD TRIALS, CHECK BAD ELECTRODES #####

% ID = {'001';'002';'003';'004';'005';'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};
% con = {'C1';'C2'};

ID = {'014'};
con = {'C1'};

site = {'ppc'};
% site = {'pfc';'ppc'};
tms = 'tms';
% tr = {'t0';'t1'};
tr = {'t0'};
u = '_';
pathIn = 'H:\nmda_tms_eeg\RAW\';
pathOut = 'H:\nmda_tms_eeg\CLEAN4\';

eeglab

for a = 1:size(ID,1)
    for c = 1:size(con,1);
        for b = 1:size(site,1)
        
            tic
            %Load point
            EEG = pop_loadset( 'filename', [ID{a,1} u con{c,1} u tms u site{b,1} u 'ep_ds.set'], 'filepath', [pathOut ID{a,1} filesep con{c,1} filesep]);

            %Remove first 5 trials of each epoch
            for d = 1:size(EEG.event,2)
                if strcmp(EEG.event(d).type,'t1')
                    break
                end
            end
            EEG = pop_select( EEG,'notrial',[d:d+4]);
            EEG = pop_select( EEG,'notrial',[1:5] );

            %Remove bad trials
            EEG = pop_rejkurt(EEG,1,[1:EEG.nbchan] ,5,5,2,0);
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
            EEG = pop_saveset( EEG, 'filename', [ID{a,1} u con{c,1} u tms u site{b,1} u 'ep_ds_mark_clean'], 'filepath', [pathOut ID{a,1} filesep con{c,1} filesep]);
            
            close all;
            
            toc
        end
    end
end
