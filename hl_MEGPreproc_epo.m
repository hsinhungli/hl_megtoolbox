function [prep_data,dataMatrix,triggerNumber,satMatrix,badEpochIdx_bc] = hl_MEGPreproc_epo(filename,tstart,tend,windowsize)

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
megChan   = 0:156;
refChan   = 157:159;
trigChan  = 160:163;  %This can be 160~167 if ALL the trigger channels are used in the experiment
photoChan = 191;
getChan   = megChan;

%% Get Saturation matrix
% plotFig     = 1;
% [rawdataMatrix,~,~] = hl_getData(filename, trigChan, megChan+1, tstart, tend);
% satMatrix   = hl_find_saturation(rawdataMatrix, windowSize, plotFig);
%save(satMatrixName,'satMatrix');
%clear rawdataMatrix

%% Epoch the data into fieldtrip format and do bad channel replacement
[trl,triggerNumber] = hl_gettrlinfo(filename, trigChan, tstart, tend);
ntrial  = size(trl,1);

prep_data = ft_preprocessing(struct('dataset',filename,...
    'channel','MEG','continuous','yes','trl',trl));
rawdataMat = cell2mat(prep_data.trial);
rawdataMat = reshape(rawdataMat,[length(megChan), length(t), ntrial]);
rawdataMat = permute(rawdataMat,[2 1 3]) * 10^15;

% Get saturation info
plotFig = 1;
satMatrix  = hl_find_saturation(rawdataMat, windowsize, plotFig); %chan x epoch
% check with the user that this looks good
drawnow;
go = input('Procede to bad channel interpolation? [y,n]','s');
if ~strcmp(go,'y')
    fprintf('\nNo interpolation\n\n')
    return
else
    fprintf('\nBad chan interpolation\n\n')
end
%% Do badchannel replace trial by trial
badEpoch_nbc = zeros(1,ntrial);
for trial = 1:ntrial
    fprintf('trial %d\n\n', trial);
    satchan  = find(satMatrix(:,trial));
    zerochan = find(sum(rawdataMat(:,:,trial),1)==0);
    badChannels = unique([satchan' zerochan]);
    
    badEpoch_nbc(trial) = numel(badChannels);
    %if numel(badChannels) > 16
    %    badEpochIdx_bc(trial) = 1;
    %end
    
    cfg = [];
    cfg.trials = trial;
    cfg.badchannel = ft_channelselection(badChannels, prep_data.label);
    cfg.method = 'spline';
    temp_data = ft_channelrepair(cfg, prep_data);
    
    prep_data.trial{trial} = temp_data.trial{1};
end

dataMatrix = cell2mat(prep_data.trial);
dataMatrix = reshape(dataMatrix,[length(megChan), length(t), ntrial]);
dataMatrix = permute(dataMatrix,[2 1 3]) * 10^15;
