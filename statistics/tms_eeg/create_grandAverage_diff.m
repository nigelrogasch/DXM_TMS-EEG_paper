%##### CREATE DIFFERENCE STRUCTURES FOR CLUSTER STATS #####

% This script creates TEP difference scores (post-pre) following drug
% administration. This is to compare a drug x time interaction.
% Inputs are EEG data in grand average structures generated by FieldTrip.

% Author: Nigel Rogasch, Monash University

clear; close all; clc;
ID = {'001';'002';'004';'005';'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};
con = {'C1';'C2'};
site = {'pfc';'ppc'};
tr = {'T0';'T1'};
tms = 'tms';
u = '_';

% Data
dataType = 'CLEAN_SOUND'; % 'CLEAN_ICA' | 'CLEAN_SOUND'

% Filtering
filtType = ''; %'' for 1-100 Hz


% Location of 'sound_final' file
filePathDir = 'I:\nmda_tms_eeg\';

% Set file path
filePath = [filePathDir,dataType,filesep];

% Set time names
if strcmp(dataType,'CLEAN_ICA')
    tr = {'T0';'T1'};
else
    tr = {'T0';'T1'};
end

% Load data
load([filePath,'grandAverage',filtType,'_N',num2str(length(ID))]);

for cidx = 1:size(con,1)
    for sidx = 1:size(site,1)
        grandAverage.(con{cidx}).(site{sidx}).diff = grandAverage.(con{cidx}).(site{sidx}).T0;
        grandAverage.(con{cidx}).(site{sidx}).diff.individual = grandAverage.(con{cidx}).(site{sidx}).T1.individual - grandAverage.(con{cidx}).(site{sidx}).T0.individual;
    end
end

% Save data
save([filePath,'grandAverage',filtType,'_N',num2str(length(ID))],'grandAverage');