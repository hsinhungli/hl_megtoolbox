function corr_ts = hl_serialcorr(data,template,corr)
%data:     time x chan
%template: ntemplate x chan

if nargin < 2
    error('Require 2 inputs: data and template');
end
if ~exist('corr','var')
    corr = 1;
elseif ~ismember(corr,[0 1])
    error('corr should be zero or 1');
end
if size(data,2) ~= size(template)
    error('channel number not matched between data and template')
end

nchan = size(data,2);
nt    = size(data,1);
ntemp = size(template,1);

if corr == 1
    data_dm   = bsxfun(@minus, data, mean(data,2)); %remove mean
    datanorm  = sqrt(sum(data_dm .* data_dm,2));
    ndata     = bsxfun(@rdivide, data_dm , datanorm);
    %ndata     = 
    %data_norm = arrayfun(@(idx) norm(data_dm(idx,:)), 1:nt);
elseif corr == 0
    ndata     = bsxfun(@minus, data, mean(data,2)); %remove mean
end

template_dm   = bsxfun(@minus, template, mean(template,2)); %remove mean
templatenorm  = sqrt(sum(template_dm .* template_dm,2));
ntemplate     = bsxfun(@rdivide, template_dm , templatenorm);
corr_ts = ntemplate * ndata';