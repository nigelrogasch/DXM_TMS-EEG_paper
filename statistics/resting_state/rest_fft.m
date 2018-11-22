% ##### CONVERT DATA FROM EEGLAB TO FIELDTRIP AND CALCULATE FFT #####

% This script converts cleaned EEGLAB data files to FieldTrip data files and
% then calculates FFT between 1-45 Hz with a Hanning taper.
% Inputs are cleaned EEGLAB data files.

% Author: Nigel Rogasch, Monash University

clear; close all; clc;

%% SETTING FILE PATHS AND NAMES

% Load FieldTrip
addpath ('C:\Users\Nigel\Desktop\fieldtrip-20170815');
ft_defaults;

% Participant ID
ID = {'001';'002';'003';'004';'005';'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};

con = {'C1';'C2'}; % Conditions
state = {'open';'closed'}; % State
tr = {'t0';'t1'}; % Time poine
u = '_'; % Underscore
pathIn = 'I:\nmda_tms_eeg\REST_CLEAN\'; % Path in

for a = 1:size(ID,1) % Loop over participants
    for c = 1:size(con,1) % Loop over conditions
        for b = 1:size(state,1) % Loop over open/closed
            for x = 1:size(tr,1)  % Loop over time points
                
                % Create file path and file name variables
                filePathTemp{a,c,b,x} = [pathIn ID{a,1} filesep con{c,1} filesep];
                fileNameTemp{a,c,b,x} = [ID{a,1} u con{c,1} u tr{x,1} u state{b,1} '_final_av.set'];
                fileIDTemp{a,c,b,x} = ID{a,1};
                fileConTemp{a,c,b,x} = con{c,1};
                
            end     
        end                  
    end
end

% Reshape for parallel loop
filePathIn = reshape(filePathTemp,1,[]);
fileNameIn = reshape(fileNameTemp,1,[]);
fileIDIn = reshape(fileIDTemp,1,[]);
fileConIn = reshape(fileConTemp,1,[]);

%% RUN PARFOR LOOP FOR FFT

parfor x = 1:length(filePathIn)
    fftFieldtrip(filePathIn{x},fileNameIn{x});
    fprintf('%s %s is finished\n',fileIDIn{x},fileConIn{x});
end

%% FFT WITH FIELD TRIP

function fftFieldtrip(filePath,fileName)

% Load data with EEGLAB and convert to FieldTrip
EEG = pop_loadset('filename', fileName, 'filepath', filePath);
data = eeglab2fieldtrip(EEG, 'preprocessing');

% Time-frequency analysis - FFT
dataFFT        = [];
cfg            = [];
cfg.channel    = {'all'};
cfg.output     = 'pow';
cfg.method     = 'mtmfft';
cfg.taper      = 'hanning';
cfg.foi        = 1:1:45;
cfg.keeptrials = 'no';
cfg.polyremoval = 1;

dataFFT = ft_freqanalysis(cfg,data);

% Create save path and name
tempName = strrep(fileName,'.set','_fft.mat');
saveName = [filePath,tempName];

save (saveName, 'dataFFT');

end
