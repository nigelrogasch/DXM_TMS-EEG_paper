% ##### STORE FFT DATA IN GRAND AVERAGE STRUCTURE #####

% This script stores the FFT data from resting state condtions
% in a grand average structures according to condition/statte/time point.
% Inputs are FieldTrip files following FFT calculations.

% Author: Nigel Rogasch, Monash University

clear; close all; clc;

%% SETTING FILE PATHS AND NAMES

% Load FieldTrip
addpath ('C:\Users\Nigel\Desktop\fieldtrip-20170815');
ft_defaults;

% Participant ID
IDtemp = {'001';'002';'004';'005';'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};

% Create ID with S suffix
for idx = 1:length(IDtemp)
    ID{idx,1} = ['S',IDtemp{idx,1}];
end

con = {'C1';'C2'}; % Conditions
state = {'open';'closed'}; % State
tr = {'t0';'t1'}; % Time poine
u = '_'; % Underscore
pathIn = 'I:\nmda_tms_eeg\REST_CLEAN\'; % Path in
pathOut = 'I:\nmda_tms_eeg\REST_FFT_STATS\data\'; % Path out

for idx = 1:size(ID,1) % Loop over participants
    for conx = 1:size(con,1) % Loop over conditions
        for statex = 1:size(state,1) % Loop over open/closed
            for trx = 1:size(tr,1)  % Loop over time points
                
                % Create file path and file name variables
                pathName = [pathIn,IDtemp{idx,1},filesep,con{conx,1},filesep];
                fileName = [IDtemp{idx,1} u con{conx,1} u tr{trx,1} u state{statex,1} '_final_av_fft.mat'];
                load([pathName,fileName]);
                temp.(con{conx,1}).(state{statex,1}).(tr{trx,1}){idx} = dataFFT;
            
            end     
        end                  
    end
end

%% CREATE GRANDAVERAGE FILES FOR STATS

for conx = 1:length(con)
    for statex = 1:length(state)
        for trx = 1:length(tr)
            
            cfg=[];
            cfg.keepindividual = 'yes';

            %Create appropriate name and ensure correct number of participants.
        
            power = [];
            power = ft_freqgrandaverage(cfg,temp.(con{conx,1}).(state{statex,1}).(tr{trx,1}){:});

            savefile = [pathOut,con{conx,1},u,state{statex,1},u,tr{trx,1},'.mat'];
            save(savefile, 'power');%change for different configurations
        end
    end
end

