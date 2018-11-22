% ##### COMPARE DISTANCE FROM BEST FITTING DIPOLE TO TARGET AND NON-TARGET SITES #####

% This script compares the distance from the best fitting dipole to the 
% target and non-target sites using a Mann-Whitney U test.
% Run dipole_fit_all.m first.

% Author: Nigel Rogasch, Monash University

clear; close all; clc;

% con = {'C1';'C2'}; % two experimental sessions seperated by at least a week
con = {'average'}; % two experimental sessions seperated by at least a week
site = {'pfc';'ppc'}; % two different stimulation sites

useData = 'CLEAN_ICA'; % 'CLEAN_ICA' | 'CLEAN_SOUND'
timeRange = '175_205'; % '' | '15_45' | '95_125' | '175_205'

pathDef = 'I:\nmda_tms_eeg\';

% Load data
if strcmp(con{1},'average')
    data = load([pathDef,useData,'/DIPOLES/dipole_outputs_average',timeRange,'.mat']);
else
    data = load([pathDef,useData,'/DIPOLES/dipole_outputs_',timeRange,'.mat']);
end

for conx = 1:length(con)
    for sitex = 1:length(site)
        
        [Stat.(con{conx}).(site{sitex}).P,~,Stat.(con{conx}).(site{sitex}).S] = ranksum(data.dipoleMetrics.(con{conx}).(site{sitex}).bestDist,data.dipoleMetrics.(con{conx}).(site{sitex}).bestDistNT);
        
    end
end

% Plot results
figure;
n = 1;
for conx = 1:length(con)
    for sitex = 1:length(site)
        
        subplot(2,2,n)
        dataCell = {data.dipoleMetrics.(con{conx}).(site{sitex}).bestDist,data.dipoleMetrics.(con{conx}).(site{sitex}).bestDistNT};
        BF_JitteredParallelScatter(dataCell,1,1,0);
        
        title([con{conx},' ',site{sitex},' Dist']);
        if Stat.(con{conx}).(site{sitex}).P < 0.001
            labelA = 'Non Target$p<0.001';
        else
            labelA = ['Non Target$p=',num2str(round(Stat.(con{conx}).(site{sitex}).P,3))];
        end
        
        labelA = strrep(labelA,'$','\newline');
        set(gca,'xlim',[0.5,2.5],'xtick',1:2,'xticklabel',{'Target',labelA});
        ylabel('Dist (m)');
        
        n = n+1;
    end
end

