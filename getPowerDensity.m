function [fre, pds, phs, resolution, leakageIdx, fx, full_fre] = getPowerDensity(data,Fs,tagFrequency,pad_duration)
% Data should a matrix with time x channel x trial
% Fs is the sampling rate of the data
% tagFrequency is the critical frequency that will be checked whether
% suffered from leakage (optional). If leakageIdx is 1, there is leakage
% This script perform FFT along the first dimension of the data matrix

% Outputs:
% fre: Frequency (x-axis of spectrum)
% psd: Power spectrum (y-axs)

[N,nchan,ntrial] = size(data);
Nyquist  = Fs/2;
duration = N*(1/Fs);

if nargin<4 || isempty(pad_duration)
   pad_duration = duration;
end
if nargin<3
    tagFrequency = [];
    leakageIdx = [];
end

%% padding if needed
if pad_duration > duration
    duration_diff = pad_duration - duration;
    nzero_added = duration_diff*Fs;
    pad_1 = zeros(floor(nzero_added/2),nchan,ntrial);
    pad_2 = zeros(nzero_added-floor(nzero_added/2),nchan,ntrial);
    data  = cat(1,pad_1,data,pad_2);
    [N,nchan,ntrial] = size(data);
    fprintf('padding applied \n');
end

%% compute fft
fx  = fft(data)/N;                 %Scale by number of samples
fre = linspace(0,1,floor(N/2)+1) * Nyquist; %Frequency component corresponding to output of fft
pds = 2*abs(fx(1:floor(N/2+1),:,:)); %Multiply by 2 since only half the energy is in the positive half of the spectrum
phs = angle(fx(1:floor(N/2+1),:,:));
%fc  = 2*fx(1:N/2+1,:,:);

resolution = fre(3) - fre(2);

full_fre = [fre fliplr(fre(2:round(N/2)))];
%assert(length(full_fre) == padt);

if ~isempty(tagFrequency)
    leakageIdx = nan(1,numel(tagFrequency));
    for i = 1:numel(tagFrequency)
        leakageIdx(i) = isempty(find(fre==tagFrequency(i)));
    end
    if sum(leakageIdx)
        fprintf('there is leakage in power spectrum\n')
    end
end
end
