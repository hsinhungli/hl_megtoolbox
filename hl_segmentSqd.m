function nSegments = hl_segmentSqd(fileName)
%
% function nRuns = rd_segmentSqd(fileName)
%
% Chunk data into smaller segments. Segments data between runs, based on 
% triggers.
%
% The variable nTrigsPerSegment will determined the number of segments to
% be made.
%
% *This function contain some varialbes that should be implemented in
% individual experiment. Copy this file to folder of the experiment in
% interest and use it there.
%
% Rachel Denison
% September 2014
% Hsin-Hung Li
% June 2015
%% setup
% subjid    = 'LH';
% exptDir   = '/Volumes/DRIVE1/DATA/hsin/MEG/BR';
% fileBase  = 'R0959_BR_6.2.15';
% dataDir   = sprintf('%s/%s/%s', exptDir,subjid,fileBase);
% fileName  = sprintf('%s/%s.sqd',dataDir,fileBase);

% file out
segmentLabel = 'run';

% trigger
trigChans = 160:167;

% segmentation options
segmentationOption = 'selectData'; % 'splitData' or 'selectData'
segmentCushion = 2; % used only if 'selectData'

% experiment info
nTrigsExpected   = 32*14;
nTrigsPerSegment = 96;
trialDur         = 3;
%% display sqd info
info = sqdread(fileName,'info')

%% read in all triggers
triggers = all_trigger(fileName, trigChans);
%triggers = hl_recoverTrig;
nTrigs   = size(triggers,1);
fprintf('Found %d triggers\n',nTrigs);
figure
plot(triggers(:,1),triggers(:,2),'.')
title('original triggers')
%% check and inspect triggers
if nTrigs~=nTrigsExpected
    fprintf('Found %d triggers, but expected %d!\n', nTrigs, nTrigsExpected)
    
    figure
    plot(triggers(:,1),triggers(:,2),'.')
    title('original triggers')
    
    fprintf('\nExiting to allow manual adjustments ...\n')
    return
end

%% exclude stray triggers
% manual (different for each subject)
% if nTrigs>nTrigsExpected
%     excludedTrigIdxs = nTrigsPerRun*6 + 1;
%     triggers(excludedTrigIdxs,:) = [];
%     nTrigs = size(triggers,1);
% 
%     fprintf('\nNow there are %d triggers (%d expected)\n\n', nTrigs, nTrigsExpected)
%     figure
%     plot(triggers(:,1),triggers(:,2),'.')
%     title('after trigger exclusion')
% end
%% specify data segments
Fs = info.SampleRate;

%nTrigsPerSegment = nRunsPerSegment*nTrigsPerRun;
segmentFirstTrialIdxs       = 1:nTrigsPerSegment:nTrigs;
segmentLastTrialIdxs        = [segmentFirstTrialIdxs(2:end)-1 nTrigs];
segmentFirstTrialStartTimes = triggers(segmentFirstTrialIdxs,1);
segmentLastTrialEndTimes    = triggers(segmentLastTrialIdxs,1) + trialDur*Fs;

switch segmentationOption
    case 'splitData'
        % % divide segments halfway through last trial end and first trial start of
        % % subsequent segments
        segmentDividePoints = mean([segmentLastTrialEndTimes(1:end-1) segmentFirstTrialStartTimes(2:end)],2)';
        segmentStartTimes = [int64(1) segmentDividePoints];
        segmentEndTimes = [segmentDividePoints+1 int64(info.SamplesAvailable)];
    case 'selectData'
        segmentStartTimes = segmentFirstTrialStartTimes - segmentCushion*Fs;
        segmentEndTimes   = segmentLastTrialEndTimes + segmentCushion*Fs;
    otherwise
        error('segmentationOption not found')
end
nSegments = numel(segmentStartTimes);

%% read data segments and write new sqd file
for iSegment = 1:nSegments
    % read segment data from original file
	segment = sqdread(fileName, 'Samples', [segmentStartTimes(iSegment) segmentEndTimes(iSegment)]);
    
    % new segment file name
    segmentFileName = sprintf('%s_%s%02d.sqd', fileName(1:end-4), segmentLabel, iSegment);
    
    % write segment file 
    fprintf('Writing sqd: %s %d\n', segmentLabel, iSegment) 
    sqdwrite(fileName, segmentFileName, 'Data', segment);
    
    % check triggers in new file
    hl_checkTriggers(segmentFileName,[],1);
    title(sprintf('%s %d', segmentLabel, iSegment)) 
end
