% ##### FIND BEST FITTING DIPOLES WITHIN SET TIME RANGES #####

% This script finds the best fitting dipole at each point in time across a
% given time range. The script returns the goodness of fit of the dipole as
% well as the distance from the target of stimulation and the non-target
% site (calculated in an MNI space). 
% Inputs are the cleaned EEGLAB files, the individual lead fields generated 
% by Brainstorm and a default anatomy from Brainstorm in MNI space.

% Author: Nigel Rogasch, Monash University

clear; clc; close all;

ID = {'001';'002';'004';'005';'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};
% con = {'C1';'C2'};
con = {'average'};
site = {'pfc';'ppc'};
tms = 'tms';
tr = {'t0'};
trCap = {'T0'};
u = '_';

% Test over time range
% timeRange = 15:45;
% timeRange = 95:125;
timeRange = 175:205;

dataSet = 'sound'; % 'ica' | 'sound'

% Calculate target coordinates in SCS for default brain
destSurfMat = load('F:\brainstorm_db\TMS-EEG_NMDA\anat\@default_subject\tess_cortex_pial_low.mat');
sMri = load('F:\brainstorm_db\TMS-EEG_NMDA\anat\@default_subject\subjectimage_T1.mat');
pfc_mni = [-0.020, 0.035, 0.055]; % PFC
pfc_scs = cs_convert(sMri, 'mni', 'scs', pfc_mni);
ppc_mni = [-0.020, -0.065, 0.065]; % PPC
ppc_scs = cs_convert(sMri, 'mni', 'scs', ppc_mni);
[pfc_I,pfc_dist] = bst_nearest(destSurfMat.Vertices,pfc_scs, 1, 0);
[ppc_I,ppc_dist] = bst_nearest(destSurfMat.Vertices,ppc_scs, 1, 0);

for idx = 1:length(ID)
    for conx = 1:length(con)
        for sitex = 1:length(site)
            for trx = 1:length(tr)
                
                tic;
                % Set paths
                lfPathIn = ['F:\brainstorm_db\TMS-EEG_NMDA\data\sub',ID{idx},'\',ID{idx},u,'C1',u,tms,u,'pfc',u,'FINAL',u,'T0',u,'avref\'];
                
                % Load eeglab file for plotting
                if strcmp(con{conx},'average')
                    if strcmp(dataSet,'ica')
                        pathIn = 'I:\nmda_tms_eeg\CLEAN_ICA\';
                        filePathIn1 = [pathIn ID{idx} filesep 'C1' filesep];
                        filePathIn2 = [pathIn ID{idx} filesep 'C2' filesep];
                        fileNameIn1 = [ID{idx} u 'C1' u tms u site{sitex} u 'FINAL' u trCap{trx} u 'avref.set'];
                        fileNameIn2 = [ID{idx} u 'C2' u tms u site{sitex} u 'FINAL' u trCap{trx} u 'avref.set'];
                        
                    elseif strcmp(dataSet,'sound')
                        pathIn = 'I:\nmda_tms_eeg\CLEAN_SOUND\';
                        filePathIn1 = [pathIn ID{idx} filesep 'C1' filesep];
                        filePathIn2 = [pathIn ID{idx} filesep 'C2' filesep];
                        fileNameIn1 = [ID{idx} u 'C1' u tms u site{sitex} u tr{trx} u 'FINAL.set'];
                        fileNameIn2 = [ID{idx} u 'C2' u tms u site{sitex} u tr{trx} u 'FINAL.set'];
                    end
                    
                    EEG1 = pop_loadset('filename', fileNameIn1, 'filepath', filePathIn1);
                    EEG2 = pop_loadset('filename', fileNameIn2, 'filepath', filePathIn2);
                    
                    EEG = EEG1;
                    
                else
                    if strcmp(dataSet,'ica')
                        pathIn = 'I:\nmda_tms_eeg\CLEAN_ICA\';
                        filePathIn = [pathIn ID{idx} filesep con{conx} filesep];
                        fileNameIn = [ID{idx} u con{conx} u tms u site{sitex} u 'FINAL' u trCap{trx} u 'avref.set'];
                    elseif strcmp(dataSet,'sound')
                        pathIn = 'I:\nmda_tms_eeg\CLEAN_SOUND\';
                        filePathIn = [pathIn ID{idx} filesep con{conx} filesep];
                        fileNameIn = [ID{idx} u con{conx} u tms u site{sitex} u tr{trx} u 'FINAL.set'];
                    end
                    
                    EEG = pop_loadset('filename', fileNameIn, 'filepath', filePathIn);
                end
                
                
                
                % Load individual leadfield matrix
                load([lfPathIn,'headmodel_surf_openmeeg_02.mat']);
                
                % Load leadfield matrix channel order
                load([lfPathIn,'channel.mat']);
                
                % Load anatomy
                pathAN = ['F:\brainstorm_db\TMS-EEG_NMDA\anat\sub',ID{idx},'\'];
                fileAN = 'tess_cortex_pial_low.mat';
                srcSurfMat = load([pathAN,fileAN]);
                
                % Sort channel orders to match
                eeglabChans = {EEG.chanlocs.labels};
                leadfieldChans = {Channel.Name};
                for i = 1:size(eeglabChans,2)
                    [~,chanIndex(i)] = ismember(lower(eeglabChans{i}),lower(leadfieldChans));
                end
                Gain = Gain(chanIndex,:);
                              
                % Loop over times
                for tpx = 1:length(timeRange)
                    
                    % Find the time point
                    [~,tp] = min(abs(EEG.times-timeRange(tpx)));
                    
                    % Inputs for fitting algorithm
                    if strcmp(con{conx},'average')
                        data_vector{tpx} = (mean(EEG1.data(:,tp,:),3)+mean(EEG2.data(:,tp,:),3))./2;
                    else
                        data_vector{tpx} = mean(EEG.data(:,tp,:),3);
                    end
                    lead_field = Gain;
                    is_free_dipoles = 1;
                    [bestmatch{tpx}, GOF_of_bestmatch{tpx}, fit_residuals{tpx}, GOF_scores{tpx}, dipole_amplitudes{tpx}, best_match_topography{tpx}] = dipfit(data_vector{tpx}, lead_field, is_free_dipoles);
                end
                
                % Find the best match
                GOFmat = cell2mat(GOF_of_bestmatch);
                [bestG,besti] = max(GOFmat);
                bestTime = timeRange(besti);
                
                % Find the first match > 0.9
                NineLog = GOFmat>0.9;
                NineAllG = GOFmat(NineLog);
                if isempty(NineAllG)
                    bestG90 = NaN;
                else
                    bestG90 = NineAllG(1,1);
                end
                NineAll = find(GOFmat>0.9);
                if isempty(NineAll)
                    bestTime90 = NaN;
                else
                    bestTime90 = timeRange(NineAll(1,1));
                end
                
                % Find the Euclidean distance between best match and target
                % (in common brain space)
                Tsrc = bestmatch{besti};
                Tdest = convert_ind2default(srcSurfMat,destSurfMat,Tsrc);
                inputCoords = destSurfMat.Vertices(Tdest,:);
                if strcmp(site{sitex},'pfc')
                    [~,bestDist] = bst_nearest(inputCoords,pfc_scs, 1, 0);
                    [~,bestDistNT] = bst_nearest(inputCoords,ppc_scs, 1, 0);
                    bestDistPdist2 = pdist2(inputCoords,pfc_scs);
                elseif strcmp(site{sitex},'ppc')
                    [~,bestDist] = bst_nearest(inputCoords,ppc_scs, 1, 0);
                    [~,bestDistNT] = bst_nearest(inputCoords,pfc_scs, 1, 0);
                    bestDistPdist2 = pdist2(inputCoords,ppc_scs);
                end
                    
                % Find the Euclidean distance between best match >90 and
                % target (in common brain space)
                if ~isempty(NineAll)
                    Tsrc90 = bestmatch{NineAll(1,1)};
                    Tdest90 = convert_ind2default(srcSurfMat,destSurfMat,Tsrc90);
                    inputCoords90 = destSurfMat.Vertices(Tdest90,:);
                    if strcmp(site{sitex},'pfc')
                        [~,bestDist90] = bst_nearest(inputCoords90,pfc_scs, 1, 0);
                        [~,bestDistNT90] = bst_nearest(inputCoords90,ppc_scs, 1, 0);
                    elseif strcmp(site{sitex},'ppc')
                        [~,bestDist90] = bst_nearest(inputCoords90,ppc_scs, 1, 0);
                        [~,bestDistNT90] = bst_nearest(inputCoords90,pfc_scs, 1, 0);
                    end
                else
                    bestDist90 = NaN;
                    bestDistNT90 = NaN;
                    Tdest90 = NaN;
                    inputCoords90 = [NaN,NaN,NaN];
                end
                
                % Save output
                dipoleMetrics.(con{conx}).(site{sitex}).bestG(idx) = bestG;
                dipoleMetrics.(con{conx}).(site{sitex}).bestG90(idx) = bestG90;
                dipoleMetrics.(con{conx}).(site{sitex}).bestTime(idx) = bestTime;
                dipoleMetrics.(con{conx}).(site{sitex}).bestTime90(idx) = bestTime90;
                dipoleMetrics.(con{conx}).(site{sitex}).bestDist(idx) = bestDist;
                dipoleMetrics.(con{conx}).(site{sitex}).bestDist90(idx) = bestDist90;
                dipoleMetrics.(con{conx}).(site{sitex}).bestDistPdist2(idx) = bestDistPdist2;
                dipoleMetrics.(con{conx}).(site{sitex}).bestDistNT(idx) = bestDistNT;
                dipoleMetrics.(con{conx}).(site{sitex}).bestDistNT90(idx) = bestDistNT90;
                dipoleMetrics.(con{conx}).(site{sitex}).bestCoords(idx,:) = inputCoords;
                dipoleMetrics.(con{conx}).(site{sitex}).bestCoords90(idx,:) = inputCoords90;
                
                id = ['S',ID{idx}];
                dipoleOutputs.(id).(con{conx}).(site{sitex}).bestmatch = bestmatch;
                dipoleOutputs.(id).(con{conx}).(site{sitex}).GOF_of_bestmatch = GOF_of_bestmatch;
                dipoleOutputs.(id).(con{conx}).(site{sitex}).fit_residuals = fit_residuals;
                dipoleOutputs.(id).(con{conx}).(site{sitex}).GOF_scores = GOF_scores;
                dipoleOutputs.(id).(con{conx}).(site{sitex}).dipole_amplitudes = dipole_amplitudes;
                dipoleOutputs.(id).(con{conx}).(site{sitex}).best_match_topography = best_match_topography;
                
                timeOut = toc;
                fprintf('%s, %s, %s finished in %d s\n',ID{idx},con{conx},site{sitex},round(timeOut));
                
%                 % Plot the best match
%                 figure;
%                 subplot(1,2,1)
%                 topoplot(data_vector{besti},EEG.chanlocs,'electrodes','off');
%                 title(['Data ',num2str(timeRange(besti)),' ms']);
%                 subplot(1,2,2)
%                 topoplot(best_match_topography{besti},EEG.chanlocs,'electrodes','off');
%                 title(['Best fit ',num2str(timeRange(besti)),' ms']);
%                 
%                 % Plot on anatomy
%                 inverse_estimate = zeros(1,length(GOF_scores{besti}));
% %                 inverse_estimate(bestmatch) = GOF_of_bestmatch;
%                 inverse_estimate = GOF_scores{besti};
% 
%                 figure;
% %                 quiver3(Vertices(:,1),Vertices(:,2),Vertices(:,3),dipole_amplitudes{besti}(1,:)',dipole_amplitudes{besti}(2,:)',dipole_amplitudes{besti}(3,:)','k');
% %                 hold on;
%                 trisurf(Faces,Vertices(:,1),Vertices(:,2),Vertices(:,3),inverse_estimate,'facecolor','interp','edgealpha',0);
%                 hold on;
%                 plot3(Vertices(bestmatch{besti},1),Vertices(bestmatch{besti},2),Vertices(bestmatch{besti},3),'b.','MarkerSize',50);
%                 view([180,0])
                
            end
        end
    end
end

if strcmp(con{1},'average')
    save([pathIn,'\DIPOLES\dipole_outputs_average',num2str(timeRange(1)),'_',num2str(timeRange(end))],'dipoleMetrics','dipoleOutputs');
else
    save([pathIn,'\DIPOLES\dipole_outputs_',num2str(timeRange(1)),'_',num2str(timeRange(end))],'dipoleMetrics','dipoleOutputs');
end