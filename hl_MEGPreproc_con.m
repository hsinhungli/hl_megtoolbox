function preprocFileName = hl_MEGPreproc_con(filename, figDir, badChannels,rnum)

%%
%filename = '/Volumes/DRIVE1/DATA/hsin/MEG/BR/LH/R0959_BR_6.2.15/preproc/R0959_BR_6.2.15_run01.sqd';
%figDir   = '/Volumes/DRIVE1/DATA/hsin/MEG/BR/LH/R0959_BR_6.2.15/preproc/figures';
%% Get the MEG data
% data is time x channels
fprintf('----------loading original sqd data----------\n')
[data,info] = sqdread(filename); %time x channel

Fs = info.SampleRate;
nt = info.SamplesAvailable;
t  = 0: 1/Fs : (nt-1)*(1/Fs);
%%
% remember, these channel numbers use zero indexing
megChannels       = 0:156;
refChannels       = 157:159;
triggerChannels   = 160:167;
photodiodeChannel = 191;
plotChannels      = 19; 

if nargin < 3
    badChannels = [];
end

% Set preproc options
removeBadChannels    = 1;
applyHighPassFilter  = 0;
applyLineNoiseFilter = 1;
environmentalDenoise = 1;
runTSPCA             = 0;
interpolate          = 0;

hpfreq   = 1;
linefreq = 60;

plotFig   = 1;
saveFig   = 1;
plotrange = 100; %second
analStr   = []; %The trace of steps of preprocessing done
if exist('plotrange','var') && ~isempty(plotrange)
    trange = t(1:plotrange*Fs);
    ntplot = length(trange);
else
    trange = t;
    ntplot = nt;
end
%% Set aside data from special channels
% add 1 to adjust for zero-indexing
refData  = data(:,refChannels+1);
trigData = data(:,triggerChannels+1);
pdData   = data(:,photodiodeChannel+1);

%% Look at special channels
if plotFig
    cpsFigure(1,1)
    subplot(3,1,1)
    plot(trange,refData(1:ntplot,:))
    title(['reference channels' num2str(refChannels)])
    subplot(3,1,2)
    plot(trange,trigData(1:ntplot,:))
    legend(num2str(triggerChannels'))
    title(['trigger channels' num2str(triggerChannels)])
    subplot(3,1,3)
    plot(trange,pdData(1:ntplot))
    title(['photodiode channel' num2str(photodiodeChannel)])
    xlabel('time (s)')
end
%% Find bad channel
if removeBadChannels
    fprintf('----------removeBadChannels----------\n')
    analStr = [analStr 'b'];
    
    % high or low variance across the entire time series
    outlierSDChannels = meg_find_bad_channels(permute(data(:,megChannels+1),[1 3 2])); %Not Zero Index
    
    % dead or saturating channels for all or portions of the time series
    % (dont do this if planning to run saturation and interpolation on
    % trial basis.
    deadChannels = checkForDeadChannels(filename)+1; %Zero Index
    %deadChannels = [];
    
    % aggregate the bad channels
    badChannels = unique([badChannels outlierSDChannels' deadChannels]);
    nBad = numel(badChannels);
    
    % plot the time series for the bad channels
    if plotFig
        cpsFigure(1,1)
        for iBad = 1:nBad
            subplot(nBad,1,iBad)
            chan = badChannels(iBad);
            plot(t, data(:,chan))
            title(sprintf('channel %d', chan))
        end
        xlabel('time (s)')
    end
    
    % zero out bad channels
    % check with the user that this looks good
%     disp(badChannels)
%     go = input('Replace these channel? [y,n]','s');
%     if ~strcmp(go,'y')
%         fprintf('\nNot replacing\n\n')
%         return
%     else 
%         fprintf('\nReplacing badchannels\n\n')
%         data(:,badChannels) = 0;
%     end
    data(:,badChannels) = 0;
end
%% Filtering: only on MEG channels
if applyHighPassFilter
    fprintf('----------applyHighpassFilter----------\n')
    analStr = [analStr 'h'];
    
    % data should be channels x time
    temp_data = data(:,megChannels+1);
    temp_data = ft_preproc_highpassfilter(temp_data', Fs, hpfreq);
    temp_data = temp_data';
    
    if plotFig
        cpsFigure(1,.4)
        plot(trange,temp_data(1:ntplot,plotChannels+1),'r'); hold on;
        plot(trange,data(1:ntplot,plotChannels+1),'b');
        legend({'filtered','raw'})
        xlabel('time (s)')
        drawnow;
    end
    
    data(:,megChannels+1) = temp_data;
    clear temp_data;
end
%% Line noise filter
if applyLineNoiseFilter
    fprintf('----------applyLineNoiseFilter----------\n')
    analStr = [analStr 'l'];
    
    % data should be channels x time
    data = ft_preproc_dftfilter(data', Fs, linefreq);
    data = data';
end
%% Denoise using reference channels
if environmentalDenoise %Regress out the components correlated with the reference channels; also center the mean of entire timeseries to zero
    fprintf('----------environmentalDenoise----------\n')
    % See also LSdenoise.m
    analStr = [analStr 'e'];
    
    data = permute(data,[1 3 2]);
    data = meg_environmental_denoising(data, refChannels+1, megChannels+1, plotFig); 
    data = permute(data,[1 3 2]); % convert back
end
%% Save data preprocessed up to this point
preFile = sprintf('%s_%s.sqd', filename(1:end-4), analStr);
bcFile  = sprintf('%s_%s_badchan.mat', filename(1:end-4), analStr);

if exist(preFile,'file')
    error('%s_%s.sqd already exists ... will not overwrite. exiting.', filename(1:end-4), analStr)
else
    fprintf('----------saving intermediate preprocessed file----------\n')
    sqdwrite(filename, preFile, 'data', data);
    save(bcFile,'badChannels','outlierSDChannels','deadChannels')
end

%% TSPCA
if runTSPCA == 1
    fprintf('----------removeBadChannels----------\n')
    analStr = [analStr 't'];
    
    sizeOfBlocks = 50000;
    shifts       = -50:50;
    nearNeighbor = 0; %set as zero so we don't use SNS denoising
    tspcaFile    = sprintf('%s_%s.sqd', filename(1:end-4), analStr);
    sqdDenoise(sizeOfBlocks, shifts, nearNeighbor, preFile, badChannels-1, 'no',167, 'no', tspcaFile);
    
    if plotFig
        [data_tspca,~] = sqdread(tspcaFile);
        
        figure
        subplot(4,1,1)
        chan = 5;
        plot(trange,data_tspca(1:ntplot,chan)); hold on;
        plot(trange,data(1:ntplot,chan));
        title(['channel 4' num2str(refChannels)])
        
        subplot(4,1,2)
        plot(trange,data_tspca(1:ntplot,refChannels+1)); hold on;
        plot(trange,refData(1:ntplot,:))
        title(['reference channels' num2str(refChannels)])
        
        subplot(4,1,3)
        plot(trange,trigData(1:ntplot,:))
        legend(num2str(triggerChannels'))
        title(['trigger channels' num2str(triggerChannels)])
        
        subplot(4,1,4)
        plot(trange,pdData(1:ntplot,:))
        title(['photodiode channel' num2str(photodiodeChannel)])
        xlabel('time (s)')
        drawnow;
    end
end

%% Interpolate to replace bad channels
if interpolate
    fprintf('----------interpolate BadChannels----------\n')
    analStr = [analStr 'i'];
    
    % read data into ft structure in continuous mode by initializing cfg with
    % only the dataset
    % ft data is channels x time
    if runTSPCA == 1
        preFile = tspcaFile;
    end
    
    cfg         = [];
    cfg.dataset = preFile;
    ft_data     = ft_preprocessing(cfg); % this preserves the data, but scales it by like 10^-13
    ft_data.trial{1} = data'; % so just replace data with the original data
    
    cfg = [];
    g = sprintf('%d ',badChannels);
    fprintf('Bad Channels: %s\n',g);
    cfg.badchannel = ft_channelselection(badChannels, ft_data.label);
    cfg.method = 'spline';
    ft_data = ft_channelrepair(cfg, ft_data);
    
    % compare before and after interpolation
    if plotFig
        figure
        sampleChannels = badChannels;
        for iCh = 1:numel(sampleChannels)
            chan = sampleChannels(iCh);
            subplot(numel(sampleChannels),1,iCh)
            hold on
            plot(t, data(:,chan))
            plot(t, ft_data.trial{1}(chan,:), 'r')
            xlabel('time (s)')
            title(sprintf('channel %d', chan))
        end
        legend('before interpolation','after interpolation')
    end
    
     % save the interpolated data
    data(:,1:numel(megChannels)) = ft_data.trial{1}';
    
    interpFile = sprintf('%s_%s.sqd', filename(1:end-4), analStr);
    sqdwrite(filename, interpFile, 'data', data);
    delete(preFile);
end
%% Check the triggers
hl_checkTriggers(filename);

%% save figs
if saveFig
    figSubDir = sprintf('%s/%s/run%02d', figDir, analStr, rnum);
    if ~exist(figSubDir,'dir')
        mkdir(figSubDir)
    end
    hl_saveallfig(figSubDir)
    close all
end

%% return preproc file name
preprocFileName = sprintf('%s_%s.sqd', filename(1:end-4), analStr);
