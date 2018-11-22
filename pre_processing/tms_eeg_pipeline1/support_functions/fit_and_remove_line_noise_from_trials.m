function [data_clean] = fit_and_remove_line_noise_from_trials(data_orig, fs, linefreq)
% 

% 
% [ChanN, TimeN, TrialN] = size(data_orig);
% 
% for k = 1:TrialN
%     disp(['Removing line noise from trial ',num2str(k)])
%     for i = 1:ChanN
%         data_clean(i,:,k)  = removeLineNoise_SpectrumEstimation(data_orig(i,:,k) , fs);
%     end
% end


% This function fits and subtracts line noise from EEG recordings 

[ChanN, TimeN, TrialN] = size(data_orig);

%Creating the fitted line-noise model matrix
x_sub = [1:ceil(0.45*TimeN),floor(0.60*TimeN):TimeN];
PeriodL = 99.8384;%((fs)/linefreq);
modelMat_fit = [sin(2*pi*x_sub/PeriodL)', sin(2*pi*x_sub/PeriodL + pi/2)'];

% modelMat_fit = [];
% for i= 0:ceil(PeriodL/2)
%     modelMat_fit = [modelMat_fit, sin(2*pi*x/PeriodL + i)'];
% end

x = 1:TimeN;

modelMat = [sin(2*pi*x/PeriodL)', sin(2*pi*x/PeriodL + pi/2)'];

% modelMat = [];
% for i= 0:ceil(PeriodL/2)
%     modelMat = [modelMat, sin(2*pi*x/PeriodL + i)'];
% end

pinv_modelMat = pinv(modelMat_fit);

data_clean = data_orig;

figure
for k = 1:TrialN
    disp(['Removing line noise from trial ',num2str(k)])
    for i = 1:ChanN

        weights = pinv_modelMat*(data_orig(i,x_sub,k)');
        data_clean(i,:,k) = data_orig(i,:,k) - (modelMat*weights)';
%         if i == 32
%         plot(data_orig(i,:,k),'b')
%         hold on;
%         plot((modelMat*weights),'r')
%          hold on;
%         plot(data_clean(i,:,k) ,'gr')
%         hold off;
%         pause();
%         end
    end
end
 

end

