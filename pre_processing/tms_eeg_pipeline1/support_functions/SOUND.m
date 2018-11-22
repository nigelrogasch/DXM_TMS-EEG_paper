function [corrected_data, x, sigmas,dn] = SOUND(data, LFM, iter,lambda0)
% This function performs the SOUND algorithm for a given data.
%
% .........................................................................
% 24 September 2017: Tuomas Mutanen, NBE, Aalto university  
% .........................................................................

chanN = size(data,1);
sigmas = ones(chanN,1);
[y_solved, sigmas] = DDWiener(data);

if nargin<4
    lambda0 = 1;
end

% Number of time points
T = size(data,2);

% Going through all the channels as many times as requested
for k=1:iter
    sigmas_old = sigmas;
    
    disp(['Performing SOUND. Iteration round: ',num2str(k)])
    
    %Evaluating each channel in a random order
    for i=randperm(chanN)
        chan = setdiff(1:chanN,i);
            % Defining the whitening operator with the latest noise
            % estimates
            W = diag(1./sigmas);
            
            % Computing the whitened version of the lead field
            WL = (W(chan,chan))*(LFM(chan,:));
            WLLW = WL*WL';
            
            % Computing the MNE, the Wiener estimate in the
            % studied channel, as well as the corresponding noise estimate
            x = (WL)'*((WLLW + lambda0*trace(WLLW)/(chanN-1)*eye(chanN-1))\((W(chan,chan))*(data(chan,:))));
            y_solved = LFM*x;
            sigmas(i) = sqrt((y_solved(i,:)-data(i,:))*(y_solved(i,:)-data(i,:))')/sqrt(T);
    end
    
    % Following and storing the convergence of the algorithm
    dn(k) = max(abs(sigmas_old - sigmas)./sigmas_old);

end

% Final data correction based on the final noise-covariance estimate.

            W = diag(1./sigmas);
            WL = W*LFM;
            WLLW = WL*WL';
            x = WL'*((WLLW + lambda0*trace(WLLW)/chanN*eye(chanN))\(W*data));

   
corrected_data = LFM*x;

end