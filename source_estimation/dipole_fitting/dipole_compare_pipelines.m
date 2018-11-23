clear; close all; clc;

con = {'C1';'C2'}; % two experimental sessions seperated by at least a week
site = {'pfc';'ppc'}; % two different stimulation sites

% Return which computer is running
currentComp = getenv('computername');

% Select path based on computer
if strcmp(currentComp,'CHEWBACCA')
    % Location of 'sound_final' file
    pathDef = 'I:\nmda_tms_eeg\';
else
    % Location of 'sound_final' file
    pathDef = 'D:\nmda_tms_eeg\';
end

% Load data
dataICA = load([pathDef,'CLEAN_ICA1/DIPOLES/dipole_outputs.mat']);
dataSOUND = load([pathDef,'CLEAN_SOUND2/DIPOLES/dipole_outputs.mat']);

% Calculate Wilcoxon rank test
for conx = 1:length(con)
    for sitex = 1:length(site)
        
        [StatG.(con{conx}).(site{sitex}).P,~,StatG.(con{conx}).(site{sitex}).S] = ranksum(dataICA.dipoleMetrics.(con{conx}).(site{sitex}).bestG,dataSOUND.dipoleMetrics.(con{conx}).(site{sitex}).bestG);
        [StatDist.(con{conx}).(site{sitex}).P,~,StatDist.(con{conx}).(site{sitex}).S] = ranksum(dataICA.dipoleMetrics.(con{conx}).(site{sitex}).bestDist,dataSOUND.dipoleMetrics.(con{conx}).(site{sitex}).bestDist);
        [StatTime.(con{conx}).(site{sitex}).P,~,StatTime.(con{conx}).(site{sitex}).S] = ranksum(dataICA.dipoleMetrics.(con{conx}).(site{sitex}).bestTime,dataSOUND.dipoleMetrics.(con{conx}).(site{sitex}).bestTime);
        
    end
end

% Plot results
figure;
n = 1;
for conx = 1:length(con)
    for sitex = 1:length(site)
        
        subplot(2,2,n)
        dataCell = {dataICA.dipoleMetrics.(con{conx}).(site{sitex}).bestG,dataSOUND.dipoleMetrics.(con{conx}).(site{sitex}).bestG};
        BF_JitteredParallelScatter(dataCell,1,1,0);
        
        title([con{conx},' ',site{sitex},' G']);
        if StatG.(con{conx}).(site{sitex}).P < 0.001;
            labelA = 'SOUND$p<0.001';
        else
            labelA = ['SOUND$p=',num2str(round(StatG.(con{conx}).(site{sitex}).P,3))];
        end
        
        labelA = strrep(labelA,'$','\newline');
        set(gca,'xlim',[0.5,2.5],'xtick',1:2,'xticklabel',{'ICA',labelA});
        ylabel('G');
        
        n = n+1;
    end
end

figure;
n = 1;
for conx = 1:length(con)
    for sitex = 1:length(site)
        
        subplot(2,2,n)
        dataCell = {dataICA.dipoleMetrics.(con{conx}).(site{sitex}).bestDist,dataSOUND.dipoleMetrics.(con{conx}).(site{sitex}).bestDist};
        BF_JitteredParallelScatter(dataCell,1,1,0);
        
        title([con{conx},' ',site{sitex},' Dist']);
        if StatDist.(con{conx}).(site{sitex}).P < 0.001;
            labelA = 'SOUND$p<0.001';
        else
            labelA = ['SOUND$p=',num2str(round(StatDist.(con{conx}).(site{sitex}).P,3))];
        end
        
        labelA = strrep(labelA,'$','\newline');
        set(gca,'xlim',[0.5,2.5],'xtick',1:2,'xticklabel',{'ICA',labelA});
        ylabel('Dist(m)');
        
        n = n+1;
    end
end

figure;
n = 1;
for conx = 1:length(con)
    for sitex = 1:length(site)
        
        subplot(2,2,n)
        dataCell = {dataICA.dipoleMetrics.(con{conx}).(site{sitex}).bestTime,dataSOUND.dipoleMetrics.(con{conx}).(site{sitex}).bestTime};
        BF_JitteredParallelScatter(dataCell,1,1,0);
        
        title([con{conx},' ',site{sitex},' Time']);
        if StatTime.(con{conx}).(site{sitex}).P < 0.001;
            labelA = 'SOUND$p<0.001';
        else
            labelA = ['SOUND$p=',num2str(round(StatTime.(con{conx}).(site{sitex}).P,3))];
        end
        
        labelA = strrep(labelA,'$','\newline');
        set(gca,'xlim',[0.5,2.5],'xtick',1:2,'xticklabel',{'ICA',labelA});
        ylabel('Time (s)');
        
        n = n+1;
    end
end
        