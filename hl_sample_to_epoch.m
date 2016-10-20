function epoch = hl_sample_to_epoch(sam_Mat,sampleInfo)

nsam   = size(sam_Mat,1);
epoch  = nan(1,nsam);

for s = 1:nsam
    for i = 1:length(sampleInfo)
        if sam_Mat(s,1) >= sampleInfo(i,1) && sam_Mat(s,2) <= sampleInfo(i,2)
            epoch(s) = i;
        end
    end
end

epoch = unique(epoch);
epoch(isnan(epoch)) = [];
