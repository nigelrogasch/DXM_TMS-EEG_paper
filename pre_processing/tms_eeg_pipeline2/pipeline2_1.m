clear; close all; clc;

%###### STEP 1: CONVERT, EPOCH, REMOVE TMS ARTIFACT, DOWNSAMPLE, REMOVE TRIALS, REMOVE CHANNELS, RUN FASTICA #####

% Note that the following need redoing:
% 001, (C2 - wrong ID name)
% 003, (C2 - wrong ID name) 
% 007, (C1 - wrong ID name)
% 008, (C1 - wrong condition name, C2 - wrong ID name)
% 014, (C1,ppc,t0 - ppc2 has most trials)

ID = {'001';'002';'003';'004';'005';'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};
con = {'C1';'C2'};
site = {'pfc';'ppc'};
tms = 'tms';
tr = {'t0';'t1'};
u = '_';

% Location of 'sound_final' file
pathIn = 'I:\nmda_tms_eeg\RAW\';
pathOut = 'I:\nmda_tms_eeg\CLEAN_ICA\';
path2 = 'I:\nmda_tms_eeg\CLEAN\';

eeglab

for a = 1:size(ID,1)
    for c = 1:size(con,1)
    
        %Makes a subject folder
        if ~isequal(exist([pathOut,ID{a,1}], 'dir'),7)
            mkdir(pathOut,ID{a,1});
        end

        %Makes a condition folder
        if ~isequal(exist([pathOut,ID{a,1},filesep,con{c,1}], 'dir'),7)
            mkdir([pathOut,ID{a,1},filesep],con{c,1});
        end
        
        for b = 1:size(site,1)
            for x = 1:size(tr,1)

                % Load file
                if strcmp(ID{a,1},'001') && strcmp(con{c,1},'C2')% 001 C2
                    con2 = {'s1'};
                    tr2 = {'t1';'t2'};
                    EEG = pop_loadbv([pathIn ID{a,1} filesep con{c,1} filesep], ['HeGa' u con2{1,1} u tr2{x,1} u site{b,1} u tms '.vhdr']);
                elseif strcmp(ID{a,1},'003') && strcmp(con{c,1},'C2')% 003 C2
                    EEG = pop_loadbv([pathIn ID{a,1} filesep con{c,1} filesep], ['002' u con{c,1} u tr{x,1} u tms u site{b,1} '.vhdr']);
                elseif strcmp(ID{a,1},'007') && strcmp(con{c,1},'C1')% 007 C1
                    EEG = pop_loadbv([pathIn ID{a,1} filesep con{c,1} filesep], ['008' u 'C2' u tr{x,1} u tms u site{b,1} '.vhdr']);
                elseif strcmp(ID{a,1},'008') && strcmp(con{c,1},'C1')% 008 C1  
                    EEG = pop_loadbv([pathIn ID{a,1} filesep con{c,1} filesep], [ID{a,1} u 'C2' u tr{x,1} u tms u site{b,1} '.vhdr']);
                elseif strcmp(ID{a,1},'008') && strcmp(con{c,1},'C2') % 008 C2 
                    EEG = pop_loadbv([pathIn ID{a,1} filesep con{c,1} filesep], ['002' u con{c,1} u tr{x,1} u tms u site{b,1} '.vhdr']);
                elseif strcmp(ID{a,1},'014') && strcmp(con{c,1},'C1') && strcmp(site{b,1},'ppc') && strcmp(tr{x,1},'t0') % 014 C1 ppc t0
                    EEG = pop_loadbv([pathIn ID{a,1} filesep con{c,1} filesep], [ID{a,1} u con{c,1} u tr{x,1} u tms u 'ppc2' '.vhdr']);
                else
                    EEG = pop_loadbv([pathIn ID{a,1} filesep con{c,1} filesep], [ID{a,1} u con{c,1} u tr{x,1} u tms u site{b,1} '.vhdr']);
                end
                
                %Load channel locations
                EEG = pop_chanedit(EEG,  'lookup', 'standard-10-5-cap385.elp');

                %Remove eye electrodes
                EEG = pop_select(EEG,'nochannel',{'31','32'});

                %Save channels
                EEG.allchan = EEG.chanlocs;

                % Epoch
                EEG = pop_epoch( EEG, {  'R128'  }, [-1.5  1.5], 'epochinfo', 'yes');

                % Demean data (ignoring data around TMS pulse)
                EEG = pop_rmbase( EEG, [-1000  -10]);

                %Remove TMS artifact
                EEG = tesa_removedata(EEG,[-2,10]);

                %Interpolate removed data
                EEG = pop_tesa_interpdata( EEG, 'cubic', [1,1]);

                %Downsample
                EEG = pop_resample( EEG, 1000);

                %Rename events specific for trial    
                for y = 1:size(EEG.event,2)
                    if strcmp('R128',EEG.event(y).type)
                        EEG.event(y).type = tr{x,1};
                    end
                end

            %Store the data
                [ALLEEG, EEG, CURRENTSET]=eeg_store(ALLEEG,EEG,x);
            end

            %Merge trials for two time sessions
            EEG = pop_mergeset(ALLEEG, 1:size(tr,1), 0);
            
            %Remove first 5 trials of each epoch
            for d = 1:size(EEG.event,2)
                if strcmp(EEG.event(d).type,'t1')
                    break
                end
            end
            EEG = pop_select( EEG,'notrial',[d:d+4]);
            EEG = pop_select( EEG,'notrial',[1:5] );
            
            %Load existing data with trials removed
            EEG1 = pop_loadset( 'filename', [ID{a,1} u con{c,1} u tms u site{b,1} u 'ep_ds_mark_clean.set'], 'filepath', [path2 ID{a,1} filesep con{c,1} filesep]);
            
            %Remove same trials from this data set
            EEG = pop_select( EEG,'notrial',EEG1.BadTr );
            EEG.BadTr = EEG1.BadTr;
            
            %Remove same channels from this data set
            EEG = pop_select( EEG,'nochannel',EEG1.badChan);
            EEG.badChan = EEG1.badChan;
            
            %Remove TMS pulse artifact 
            EEG = pop_tesa_removedata( EEG, [-2 10] );
            
            %Run FastICA (round 1)
            EEG = pop_tesa_fastica( EEG, 'approach', 'symm', 'g', 'tanh', 'stabilization', 'off' );

            %Save point
            EEG = pop_saveset( EEG, 'filename', [ID{a,1} u con{c,1} u tms u site{b,1} u 'ep_bc_ds_clean_ica1'],'filepath',[pathOut ID{a,1} filesep con{c,1} filesep]);
        
            fprintf([ID{a,1},' ',con{c,1},' ',site{b,1},' is finished\n']);
        end
    end
end
        