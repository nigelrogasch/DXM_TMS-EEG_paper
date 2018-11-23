clear; close all; clc;

%###### STEP 1: CONVERT, EPOCH, REMOVE TMS ARTIFACT, DOWNSAMPLE #####

% Note that the following need redoing:
% 001, (C2 - wrong name)
% 003, (C2 - wrong name) 
% 007, (C1 - wrong name)
% 008, (C1 - wrong name, C2 - wrong name)

ID = {'002';'004';'005';'006';'009';'010';'011';'012';'013';'014';'015'};
con = {'C1';'C2'};

site = {'pfc';'ppc'};
tms = 'tms';
tr = {'t0';'t1'};
u = '_';
pathIn = 'H:\nmda_tms_eeg\RAW\';
pathOut = 'H:\nmda_tms_eeg\CLEAN1\';

eeglab

for a = 1:size(ID,1)
    for c = 1:size(con,1);
    
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
%                 EEG = pop_loadbv([pathIn ID{a,1} filesep con{c,1} filesep], [ID{a,1} u con{c,1} u tr{x,1} u tms u site{b,1} '.vhdr']);
                
                % 001 C2
%                 con2 = {'s1'};
%                 tr2 = {'t1';'t2'};
%                 EEG = pop_loadbv([pathIn ID{a,1} filesep con{c,1} filesep], ['HeGa' u con2{c,1} u tr2{x,1} u site{b,1} u tms '.vhdr']);
                
                % 003 C2
%                   EEG = pop_loadbv([pathIn ID{a,1} filesep con{c,1} filesep], ['002' u con{c,1} u tr{x,1} u tms u site{b,1} '.vhdr']);

                % 007 C1
%                   EEG = pop_loadbv([pathIn ID{a,1} filesep con{c,1} filesep], ['002' u 'C2' u tr{x,1} u tms u site{b,1} '.vhdr']);
                
                % 008 C1  
%                 EEG = pop_loadbv([pathIn ID{a,1} filesep con{c,1} filesep], [ID{a,1} u 'C2' u tr{x,1} u tms u site{b,1} '.vhdr']);

                % 008 C2  
                EEG = pop_loadbv([pathIn ID{a,1} filesep con{c,1} filesep], [ID{a,1} u 'C1' u tr{x,1} u tms u site{b,1} '.vhdr']);

                
                %Load channel locations
                EEG = pop_chanedit(EEG,  'lookup', 'standard-10-5-cap385.elp');

                %Remove eye electrodes
                EEG = pop_select(EEG,'nochannel',{'31','32'});

                %Save channels
                EEG.allchan = EEG.chanlocs;

                %Automatic removal of bad electrodes
                EEG = pop_rejchan(EEG, 'elec',[1:size(EEG.data,1)] ,'threshold',5,'norm','on','measure','kurt');

                % Epoch
                EEG = pop_epoch( EEG, {  'R128'  }, [-1.5  1.5], 'epochinfo', 'yes');

                % Demean data
                EEG = pop_rmbase( EEG, [-1500  1500]);

                %Remove TMS artifact
                EEG = tesa_removedata(EEG,[-2,15]);

                %Interpolate removed data
                EEG = pop_tesa_interpdata( EEG, 'linear' );

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

            %Check that electrodes match
            z1 = extractfield(ALLEEG(1).chanlocs,'labels');
            z2 = extractfield(ALLEEG(2).chanlocs,'labels');
            miss1 = setdiff(z1,z2);
            miss2 = setdiff(z2,z1);
            
            if ~isempty(miss1)
                ALLEEG(1) = pop_select( ALLEEG(1),'nochannel',miss1);
            end
            if ~isempty(miss2)
                ALLEEG(2) = pop_select( ALLEEG(2),'nochannel',miss2);
            end

            %Merge trials for two time sessions
            EEG = pop_mergeset(ALLEEG, 1:size(tr,1), 0);

            %Save point
            EEG = pop_saveset( EEG, 'filename', [ID{a,1} u con{c,1} u tms u site{b,1} u 'ep_ds'],'filepath',[pathOut ID{a,1} filesep con{c,1} filesep]);
        
        end
    end
end
        