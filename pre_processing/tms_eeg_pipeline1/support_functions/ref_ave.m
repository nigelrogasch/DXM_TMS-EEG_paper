function [data_ave] = ref_ave(data)
% This function re-references the data to the average reference.
%
% .........................................................................
% 24 September 2017: Tuomas Mutanen, NBE, Aalto university  
% .........................................................................

data_ave = data - repmat(mean(data,1),[size(data,1),1]);

end
