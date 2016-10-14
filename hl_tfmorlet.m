function [tf] = hl_tfmorlet(data, time, freqoi, nCycle, detrend_n)
% Input:
% data: 2D: trial x time
% time: 1D: time points of the data
% freqoi: 1D: a vector of frequency to be analyzed
% nCycle: 1D: the width for morelet wavelet
% OutPut: 
% tf: trl x fre time

nfreq = length(freqoi);
Fs = 1000 / mean(diff(time));

if notDefined('nCycle')
    nCycle = 7*ones(1,nfreq);
end
if notDefined('detrend_n')
    detrend_n = 1;
end

s       = nCycle./(2*pi*freqoi);
wavtime = -2:1/Fs:2;
half_wave = (length(wavtime)-1)/2;

nWave = length(wavtime);
nData = size(data,2);
ntrl  = size(data,1);
nConv = nWave + nData - 1;

% detrend the data
V = ones(nData,detrend_n+1);
for k = 1:ntrl
    y = data(k,:)';
    x = time';
    
    V(:,detrend_n+1) = 1;
    for j = detrend_n:-1:1
        V(:,j) = V(:,j+1) .* x;
    end
    
    beta = V\y;
    data(k,:) = (y - V*beta)';
end

%preassign the output matrix
tf = zeros(nfreq,ntrl,nData);

for fi = 1:nfreq
    wavelet = exp(1i*2*pi*freqoi(fi).*wavtime) .* exp(-wavtime.^2/(2*s(fi)^2));
    waveletX = fft(wavelet,nConv);
    waveletX = waveletX ./ max(waveletX);
    
    dataX = fft(data,nConv,2);
    
    % run convolution
    as = ifft( repmat(waveletX,ntrl,1) .* dataX ,[],2);
    as = as(:,half_wave+1:end-half_wave);
    
    tf(fi,:,:) = as;
end

tf = permute(tf,[2 1 3]);
%trl x fre x time

