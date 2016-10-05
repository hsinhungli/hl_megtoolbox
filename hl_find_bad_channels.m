function bad_channels = hl_find_bad_channels(ts,lb,ub)
%Identify problem channels in MEG time series. 
%
%  bad_channels = meg_find_bad_channels(ts)
%
%   Bad channels are identified based on the standard deviation of the
%   time series. We compute one sd for each channel for each epoch. Then,
%   for each channel, we take the median standard deviation across epochs.
%   The grand median is the median of these values across channels. If the
%   median of any particular channel is either less than 10 times smaller
%   or more than 10 times bigger than the grand median, we label that
%   channel as bad. We return a vector of bad channels.
% 
% INPUT
%   ts: time x epoch x channel
% OUTPUT
%   bad_channels: vector of bad channels
%
% Example: bad_channels = meg_find_bad_channels(ts);

% % doesn't work when there is only one epoch
% sd              = squeeze(nanstd(ts)); % sd will be epochs x channels
% sd_median       = nanmedian(sd); % median sd for each channel
% sd_grand_median = nanmedian(sd_median); % median across all channels
%
% bad_channels = sd_median < 0.1 * sd_grand_median | sd_median > 10 * sd_grand_median;
% bad_channels = find(bad_channels);

if nargin<3
    ub = 5;
end
if nargin<2
    lb = .2;
end

sd              = nanstd(ts,0,1); % sd will be epochs x channels
sd_median       = nanmedian(sd,2); % median sd for each channel
sd_grand_median = nanmedian(sd_median,3); % median across all channels

bad_channels = squeeze(sd_median) < lb * sd_grand_median | squeeze(sd_median) > ub * sd_grand_median;
bad_channels = find(bad_channels);
figure;plot(sd_median(:),'-o'); hold on;
plot([1 157],[5 * sd_grand_median 5 * sd_grand_median],'-');
plot([1 157],[0.3 * sd_grand_median 0.3 * sd_grand_median],'-'); hold off;




