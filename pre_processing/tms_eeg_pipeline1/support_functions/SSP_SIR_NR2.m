function [data_correct, artifact_topographies, data_clean, cleaning_operator] = SSP_SIR_NR2(EEG, L, Fs, time, artScale, timeRange, parameters)

% This functions removes muscle artifacts from TMS-EEG signal using the 
% SSP-SIR approach. The SSP operator is estimated as described in Mäki et
% al. Neuroimage, 2011. 

% The SIR and the time-adapted artifact rejection are implemented by Tuomas
% Mutanen. Please see Mutanen et al. NeuroImage, 2016 for details.

% data: the input data to be cleaned 
% L: the lead field used in SIR
% Fs: the sampling rate in Hz
% time: 1xN vector defining time range of epoch in ms
% artScale: choose which method to estimate the TMS-evoked muscle response
%           in the PCA
%           'automatic' (default): uses a sliding window to scale the
%           signal relative to the amplitude
%           'manual': only uses the data within a window provided by the
%           user in timeRange
% timeRange: required for artScale = 'manual'. Vector with start and end
%           times in ms of window containing TMS-evoked muscle response.
%           Note that multiple time windows can be defined.
%           Example: [5,50] - one window
%           Example: [5,50;100,120] - multiple windows

% PC: the number of artifact PCs to be removed
% M: the truncation dimension used in the SIR step

%NOTE: Data and LFM are expeted to have the same reference system

% Modifications:
% - NR adjusted x_scal to take into account different sampling rates
% - NR included sampling rate input (Fs)
% - NR included time vector input (time)
% - NR included plot of PC time courses
% - NR included an option for running PCA on limited data including the
%       TMS-evoked muscle response instead of scaling the signal in time
% - NR included smooth weighting function for 
% - 27-4-18:
% - TM modified the smooth time-weighting function
% - TM removed a dated mentioning that this function only works with Nexstim data
% - TM changed the condition for 'automatic' to nargin < 6 instead of
% nargin < 5. 
% - NR added a cleaning_operator output
% - NR changed first input to EEG data structure

if nargin < 6 %This used to be nargin < 5
    artScale = 'automatic';
end

if nargin == 7
    PC = parameters(1);
    M = parameters(2);
end

% Extract data
data = mean(EEG.data,3);
data = double(data);

%High-pass filtering the data from 100 Hz:
[b,a] = butter(2,100/(Fs/2),'high'); 
data_high = (filtfilt(b,a,data'))';

if strcmp(artScale,'automatic')
    %Estimating the relative-amplitude kernel of the artifact:
    tmp = data_high.^2;
    % x_scal = 73; %estimating the RMS value in 50-ms sliding windows
    x_scal = Fs./1000.*50; %estimating the RMS value in 50-ms sliding windows
    x = int8(linspace(-x_scal/2, x_scal/2,x_scal));
    for i=1:size(tmp,1)
        filt_ker(i,:) = conv(tmp(i,:),ones(1,x_scal),'same')/x_scal;
    end
    filt_ker = sum(filt_ker,1)/size(tmp,1);
    filt_ker = filt_ker/max(filt_ker);
    filt_ker = sqrt(filt_ker);
    filt_ker = repmat(filt_ker,[size(data_high,1),1]);

    %Estimating the artifact-supression matrix P:
    [Usup,singular_spectum,~] = svd(filt_ker.*data_high,'econ');

elseif strcmp(artScale,'manual')
    
    if isempty(timeRange)
        error('Please include a time range for the TMS-evoked muscle response\n');
    end
    
    % RUN PCA JUST ON DATA CONTAINING THE TMS-EVOKED MUSCLE RESPONSE
    for tidx = 1:size(timeRange,1)
        [~,t1] = min(abs(time-timeRange(tidx,1)));
        [~,t2] = min(abs(time-timeRange(tidx,2)));
        data_tmp(:,:,tidx) = data_high(:,t1:t2);
    end
    data_short = reshape(data_tmp,size(data_high,1),[]);

    % Estimating the artifact-supression matrix P:
    [Usup,singular_spectum,~] = svd(data_short,'econ');
    
    % Calculate scaling function for manual data
    smoothLength = 10; % Length of smooting window either side of 'includeLength'    
    smooth_weighting_function = dsigmf(time,[4/(smoothLength) timeRange(1) 4/(smoothLength) timeRange(2)]);
    smooth_weighting_function = repmat(smooth_weighting_function,[size(data_high,1),1]);
    
end

% % TEST PLOT OF PC TIME COURSES (-100 to 500 ms)
% fig1 = figure;
% for pcdx = 1:10
%     subplot(2,5,pcdx)
%     datatmp = U(:,pcdx)'*data;
%     plot(time,datatmp,'k');
% %     set(gca,'xlim',[-100,500]);
%     title(['PC ',num2str(pcdx)]);
% end
% 
% if nargin < 7
%     fig = figure(555);
%     plot(diag(singular_spectum))
%     title('Click line to choose the artifact dimension, then press Return.')
%     datacursormode on;
%     dcm_obj = datacursormode(fig);
%     % Wait while the user does this.
%     pause 
%     c_info = getCursorInfo(dcm_obj);
%     PC = c_info.Position(1);
%     M = rank(data) - PC;
%     close(fig);
% end
% 
% close(fig1);

% Loop over the first five PCs

for pcx = 1:5
    
    PC = pcx;
    M = rank(data) - PC;
    
    P = eye(size(data,1)) - Usup(:,1:PC)*(Usup(:,1:PC))';
    artifact_topographies_tmp{pcx} = Usup(:,1:PC);
    
    %Suppressing the artifacts:
    data_clean_tmp{pcx} = P*data;

    %Performing SIR for the suppressed data:
    PL = P*L;

    tau_proj = PL*PL';
    [U,S,V] = svd(tau_proj);
    S_inv = zeros(size(S));
    S_inv(1:M,1:M) = diag(1./diag(S(1:M,1:M)));
    tau_inv = V*S_inv*U';
    suppr_data_SIR = L*(PL)'*tau_inv*data_clean_tmp{pcx};

    cleaning_operator_tmp{pcx} = L*(PL)'*tau_inv*P;

    %Performing SIR for the original data:
    tau_proj = L*L';
    [U,S,V] = svd(tau_proj);
    S_inv = zeros(size(S));
    S_inv(1:M,1:M) = diag(1./diag(S(1:M,1:M)));
    tau_inv = V*S_inv*U';
    orig_data_SIR = L*(L)'*tau_inv*data;

    if strcmp(artScale,'automatic')
        data_correct{pcx} = filt_ker.*suppr_data_SIR + orig_data_SIR - filt_ker.*orig_data_SIR;
    elseif strcmp(artScale,'manual')
    %     data_correct = smooth_weighting_function.*suppr_data_SIR + (1 - smooth_weighting_function).*orig_data_SIR;
        data_correct{pcx} = smooth_weighting_function.*suppr_data_SIR + orig_data_SIR - smooth_weighting_function.*orig_data_SIR;
%          data_correct{pcx} = suppr_data_SIR;
    end
end

% Plot the impact of the top five PCs
tps = [10,20,30];
[~,tp1] = min(abs(tps(1)-time));
[~,tp2] = min(abs(tps(2)-time));
[~,tp3] = min(abs(tps(3)-time));

fig = figure;
subplot(6,5,1)

[b,a] = butter(2,100/(Fs/2),'low'); 
dataIn = (filtfilt(b,a,data'))';

plot(time, dataIn,'k');hold on;
plot([0,0],[-5,5],'k--');
plot([10,10],[-5,5],'r--');
plot([20,20],[-5,5],'r--');
plot([30,30],[-5,5],'r--');
ylabel('Raw');
set(gca,'xlim',[-10,100],'ylim',[-5,5]);
subplot(6,5,3)
topoplot(data(:,tp1), EEG.chanlocs);
subplot(6,5,4)
topoplot(data(:,tp2), EEG.chanlocs);
subplot(6,5,5)
topoplot(data(:,tp3), EEG.chanlocs);

for pcx = 1:5
    subplot(6,5,pcx*5+1)
    [b,a] = butter(2,100/(Fs/2),'low'); 
    dataIn = (filtfilt(b,a,data_correct{pcx}'))';
    plot(time, dataIn,'k');hold on;
    plot([0,0],[-5,5],'k--');
    plot([10,10],[-5,5],'r--');
    plot([20,20],[-5,5],'r--');
    plot([30,30],[-5,5],'r--');
    ylabel(['PC',num2str(pcx)]);
    set(gca,'xlim',[-10,100],'ylim',[-5,5]);
    subplot(6,5,pcx*5+2)
    datatmp = Usup(:,pcx)'*data;
    plot(time, datatmp,'k');hold on;
    set(gca,'xlim',[-10,100]);
    subplot(6,5,pcx*5+3)
    topoplot(data_correct{pcx}(:,tp1), EEG.chanlocs);
    subplot(6,5,pcx*5+4)
    topoplot(data_correct{pcx}(:,tp2), EEG.chanlocs);
    subplot(6,5,pcx*5+5)
    topoplot(data_correct{pcx}(:,tp3), EEG.chanlocs);
end

set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 1, 0.96]);

list = {'0','1','2','3','4','5'};
[indx,tf] = listdlg('ListString',list);

close(fig);

if indx == 1
    data_correct = data;
    artifact_topographies = [];
    data_clean = [];
    cleaning_operator = [];
else
    data_correct = data_correct{indx-1};
    artifact_topographies = artifact_topographies_tmp{indx-1};
    data_clean = data_clean_tmp{indx-1};
    cleaning_operator = cleaning_operator_tmp{indx-1};
end
    
end
