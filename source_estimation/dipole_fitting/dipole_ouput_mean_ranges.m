% ##### OUTPUT BEST FITTING DIPOLE METRICS TO COMMAND LINE #####

% This script outputs the best fitting dipole metrics used in the tables in
% the manuscript to the command line. Run dipole_fit_all.m first.

% Author: Nigel Rogasch, Monash University

clear; close all; clc;

% Which data to use
useData = 'ica_final'; % 'ica_final' | 'sound_final'

% Stimulation sites
site = {'pfc';'ppc'}; % two different stimulation sites
con = {'C1';'C2'};
timeBins = {'15_45';'95_125';'175_205'};

pathDef = 'I:\nmda_tms_eeg\';

% Create input path
if strcmp(useData,'ica_final')
    pathIn = [pathDef,'CLEAN_ICA\'];
elseif strcmp(useData,'sound_final')
    pathIn = [pathDef,'CLEAN_SOUND\'];
end

for sitex = 1:length(site)
    for timex = 1:length(timeBins)
        load([pathIn,'DIPOLES\dipole_outputs_average',timeBins{timex},'.mat']);
        
        fprintf('%s %s bestDist mean = %d [%d - %d]\n',site{sitex},timeBins{timex},round(mean(dipoleMetrics.average.(site{sitex}).bestDist)*1000),round(min(dipoleMetrics.average.(site{sitex}).bestDist)*1000),round(max(dipoleMetrics.average.(site{sitex}).bestDist)*1000));
        
    end
end

fprintf('\n');

for sitex = 1:length(site)
    for timex = 1:length(timeBins)
        load([pathIn,'DIPOLES\dipole_outputs_average',timeBins{timex},'.mat']);
        
        fprintf('%s %s bestDistNT mean = %d [%d - %d]\n',site{sitex},timeBins{timex},round(mean(dipoleMetrics.average.(site{sitex}).bestDistNT)*1000),round(min(dipoleMetrics.average.(site{sitex}).bestDistNT)*1000),round(max(dipoleMetrics.average.(site{sitex}).bestDistNT)*1000));
        
    end
end

fprintf('\n');

for sitex = 1:length(site)
    for timex = 1:length(timeBins)
        load([pathIn,'DIPOLES\dipole_outputs_average',timeBins{timex},'.mat']);
        
        fprintf('%s %s bestG mean = %d [%d - %d]\n',site{sitex},timeBins{timex},round(mean(dipoleMetrics.average.(site{sitex}).bestG),2),round(min(dipoleMetrics.average.(site{sitex}).bestG),2),round(max(dipoleMetrics.average.(site{sitex}).bestG),2));
        
    end
end

fprintf('\n');

for sitex = 1:length(site)
    for timex = 1:length(timeBins)
        load([pathIn,'DIPOLES\dipole_outputs_average',timeBins{timex},'.mat']);
        
        fprintf('%s %s bestG > 90  = %d \n',site{sitex},timeBins{timex},sum(dipoleMetrics.average.(site{sitex}).bestG > 0.9));
        
    end
end