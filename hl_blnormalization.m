function data_normliazed = hl_blnormalization(data,time,int,type,dim)
% data_normliazed = hl_blnormalization(data,time,int,type,dim)
% This function take data as the data Matrix (e.g. MEG time-frequency time series), and do baseline normalization
% By default, the first dimension of the data matrix should be time.
% Otherwise, use optional input to assign the time dimension.
% The baseline interval is defined by vector "time" and the range defined
% in "int". For example, time can be a vectior -500:1:1000 (-500 ~ 1000
% msec). int has to be a 1x2 vector (e.g. [-500 0], defining the time window for baseline.
% if time is not at the first dimension of the data matrix, can use option:
% dim to inform the time dimension.

% Required inputs:
% data: data Matrix, typically time is the first dimension
% time: time axis. Should be the same lenth as the time domain in data
% matrix
% int: the interval that is take as the baseline
% Optional inputs (in order):
% type: 1: percentage change  2: ratio
% dim: the dimension to be take as baseline, the default is the first
% dimension (which should be time)

if nargin > 5
    error('hl_blnormalize:TooManyInputs', ...
        'requires at most 2 optional inputs');
end

%Set optional inputs if not set
if ~exist('type','var') || isempty(type)
  type = 1;
end
if ~exist('dim','var') || isempty(dim)
  type = 1;
end

% Check whether all inputs make sense
if ~isvector(time) || ~isrow(time)
    error('hl_blnormalize:TooManyInputs', ...
        'time should be a vector or a row');
end
if numel(time) ~= size(data,dim)
    error('hl_blnormalize:TooManyInputs', ...
        'length of time vector doest match the data');
end
if numel(int)>2 || int(2)<int(1)
    error('hl_blnormalize:TooManyInputs', ...
        'int should be 1x2 and int(2)>int(1)');
end
if ~ismember(type,[1 2])
    error('hl_blnormalize:TooManyInputs', ...
        'type has to be 1 (pct change) or 2 (ratio)');
end

bl_ind = find(time>int(1) & time<int(2));

ind = cell(1, ndims(data));
for k = 1:ndims(data)
    if k==dim
        ind{k} = bl_ind;
    else
        ind{k} = 1:size(data, k);
    end
end

bl = mean(data(ind{:}),dim);
switch type
    case 1
        data_normliazed = bsxfun(@rdivide, bsxfun(@minus, data, bl), bl);
    case 2
        data_normliazed = ( bsxfun(@rdivide, data, bl) );
end

