ntrial = length(prep_data.trial)
temp = satts;
clear satts;
for i = 1:ntrial
    satts(i,:) = temp(trl(i,1):trl(i,2));
end