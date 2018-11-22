clear; close all; clc;

%###### STEP 2: SELECT BAD COMPONENTS, HIGH PASS FILTER, SELECT BAD TRIALS #####

ID = {'001';'002';'004';'005';'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};
con = {'C1';'C2'};
site = {'pfc';'ppc'};
tms = 'tms';
tr = {'t0';'t1'};
u = '_';

% Location of 'sound_final' file
pathIn = 'I:\nmda_tms_eeg\RAW\';
pathOut = 'F:\nmda_tms_eeg\CLEAN_SOUND\';

niter = 1;
for a = 1:size(ID,1) % Loop over participants
    for c = 1:size(con,1) % Loop over conditions
        for b = 1:size(site,1) % Loop over open/closed
            for x = 1:size(tr,1)  % Loop over time points
                
                % Load data
                EEG2ICA = pop_loadset('filename', [ID{a,1} u con{c,1} u tms u site{b,1} u tr{x,1} u 'ep_bc_ica1.set'], 'filepath', [pathOut ID{a,1} filesep con{c,1} filesep]);
                
                % Remove clear muscle artifacts, blink artifacts
                EEG2ICA = pop_tesa_compselect( EEG2ICA,'comps',10,'figSize','small','plotTimeX',[-200 500],'plotFreqX',[1 100],'tmsMuscle','on','tmsMuscleThresh',8,'tmsMuscleWin',[6 30],'tmsMuscleFeedback','off','blink','on','blinkThresh',2.5,'blinkElecs',{'Fp1','Fp2'},'blinkFeedback','off','move','off','moveThresh',2,'moveElecs',{'F7','F8'},'moveFeedback','off','muscle','off','muscleThresh',0.6,'muscleFreqWin',[30 100],'muscleFeedback','off','elecNoise','off','elecNoiseThresh',4,'elecNoiseFeedback','off' );
                
                % Do the baseline correction
                EEG2ICA = pop_rmbase( EEG2ICA, [-1000  1000]);
                
                % High pass filter (1 Hz)
                [bbut,abut] = butter(2,1/(EEG2ICA.srate/2),'high');
                for j = 1:size(EEG2ICA.data,1)
                    EEG2ICA.data(j,:) = filtfilt(bbut,abut,double(EEG2ICA.data(j,:))')';
                    disp(['High-pass filtering channel ',num2str(j)]);
                end
                
                % Baseline correction
                EEG2ICA = pop_rmbase( EEG2ICA, [-1000  -10]);
                
                % Remove bad trials
                TMPREJ=[];
                set(0,'units','pixels'); % Measure pixels
                Pix_SS = get(0,'screensize'); % Get pixel size of screen
                eegplot(EEG2ICA.data,'winlength',5,'command','pippo','srate',EEG2ICA.srate,'spacing',100,'position',Pix_SS);
                R1=input('Highlight bad trials, press Reject and then press enter');
                if ~isempty(TMPREJ)
                    [trialrej elecrej]=eegplot2trial(TMPREJ,size(EEG2ICA.data,2),size(EEG2ICA.data,3));
                else
                    trialrej=[];
                end
                tr2reject=find(trialrej==1);
                EEG2ICA.badTrials = tr2reject;
                EEG2ICA = pop_select( EEG2ICA,'notrial',tr2reject );
                
                % Save file
                EEG2ICA = pop_saveset( EEG2ICA, 'filename', [ID{a,1} u con{c,1} u tms u site{b,1} u tr{x,1} u 'ep_bc_ica1_clean'],'filepath',[pathOut ID{a,1} filesep con{c,1} filesep]);
                
                % Print how far through analysis we are
                fprintf('%d of 112 complete\n',niter);
                niter = niter+1;
            end
        end
    end
end