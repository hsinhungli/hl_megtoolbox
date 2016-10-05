function [tf_data,nCycles] = getTimeFrequency(data, Fs, frex, range_cycles)
%data is 2 dimensional matrix, each row should be a timeseries that will be transform
%to time-frequency spectrum. Thus the output will be 3D if data is more
%than one row.
%Fs: sampling rate of the data
%frex: frequency to be analyzed
%range_cycles: this determine the width of the Gaussian of the wavelet.

% test parameters
% min_freq =  2;
% max_freq = 28;
% num_frex = max_freq-min_freq+1;
% frex = linspace(min_freq,max_freq,num_frex);
% range_cycles = [4 10];

% other wavelet parameters
num_frex = length(frex);
nCycles = logspace(log10(range_cycles(1)),log10(range_cycles(end)),num_frex);
s       = nCycles./(2*pi*frex);
wavtime = -2:1/Fs:2;
half_wave = (length(wavtime)-1)/2;

% FFT parameters
nWave = length(wavtime);
nData = size(data,2);
nConv = nWave + nData - 1;
nRow  = size(data,1);

% initialize output time-frequency data
tf_data = zeros(length(frex),nData,nRow);

% now compute the FFT of all trials concatenated
for r = 1:nRow;
    dataX(r,:) = fft(data(r,:),nConv); %Run fft for each row and set output with a length of nConv
end
%dataX = dataX';

% loop over frequencies
for fi=1:length(frex)
    
    % create wavelet and get its FFT
    % the wavelet doesn't change on each trial...
    wavelet  = exp(2*1i*pi*frex(fi).*wavtime) .* exp(-wavtime.^2./(2*s(fi)^2));
    waveletX = fft(wavelet,nConv);
    waveletX = waveletX ./ max(waveletX);
    waveletX = repmat(waveletX,nRow,1);
    
    % now run convolution in one step
    tempMat = waveletX .* dataX;
    for r = 1:nRow
        as = ifft(tempMat(r,:));
        as = as(half_wave+1:end-half_wave);
        tf_data(fi,:,r) = abs(as).^2;
    end
    %tf_dp(fi,:) = abs(as).^2;
end
tf_data = squeeze(tf_data);