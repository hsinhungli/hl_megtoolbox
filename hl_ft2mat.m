function dataMatrix = hl_ft2mat(prep_data)
%Transform the data in fieldtrip structure to matlab matrix.

duration = size(prep_data.trial{1},2);
nchan    = size(prep_data.trial{1},1);
ntrial   = length(prep_data.trial);
dataMatrix = cell2mat(prep_data.trial);
dataMatrix = reshape(dataMatrix,[nchan, duration, ntrial]);
dataMatrix = permute(dataMatrix,[2 1 3]) * 10^15;