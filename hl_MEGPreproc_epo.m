function [prep_data,prep_data_eye,dataMatrix,triggerNumber,satMatrix,badEpoch_nbc,badchan] = hl_MEGPreproc_epo(filename,tstart,tend,windowsize)

if nargin<3
    error('Please assign the tstart and tend for epoching')
end
if nargin<4
    fprintf('using default windowsize : 20*SampleingRate\n')
    windowsize = 20;
end

%% Get the MEG data
% data is time x channels
fprintf('----------loading original sqd data----------\n')
info = sqdread(filename,'Info');
Fs   = info.SampleRate;
nt   = info.SamplesAvailable;
t    = tstart:tend;

% remember, these channel numbers use zero indexing
hl_loadMEGInfo;

%% Get Saturation matrix
% plotFig     = 1;
% [rawdataMatrix,~,~] = hl_getData(filename, trigChan, megChan+1, tstart, tend);
% satMatrix   = hl_find_saturation(rawdataMatrix, windowSize, plotFig);
%save(satMatrixName,'satMatrix');
%clear rawdataMatrix

%% Epoch the data into fieldtrip format and do bad channel replacement
[trl,triggerNumber] = hl_gettrlinfo(filename, trigChan, tstart, tend);
ntrial   = size(trl,1);
duration = trl(1,2) - trl(1,1) +1;

%prepare ft data format
prep_data = ft_preprocessing(struct('dataset',filename,...
    'channel','MEG','continuous','yes','trl',trl));

%prepare matlab matrix format: time x chan x trial
rawdataMat = cell2mat(prep_data.trial);
rawdataMat = reshape(rawdataMat,[length(megChan), duration, ntrial]);
rawdataMat = permute(rawdataMat,[2 1 3]) * 10^15;
temp_badchan = hl_find_bad_channels(permute(rawdataMat,[1 3 2])); %scan bad channel again;
disp(temp_badchan);
dummy = input('check bad channel');

% Get saturation info
plotFig    = 1;
satMatrix  = hl_find_saturation(rawdataMat, windowsize, plotFig); %chan x epoch
sat_badchan = find(sum(satMatrix,2)>0);
% check with the user that this looks good
drawnow;
go = input('Procede to bad channel interpolation? [y,n]','s');
if ~strcmp(go,'y')
    fprintf('\nNo interpolation\n\n')
    dataMatrix = rawdataMat;
    return
else
    fprintf('\nBad chan interpolation\n\n')
end

%% Do badchannel replace for all trial
badEpoch_nbc = zeros(1,ntrial);
badchan      = cell(1,ntrial);
badChannels  = temp_badchan; %use sat_badchan or temp_badchan here.
fprintf('Do interpolation for all trials \n')
disp(badChannels)
cfg = [];
cfg.badchannel = ft_channelselection(badChannels, prep_data.label);
cfg.method = 'spline';
temp_data_1 = ft_channelrepair(cfg, prep_data);
% compare before and after interpolation
for trial = 1:ntrial
    badchan{trial} = badChannels;
    badEpoch_nbc(trial) = numel(badChannels);
end
if plotFig
    figure
    sampleChannels = badChannels;
    for iCh = 1:numel(sampleChannels)
        chan = sampleChannels(iCh);
        subplot(numel(sampleChannels),1,iCh)
        hold on
        plot(t, prep_data.trial{1}(chan,:))
        plot(t, temp_data_1.trial{1}(chan,:), 'r')
        xlabel('time (s)')
        title(sprintf('channel %d', chan))
    end
    legend('before interpolation','after interpolation')
end

%% Do badchannel replace for a portion of trials
badChannels  = 27; %Check this from satMat
badtrial = find(satMatrix(badChannels,:)==1);
temp_data_2 = temp_data_1;
cfg = [];
cfg.badchannel = ft_channelselection(badChannels, prep_data.label);
cfg.method = 'spline';
cfg.trials = badtrial;
temp = ft_channelrepair(cfg, temp_data_1);
temp_data_2.trial(badtrial) = temp.trial;
for trial = badtrial
    badchan{trial} = [badchan{trial}; badChannels];
    badEpoch_nbc(trial) = numel(unique(badchan{trial}));
end
if plotFig
    figure
    sampleChannels = badChannels;
    for iCh = 1:numel(sampleChannels)
        chan = sampleChannels(iCh);
        subplot(numel(sampleChannels),1,iCh)
        hold on
        plot(t, temp_data_1.trial{badtrial(1)}(chan,:))
        plot(t, temp_data_2.trial{badtrial(1)}(chan,:), 'r')
        xlabel('time (s)')
        title(sprintf('channel %d', chan))
    end
    legend('before interpolation','after interpolation')
end
%% Do badchannel replace trial by trial
% badEpoch_nbc = zeros(1,ntrial);
% badchan = cell(1,ntrial);
% for trial = 1:ntrial
%     fprintf('trial %d\n\n', trial);
%     satchan  = find(satMatrix(:,trial));
%     zerochan = find(sum(rawdataMat(:,:,trial),1)==0);
%     badChannels = unique([satchan(:);zerochan(:);temp_badchan(:)]);
%     badchan{trial} = badChannels;
%     disp(badChannels')
%     badEpoch_nbc(trial) = numel(badChannels);
%     %if numel(badChannels) > 16
%     %    badEpochIdx_bc(trial) = 1;
%     %end
%     
%     cfg = [];
%     cfg.trials = trial;
%     cfg.badchannel = ft_channelselection(badChannels, prep_data.label);
%     cfg.method = 'spline';
%     temp_data = ft_channelrepair(cfg, prep_data);
%     
%     prep_data.trial{trial} = temp_data.trial{1};
% end
%%
prep_data = temp_data_2;
dataMatrix = cell2mat(prep_data.trial);
dataMatrix = reshape(dataMatrix,[length(megChan), duration, ntrial]);
dataMatrix = permute(dataMatrix,[2 1 3]) * 10^15;

%%
%prepare ft data format
prep_data_eye = ft_preprocessing(struct('dataset',filename,...
    'channel',(176:178)+1,'continuous','yes','trl',trl));

%prep_data = hl_addtimetoft(prep_data,Fs,tstart,tend);
