clear; close all; clc;

ID = {'001';'002';'004';'005';'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};
con = {'average'}; % two experimental sessions seperated by at least a week
site = {'pfc';'ppc'}; % two different stimulation sites
tr = {'T0'}; % two different time points within a day - t0 = baseline, t1 = following drug/placebo
useData = 'sound_final';



% Plot data
plotData = 'off'; %'on' | 'off'

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

% Create input path
if strcmp(useData,'ica_final')
    pathIn = [pathDef,'CLEAN_ICA1\'];
elseif strcmp(useData,'sound_final')
    pathIn = [pathDef,'CLEAN_SOUND2\'];
end

addpath ('C:\Users\Nigel\Desktop\fieldtrip-20170815');
ft_defaults;

% Load EEG data
load([pathIn,'grandAverage_N14.mat']);

% Load MNE data
load([pathIn,'MNE\mne_',useData],'mne');

% Load the target points in MNI space
sMri = load('F:\brainstorm_db\TMS-EEG_NMDA\anat\@default_subject\subjectimage_T1.mat');
pfc_mni = [-0.020, 0.035, 0.055]; % PFC
pfc_scs = cs_convert(sMri, 'mni', 'scs', pfc_mni);
ppc_mni = [-0.020, -0.065, 0.065]; % PPC
ppc_scs = cs_convert(sMri, 'mni', 'scs', ppc_mni);
[pfc_I,pfc_dist] = bst_nearest(mne.anat_def.Vertices,pfc_scs, 1, 0);
[ppc_I,ppc_dist] = bst_nearest(mne.anat_def.Vertices,ppc_scs, 1, 0);

% Cortical surface figure settings
sSurf = mne.anat_def;
iVertices = 1:length(sSurf.Vertices);
SurfSmoothIterations = ceil(300 * smoothValue * length(iVertices) / 100000);
Vertices_sm = sSurf.Vertices;
Vertices_sm(iVertices,:) = tess_smooth(sSurf.Vertices(iVertices,:), smoothValue, SurfSmoothIterations, sSurf.VertConn(iVertices,iVertices), 1);

vertFull = Vertices_sm;
facesFull = mne.anat_def.Faces;
curvData = mne.anat_def.Curvature;

msh_curvature           = -curvData.';
mod_depth               = 0.5;
curvatureColorValues    = ((2*msh_curvature>0) - 1) * mod_depth * 128 + 127.5;

curvatureColorValues(find(curvatureColorValues == 63.5)) = 130; % Original 85
curvatureColorValues(find(curvatureColorValues == 127.5)) = 85; % Original 130
curvData = [curvatureColorValues;curvatureColorValues;curvatureColorValues].';
curvData = curvData/255;

sitex = 1;
toix = 1;

for sitex = 1:length(site)
    for toix = 1:length(toi)
        % Generate figure
        fig = figure;
        set(gcf,'color','w');
        
        hold on;
        surfaceHandle = patch('Vertices',vertFull,'Faces',facesFull,'FaceVertexCdata',curvData,'FaceColor','interp','EdgeColor','none','FaceAlpha',1);
        axis image;
        axis off;
        
        view([-90,90])
        h = camlight('left');
        h = camlight('right');
%         h = camlight;
        material('dull');
        
        faceVDataCurv = get(surfaceHandle,'FaceVertexCData'); % Here always keep!
        
        cmap = jet(100).';
%         cmap = cmap(:,end:-1:1);
        
        FaceVData = faceVDataCurv;
        data = mean(mne.(site{sitex}){toix},2);
        
        cols = meshData2Colors(data, cmap, [], 1).';
        
%         Set the colours to plot
        maxVal = max(data);
        inds = find(data>maxVal*thresh);
        
        FaceVData(inds,:) = cols(inds,:);
        
        set(surfaceHandle,'FaceVertexCData',FaceVData);
        
        if strcmp(site{sitex},'pfc')
            plot3(mne.anat_def.Vertices(pfc_I,1),mne.anat_def.Vertices(pfc_I,2),mne.anat_def.Vertices(pfc_I,3),'b.','MarkerSize',50);
        elseif strcmp(site{sitex},'ppc')
            plot3(mne.anat_def.Vertices(ppc_I,1),mne.anat_def.Vertices(ppc_I,2),mne.anat_def.Vertices(ppc_I,3),'g.','MarkerSize',50);
        end
        
    end
end