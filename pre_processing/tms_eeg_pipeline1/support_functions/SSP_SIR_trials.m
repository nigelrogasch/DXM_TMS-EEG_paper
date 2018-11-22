function [EEG_out] = SSP_SIR_trials(EEG_in, L, art_topographies,  timeRange, regularization )


%This function cleans each trial separately with a given artifact
%topographies

EEG_out = EEG_in;
time = EEG_in.times;

P = eye(size(EEG_in.data,1)) - art_topographies*art_topographies';


for i = 1:size(EEG_in.data,3)

    data = EEG_in.data(:,:,i);

%Suppressing the artifacts:
data_clean = P*data;

%Performing SIR for the suppressed data:
PL = P*L;

if nargin < 4

    M = regularization;
else
    M = rank(data_clean);
end
    
tau_proj = PL*PL';
[U,S,V] = svd(tau_proj);
S_inv = zeros(size(S));
S_inv(1:M,1:M) = diag(1./diag(S(1:M,1:M)));
tau_inv = V*S_inv*U';
suppr_data_SIR = L*(PL)'*tau_inv*data_clean;

%Performing SIR for the original data:
tau_proj = L*L';
[U,S,V] = svd(tau_proj);
S_inv = zeros(size(S));
S_inv(1:M,1:M) = diag(1./diag(S(1:M,1:M)));
tau_inv = V*S_inv*U';
orig_data_SIR = L*(L)'*tau_inv*data;

filt_ker = -1*sigmf(time,[0.05*(timeRange(2)-timeRange(1)) timeRange(2)]) + sigmf(time,[0.05*(timeRange(2)-timeRange(1)) timeRange(1)]);

filt_ker = repmat(filt_ker,[size(suppr_data_SIR,1),1]);
    
data_correct = filt_ker.*suppr_data_SIR + orig_data_SIR - filt_ker.*orig_data_SIR;

EEG_out.data(:,:,i) = data_correct;

end
end

