% ##### CONVERT EEGLAB TO FIELDTRIP AND STORE IN GRAND AVERAGE STRUCTURE #####

% This script converts individual EEGLAB files in to FieldTrip files and 
% stores the data in a grand average structures according to
% condition/site/time point.
% Inputs are final cleaned EEGLAB data files

% Author: Nigel Rogasch, Monash University

clear;

% ##### SETTINGS #####
ID = {'001';'002';'004';'005';'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};
con = {'C1';'C2'};
site = {'pfc';'ppc'};
tr = {'T0';'T1'};
trAlt = {'t0';'t1'};
tms = 'tms';
u = '_';

% Data
dataType = 'CLEAN_SOUND'; % 'CLEAN_ICA' | 'CLEAN_SOUND'

% Filtering
filtType = ''; %'' for 1-100 Hz

filePathDir = 'I:\nmda_tms_eeg\';


% Set file path
filePath = [filePathDir,dataType,filesep];
   
% ##### SCRIPT #####

% load fieldtrip

addpath ('C:\Users\Nigel\Desktop\fieldtrip-20170815');
ft_defaults;

% CONVERT FILES FROM EEGLAB TO FIELDTRIP

for idx = 1:size(ID,1)
    for sitex = 1:size(site,1)
        for conx = 1:size(con,1)
            for trx = 1:size(tr,1)
                
                %set filepath
                filepath = [filePath,ID{idx,1},filesep,con{conx,1},filesep];
                
                %set filename
                if strcmp(dataType,'CLEAN_ICA')
                    filename = [ID{idx,1} u con{conx,1} u tms u site{sitex,1} u 'FINAL_' tr{trx,1} '_avref',filtType,'.set'];
                elseif strcmp(dataType,'CLEAN_SOUND')
                    filename = [ID{idx,1} u con{conx,1} u tms u site{sitex,1} u trAlt{trx,1} filtType '_FINAL.set'];
                end
                
                %load EEGLAB data
                EEG = pop_loadset('filename', filename, 'filepath', filepath);
                
                EEG.icachansind = [];
                
                %convert to fieldtrip
                ftData = eeglab2fieldtrip(EEG, 'timelockanalysis');
                ftData.dimord = 'chan_time';
                
                %store data
                allData.(con{conx,1}).(site{sitex,1}).(tr{trx,1}){idx} = ftData;
                               
                fprintf('%s''s data converted from eeglab to fieldtrip\n', ID{idx,1});
                
            end
        end
    end
end

% CREATE GRAND AVERAGE FOR EACH CONDITION AND STORE

for conx = 1:size(con,1)
    for sitex = 1:size(site,1)
        for trx = 1:size(tr,1)
            
            %Perform grand average
            cfg=[];
            cfg.keepindividual = 'yes';
            
            grandAverage.(con{conx,1}).(site{sitex,1}).(tr{trx,1}) = ft_timelockgrandaverage(cfg,allData.(con{conx,1}).(site{sitex,1}).(tr{trx,1}){:});
           
        end
    end
end

%set filename
filename = ['grandAverage',filtType,'_N',num2str(length(ID))];

%Save data
save([filePath,filename],'grandAverage');