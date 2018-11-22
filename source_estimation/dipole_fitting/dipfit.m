function [bestmatch, GOF_of_bestmatch, fit_residuals, GOF_scores, dipole_amplitudes, best_match_topography] = dipfit(data_vector, lead_field, is_free_dipoles)

% This function does the simple dipole fitting to the signal vector of
% interest.

% By Tuomas Mutanen, 20th June, 2018
% Tuomas.mutanen@glasgow.ac.uk
% Room 632 Level 6 
% 62 Hillhead Street
% G12 8AD Glasgow, Scotland, UK
% Centre for Cognitive Neuroimaging
% Institute of Neuroscience & Pshychology
% University of Glasgow


% Input:

% data_vector : The input signal vector, e.g. at a certain deflection. 
% The function assumes the data in channels x 1 format.
%
% lead_field : The matrix containing the forward model. The function
% assumes channels x dipoles structure
%
% is_free_dipoles : The parameter that defines whether the dipoles in the
% forward model have a free orientation or not. In the case of free dipoles,
% the function assumes that the the dipoles are stored in the lead_field
% matrix as [q1x,q1y,q1z, ...,  qix,qiy,qiz, ...]

% Output:

% bestmatch = the index of the best dipole match
% GOF_of_bestmatch = The goodness-of-fit of the best macthing dipole
% fit_residuals = the residuals of all the dipoles (the fitting error) in
% uV^2
% GOF_scores = the goodness-of-fit scores of all the dipoles
% dipole_amplitudes = the best fitting dipole amplitudes at each source
% location (useful for different sort of visualizations)
% best_match_topography = the topopgrahy produced by the best matching
% dipole

if is_free_dipoles
    
    dipN = size(lead_field,2)/3;
    
    fit_residuals = zeros(1,dipN);
    GOF_scores = zeros(1,dipN);
    
    
    for i=1:dipN
        dipole_amplitudes(:,i) = pinv(lead_field(:,(3*i-2):(3*i)))*data_vector;
        fit_residuals(i) = sum((data_vector - lead_field(:,(3*i-2):(3*i))*dipole_amplitudes(:,i)).^2);
        GOF_scores(i) = 1 - fit_residuals(i)/sum(data_vector .^2);
    end
    
else
    
    dipN = size(lead_field,2);
    
    fit_residuals = zeros(1,dipN);
    GOF_scores = zeros(1,dipN);
    
    for i=1:dipN
        dipole_amplitudes(i) = pinv(lead_field(:,i))*data_vector;
        fit_residuals(i) = sum((data_vector - lead_field(:,i)*dipole_amplitudes(i)).^2);
        GOF_scores(i) = 1 - fit_residuals(i)/sum(data_vector .^2);
    end
end

[~, bestmatch] = min(fit_residuals);
GOF_of_bestmatch = GOF_scores(bestmatch);

if is_free_dipoles
    best_match_topography = dipole_amplitudes(1,bestmatch)*lead_field(:,3*bestmatch -2) +...
        dipole_amplitudes(2,bestmatch)*lead_field(:,3*bestmatch -1) + ...
        dipole_amplitudes(3,bestmatch)*lead_field(:,3*bestmatch);
else
    best_match_topography = dipole_amplitudes(bestmatch)*lead_field(:,bestmatch);
end
end

