clear; close all; clc;

%###### STEP 1: CONVERT, EPOCH, BASELINE CORRECT, REMOVE TMS ARTIFACT, REMOVE CHANNELS, RUN FASTICA #####

% Note that the following need redoing:
% 001, (C2 - wrong ID name)
% 003, (C2 - wrong ID name) 
% 007, (C1 - wrong ID name)
% 008, (C1 - wrong condition name, C2 - wrong ID name)
% 014, (C1,ppc,t0 - ppc2 has most trials)

ID = {'001';'002';'004';'005';'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};
con = {'C1';'C2'};
site = {'pfc';'ppc'};
tms = 'tms';
tr = {'t0';'t1'};
u = '_';


% Location of 'sound_final' file
pathIn = 'I:\nmda_tms_eeg\RAW\';
pathOut = 'F:\nmda_tms_eeg\CLEAN_SOUND\';

eeglab

% Set up file paths and names

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

                % Load file
                if strcmp(ID{a,1},'001') && strcmp(con{c,1},'C2')% 001 C2
                    con2 = {'s1'};
                    tr2 = {'t1';'t2'};
                    filePath = [pathIn ID{a,1} filesep con{c,1} filesep];
                    fileName = ['HeGa' u con2{1,1} u tr2{x,1} u site{b,1} u tms '.vhdr'];
                elseif strcmp(ID{a,1},'003') && strcmp(con{c,1},'C2')% 003 C2
                    filePath = [pathIn ID{a,1} filesep con{c,1} filesep];
                    fileName = ['002' u con{c,1} u tr{x,1} u tms u site{b,1} '.vhdr'];
                elseif strcmp(ID{a,1},'007') && strcmp(con{c,1},'C1')% 007 C1
                    filePath = [pathIn ID{a,1} filesep con{c,1} filesep];
                    fileName = ['008' u 'C1' u tr{x,1} u tms u site{b,1} '.vhdr'];                   
                elseif strcmp(ID{a,1},'008') && strcmp(con{c,1},'C1')% 008 C1  
                    filePath = [pathIn ID{a,1} filesep con{c,1} filesep];
                    fileName = [ID{a,1} u 'C2' u tr{x,1} u tms u site{b,1} '.vhdr'];                   
                elseif strcmp(ID{a,1},'008') && strcmp(con{c,1},'C2') % 008 C2 
                    filePath = [pathIn ID{a,1} filesep con{c,1} filesep];
                    fileName = ['002' u con{c,1} u tr{x,1} u tms u site{b,1} '.vhdr'];                  
                elseif strcmp(ID{a,1},'014') && strcmp(con{c,1},'C1') && strcmp(site{b,1},'ppc') && strcmp(tr{x,1},'t0') % 014 C1 ppc t0
                    filePath = [pathIn ID{a,1} filesep con{c,1} filesep];
                    fileName = [ID{a,1} u con{c,1} u tr{x,1} u tms u 'ppc2' '.vhdr'];                   
                else
                    filePath = [pathIn ID{a,1} filesep con{c,1} filesep];
                    fileName = [ID{a,1} u con{c,1} u tr{x,1} u tms u site{b,1} '.vhdr'];                   
                end
                
                tempFilePath{a,c,b,x} = filePath;
                tempFileName{a,c,b,x} = fileName;
                tempFilePathOut{a,c,b,x} = [pathOut ID{a,1} filesep con{c,1} filesep];
                tempFileNameOut{a,c,b,x} = [ID{a,1} u con{c,1} u tms u site{b,1} u tr{x,1} u 'ep_bc_ica1'];
                
            end
        end
    end
end

% Reshape name structures for loop
filePathIn = reshape(tempFilePath,1,[]);
fileNameIn = reshape(tempFileName,1,[]);
filePathOut = reshape(tempFilePathOut,1,[]);
fileNameOut = reshape(tempFileNameOut,1,[]);

%% RUN PARFOR LOOP TO CLEAN DATA

parfor x = 1:length(filePathIn)
    restCleaningStep1(filePathIn{x},fileNameIn{x},filePathOut{x},fileNameOut{x},mainpath);
    fprintf('%s complete\n',fileNameOut{x});
end

%%
function restCleaningStep1(filePathIn,fileNameIn,filePathOut,fileNameOut,mainpath)
    
    % Create report
    reportStatus = 'started';
    save([filePathOut,fileNameOut,'_report'],'reportStatus');

    % Check if has been done
    checkOut = dir(filePathOut);
    namesIn = {checkOut.name};
    newFile = fileNameOut;
    
    if ~ismember(newFile,namesIn)

        % Load data
        EEG = pop_loadbv(filePathIn, fileNameIn);

        % Load default channel file
        EEG=pop_chanedit(EEG, 'lookup',[mainpath,'/eeglab14_1_1b/plugins/dipfit2.3/standard_BESA/standard-10-5-cap385.elp'],'changefield',{1 'type' 'EEG'},'changefield',{2 'type' 'EEG'},'changefield',{3 'type' 'EEG'},'changefield',{4 'type' 'EEG'},'settype',{'1:64' 'EEG'});

        % Remove eye electrodes
        EEG = pop_select(EEG,'nochannel',{'31','32'});

        % Epoch data
        EEG = pop_epoch( EEG, { 'R128' }, [-1.5  1.5], 'newname', ['TMS' ' epochs'], 'epochinfo', 'yes');

        % Baseline correction
        EEG = pop_rmbase( EEG, [-1000  1000]);

        % Fit and remove line noise
        EEG.data = fit_and_remove_line_noise_from_trials(EEG.data, EEG.srate, 50);

        % Remove the TMS artifact and replace with the baseline data
        [~, TMS_art_start] = min(abs(EEG.times - (-2)));
        [~, TMS_art_end] = min(abs(EEG.times - (6)));
        EEG.data(:,TMS_art_start:TMS_art_end,:) = fliplr(EEG.data(:,(TMS_art_start:TMS_art_end) - length((TMS_art_start:TMS_art_end)),:));

        % Perform the baseline correction 
        EEG = pop_rmbase( EEG, [-1000  1000]);

        % Prepare the data for ICA: First remove for a while the very worst channels!
        EEG_evo = mean(EEG.data,3);
        [~, sigmas] = DDWiener(EEG_evo);

        % labeling the very worst channels to not affect the ICA run
        badC = find(sigmas > (median(sigmas) + 5*std(sigmas)));
        goodC = setdiff(1:length(sigmas),badC);
        EEG2ICA = pop_select( EEG, 'nochannel', badC);

        %Reshapes 3D matrix to 2D
        inMat=reshape(EEG2ICA.data,size(EEG2ICA.data,1),[],1);

        %Checks that number of dimensions is larger than compression value
        covarianceMatrix = cov(inMat', 1);
        [E, D] = eig (covarianceMatrix);
        rankTolerance = 1e-7;
        rankMat = sum (diag (D) > rankTolerance);

        % Run ICA
        EEG2ICA = ICA_analysis(EEG2ICA,EEG2ICA.data,rankMat);% run ICA using the runica method from EEGlab

        % Save data
        EEG2ICA = pop_saveset( EEG2ICA, 'filename', fileNameOut,'filepath',filePathOut);
        
    end
    
    % Create updated report
    reportStatus = 'finished';
    save([filePathOut,fileNameOut,'_report'],'reportStatus');
    
end

