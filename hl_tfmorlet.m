function [tf] = hl_tfmorlet(data, time, freqoi, nCycle, detrend_n)
% Input:
% data: 2D: time x trial
% time: 1D: time points of the data
% freqoi: 1D: a vector of frequency to be analyzed
% nCycle: 1D: the width for morelet wavelet
% OutPut: 
% tf: fre x time x trl

nfreq = length(freqoi);
Fs    = 1000 / mean(diff(time));

if notDefined('nCycle')
    nCycle = 7*ones(1,nfreq);
end
if notDefined('detrend_n')
    detrend_n = 0;
end
if isrow(time)
    time = time';
end

s       = nCycle./(2*pi*freqoi);
wavtime = (-2:1/Fs:2)';
half_wave = (length(wavtime)-1)/2;

nWave = length(wavtime);
nData = size(data,1);
ntrl  = size(data,2);
nConv = nWave + nData - 1;

if detrend_n>0
    % detrend the data
    V = ones(nData,detrend_n+1);
    x = time;
    V(:,detrend_n+1) = 1;
    for j = detrend_n:-1:1
        V(:,j) = x.^j;
    end
    beta = V\data;
    data = (data - V*beta);
end

%preassign the output matrix
tf = zeros(nfreq,nData,ntrl);

for fi = 1:nfreq
    wavelet = exp(1i*2*pi*freqoi(fi).*wavtime) .* exp(-wavtime.^2/(2*s(fi)^2));
    waveletX = fft(wavelet,nConv);
    waveletX = waveletX ./ max(waveletX);
    
    dataX = fft(data,nConv,1);
    
    % run convolution
    as = ifft( repmat(waveletX,1,ntrl) .* dataX ,[],1);
    as = as(half_wave+1:end-half_wave,:);
    
    tf(fi,:,:) = as;
end

%fre x time x trl

