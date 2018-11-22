clear; close all; clc;
%###### STEP 1: CONVERT, EPOCH, REMOVE TMS ARTIFACT, DOWNSAMPLE #####

%% SETTING FILE PATHS AND NAMES

% Note that the following require correction:
% 001, (C2 - wrong name)
% 003, (C2 - wrong name) 
% 006, (C1 - closed misspelt)
% 007, (C1 - wrong name, umlaut used in closed)
% 008, (C1 - wrong name, t0 as to; C2 - wrong name)

ID = {'001';'002';'003';'004';'005';'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};
con = {'C1';'C2'};

site = {'open';'closed'};
tms = 'rest';
tr = {'t0';'t1'};
u = '_';
pathIn = 'I:\nmda_tms_eeg\RAW\';
pathOut = 'I:\nmda_tms_eeg\REST_CLEAN1\';

for a = 1:size(ID,1) % Loop over participants
    for c = 1:size(con,1) % Loop over conditions
        
        %Makes a subject folder
        if ~isequal(exist([pathOut,ID{a,1}], 'dir'),7)
            mkdir(pathOut,ID{a,1});
        end

        %Makes a condition folder
        if ~isequal(exist([pathOut,ID{a,1},filesep,con{c,1}], 'dir'),7)
            mkdir([pathOut,ID{a,1},filesep],con{c,1});
        end

        for b = 1:size(site,1) % Loop over open/closed
            for x = 1:size(tr,1)  % Loop over time points
                
                % Load data
                if strcmp(ID{a,1},'001') && strcmp(con{c,1},'C2')% 001 C2
                    con2 = {'s1'};
                    tr2 = {'t1';'t2'};
                    filePath = [pathIn ID{a,1} filesep con{c,1} filesep];
                    fileName = ['HeGa' u con2{1,1} u tr2{x,1} u tms u site{b,1} '.vhdr'];
                elseif strcmp(ID{a,1},'003') && strcmp(con{c,1},'C2')% 003 C2
                    filePath = [pathIn ID{a,1} filesep con{c,1} filesep];
                    fileName = ['002' u con{c,1} u tr{x,1} u tms u site{b,1} '.vhdr'];
                elseif strcmp(ID{a,1},'006') && strcmp(con{c,1},'C1') && strcmp(tr{x,1},'t1')% 006 C1
                    filePath = [pathIn ID{a,1} filesep con{c,1} filesep];
                    fileName = [ID{a,1} u con{c,1} u tr{x,1} u tms u 'closeed' '.vhdr'];
                elseif strcmp(ID{a,1},'007') && strcmp(con{c,1},'C1')% 007 C1
                    filePath = [pathIn ID{a,1} filesep con{c,1} filesep];
                    fileName = ['002' u 'C2' u tr{x,1} u tms u site{b,1} '.vhdr'];
                elseif strcmp(ID{a,1},'008') && strcmp(con{c,1},'C1')% 008 C1  
                    filePath = [pathIn ID{a,1} filesep con{c,1} filesep];
                    fileName = [ID{a,1} u 'C2' u tr{x,1} u tms u site{b,1} '.vhdr'];
                elseif strcmp(ID{a,1},'008') && strcmp(con{c,1},'C2') % 008 C2
                    if strcmp(tr{x,1},'t0')
                        filePath = [pathIn ID{a,1} filesep con{c,1} filesep];
                        fileName = [ID{a,1} u 'C1' u 'to' u tms u site{b,1} '.vhdr'];
                    else
                        filePath = [pathIn ID{a,1} filesep con{c,1} filesep];
                        fileName = [ID{a,1} u 'C1' u tr{x,1} u tms u site{b,1} '.vhdr'];
                    end
                else
                    filePath = [pathIn ID{a,1} filesep con{c,1} filesep];
                    fileName = [ID{a,1} u con{c,1} u tr{x,1} u tms u site{b,1} '.vhdr'];
                end
                
                filePathTemp{a,c}{b,x} = filePath;
                fileNameTemp{a,c}{b,x} = fileName;
                fileIDTemp{a,c} = ID{a,1};
                fileConTemp{a,c} = con{c,1};
                
            end                  
        end
    end
end

% Reshape name structures for loop
filePathIn = reshape(filePathTemp,1,[]);
fileNameIn = reshape(fileNameTemp,1,[]);
fileIDIn = reshape(fileIDTemp,1,[]);
fileConIn = reshape(fileConTemp,1,[]);

for x = 1:length(filePathIn)
    filePathIn{x} = reshape(filePathIn{x},1,[]);
    fileNameIn{x} = reshape(fileNameIn{x},1,[]);
end

%% RUN PARFOR LOOP TO CLEAN DATA

parfor x = 1:length(filePathIn)
    restCleaningStep1(filePathIn{x},fileNameIn{x},fileIDIn{x},fileConIn{x},pathOut);
    fprintf('%s %s is finished\n',fileIDIn{x},fileConIn{x});
end

%% FUNCTION FOR CLEANING THE DATA

function restCleaningStep1(filePathIn,fileNameIn,fileIDIn,fileConIn,pathOut)
% Performs the data cleaning steps. Input structures for file and path
% names need to be in the following format; e.g. filePathIn{1,ID}{condition,open/closed,timepoints}
% Load in one ID dimension per run

% Generate ALLEEG
ALLEEG = [];

% Generate names for triggers
trigName = {'t0_open','t0_closed','t1_open','t1_closed'};

for x = 1:length(filePathIn)

    % Load data
    EEG = pop_loadbv(filePathIn{x}, fileNameIn{x});

    % Import channels
    EEG=pop_chanedit(EEG, 'lookup','C:\\Program Files\\MATLAB\\eeglab14_1_1b\\plugins\\dipfit2.3\\standard_BESA\\standard-10-5-cap385.elp');

    % Downsample data
    EEG = pop_resample( EEG, 1000);

    % Remove unused channels
    EEG = pop_select(EEG,'nochannel',{'31','32'});

    % Filter the data
    EEG = pop_tesa_filtbutter( EEG, 1, 100, 4, 'bandpass' );
    EEG = pop_tesa_filtbutter( EEG, 48, 52, 4, 'bandstop' );

    % Generate triggers every 2 seconds (exclude first 10s and last 10s)
    s10 = EEG.srate*10;% Find 10 s from start
    e10 = EEG.times(1,end)-EEG.srate*10; % Find 10 s from end
    eventTimes = s10:EEG.srate*2:e10; % Calculate vector with 2 s intervals

    idx = length(EEG.event);
    for ev = 1:length(eventTimes)
        EEG.event(idx+ev).latency = eventTimes(ev);
        EEG.event(idx+ev).duration = NaN;
        EEG.event(idx+ev).channel = 0;
        EEG.event(idx+ev).type = trigName{x};
        EEG.event(idx+ev).urevent = idx+x;
        EEG.urevent(idx+ev).latency = eventTimes(ev);
        EEG.urevent(idx+ev).duration = NaN;
        EEG.urevent(idx+ev).channel = 0;
        EEG.urevent(idx+ev).type = trigName{x};
    end

    % Epoch the data
    EEG = pop_epoch( EEG, {  trigName{x}  }, [0  2], 'newname', ' resampled epochs', 'epochinfo', 'yes');

    %Store the data
    [ALLEEG, EEG, CURRENTSET]=eeg_store(ALLEEG,EEG,x);
end
                          
%Merge trials for two time sessions
EEG = pop_mergeset(ALLEEG, 1:length(filePathIn), 0);

%Save point
EEG = pop_saveset( EEG, 'filename', [fileIDIn,'_',fileConIn,'ds_filt_ep'],'filepath',[pathOut,fileIDIn,filesep,fileConIn,filesep]);
            
end
