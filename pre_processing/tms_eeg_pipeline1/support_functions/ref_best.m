function [data_bestC] = ref_best(data, bestC)
% This function re-references the data to the channel with the least noise, 
% indicated with bestC.
%
% .........................................................................
% 24 September 2017: Tuomas Mutanen, NBE, Aalto university  
% .........................................................................

data_bestC = data - repmat(data(bestC,:),[size(data,1),1]);

end
