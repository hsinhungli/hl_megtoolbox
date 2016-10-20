function data_bc = hl_rmbaseline(data,t,window)
%data: time x channel x trial
%window: 1x2 vector
assert(length(window)==2);

nt = size(data,1);
baseline = mean(data(t>=window(1) & t<window(2),:,:),1);
baseline = repmat(baseline,nt,1,1);
data_bc = data-baseline;
