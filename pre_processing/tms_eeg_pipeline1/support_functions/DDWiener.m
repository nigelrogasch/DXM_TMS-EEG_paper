function [y_solved, sigmas] = DDWiener(data)  
% This function computes the data-driven Wiener estimate (DDWiener),
% providing the estimated signals and the estimated noise-amplitudes
%
% .........................................................................
% 24 September 2017: Tuomas Mutanen, NBE, Aalto university  
% .........................................................................

% Compute the sample covariance matrix
C = data*data';

gamma = mean(diag(C));

% Compute the DDWiener estimates in each channel
chanN = size(data,1);
for i=1:chanN
    idiff = setdiff(1:chanN,i);
    y_solved(i,:) = C(i,idiff)*((C(idiff,idiff)+gamma*eye(chanN-1))\data(idiff,:));
end

% Compute the noise estimates in all channels 
sigmas = sqrt(diag((data-y_solved)*(data-y_solved)'))/sqrt(size(data,2));

end
