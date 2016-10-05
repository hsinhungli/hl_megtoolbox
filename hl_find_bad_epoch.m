function [bad_epochs, bad_epochs_2D, ts_out] = hl_find_bad_epoch(ts_in, var_thresh, nbadchannel_thresh, produce_figures)

% This function will take every epoch and compares the variance of the
% signal within this epoch with a certain threshold (say, 10 times the
% median of the signal of one channel). All epochs with a variance larger
% than the threshold, will be defined as a bad epoch (1) in a matrix. One 
% can use this matrix to plot the difference between with/without bad
% epochs.

% INPUTS
%   ts_in:           Timeseries (time points x epochs x channels)
%   produce_figures: boolean (if true, plot pre and post remove bad epochs)
%
% OUTPUTS 
%   bad_epochs: Matrix with all the bad_epochs
%   ts_out:         Timeseries with removed epochs
%
% From Winawer Lab
% Modified by Hsin-Hung Li 6/2015

%% Check required inputs
if size(ts_in,3) ~= 157
error('check data matrix dimension: time x epoch x channels')
end
if exist('var_thresh','var') == 0
    var_thresh = [.1 10];
end
if exist('nbadchannel_thresh','var') == 0
    nbadchannel_thresh = 30;
end
if exist('produce_figures','var') == 0
    produce_figures = 1;
end
%% Make matrix to remove bad epochs for ON-data
% epochs x channel
num_epochs = size(ts_in, 2);
num_channels = 157;
bad_epochs_2D =false(num_epochs,num_channels);


remove_fun = @(x) x>(var_thresh(2)*median(x)) | x < (var_thresh(1) * median(x));

% check epochs
for chan=1:num_channels
    a=nanvar(squeeze(ts_in(:,:,chan)),[],1); %a is the variance (across time points) of each trial.
    bad_epochs_2D(remove_fun(a),chan)=true;
end


%% plot bad epoch matrix for on and off data
if produce_figures
    figure; set(gca, 'FontSize', 20)
    imagesc(bad_epochs_2D'); colormap gray
    xlabel('Epochs');
    ylabel('Channels');
    title('Removed epochs');
end

%% Define clean data with removed epochs as a new variable, with for removed epochs NaN's

 ts_out = ts_in;
 
% Loop over channels & replace time points with NaNs in bad epochs
for chan = 1:157
   
    % Turn this epoch into NaN's
    ts_out(:,bad_epochs_2D(:,chan),chan) = NaN;
    
end

%% note: if more than XX channels have a bad epoch at the same time, 
% then that epoch should probably be killed for all channels
thresh = nbadchannel_thresh;
num_bad_channels_per_epoch = sum(bad_epochs_2D,2);
bad_epochs = num_bad_channels_per_epoch > thresh;
ts_out(:, bad_epochs,:) = NaN;

nbad_epochs = sum(bad_epochs);
badpercentage = nbad_epochs / size(ts_in,2)*100;
disp(['bad epochs',num2str(find(bad_epochs)')]);
fprintf('%2.2f percentage of epochs marked as bad',badpercentage);

%% Plot two visual channels again

if produce_figures

    figure(107); clf
    chan = 1;
    
    plot(nanmean(ts_out(:,:,chan),2), 'r'); hold on;
    plot(nanmean(ts_in(:,:,chan),2),'b');
    xlabel('Time (ms)');
    ylabel('Amplitude (Picotesla)');
    title(sprintf('Timeseries with removed bad epochs of channel nr %d', chan));
    legend('Removed','Not removed');

    figure(109); clf
    chan = 14;
    plot(nanmean(ts_out(:,:,chan),2), 'r'); hold on;
    plot(nanmean(ts_in(:,:,chan),2),'b');
    xlabel('Time (ms)');
    ylabel('Amplitude (Picotesla)');
    title(sprintf('Timeseries with removed bad epochs of channel nr %d', chan));
    legend('Removed','Not removed');

end
