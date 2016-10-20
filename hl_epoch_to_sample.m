function [sample_mat] = hl_epoch_to_sample(epoch,sampleInfo)

nepoch = length(epoch);
sample_mat   = nan(nepoch,2);
for e = 1:nepoch
    sample_mat(e,:) = sampleInfo(epoch(e),:);
end