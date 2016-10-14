% For visual inspection after the first-stage preprocessing has been done.
% The preprocessed file should have an tag defined by analStr in its
% filename. This script calls that preprocessed file for visual inspection
%addpath(genpath('/users2/purpadmin/Hsin/eeglab13_4_4b'));
addpath(genpath('/users2/purpadmin/Hsin/fieldtrip'));
addpath(genpath('/users2/purpadmin/Hsin/meg_utils-master'));
addpath(genpath('/users2/purpadmin/Hsin/myFunc'));
addpath(genpath('/users2/purpadmin/Hsin/denoise'));
addpath(genpath('/users2/purpadmin/Hsin/hl_megtoolbox'));

ft_defaults

%%
subjid    = 'HL';
exptDir   = '/Volumes/DRIVE1/DATA/hsin/MEG/SL';
fileBase  = 'R0959_SL_10.11.16';

dataDir   = sprintf('%s/%s/%s', exptDir,subjid,fileBase);
preprocDir= sprintf('%s/preproc', dataDir);
figDir    = sprintf('%s/%s', preprocDir, 'figures');
analStr   = 'bhlei';
fileName  = sprintf('%s/%s_%s.sqd',preprocDir,fileBase,analStr);
ft_datafileName = sprintf('%s/%s_%s_ft.mat',dataDir,fileBase,analStr); %This is the epoched file in ft format
dataMatrixName  = sprintf('%s/%s_%s_dataMatrix.mat',dataDir,fileBase,analStr); %This is the epoched data in a matrix
satInfoName     = sprintf('%s/%s_satInfo.mat',preprocDir,fileBase);
%satMatrixName   = sprintf('%s/%s_satMatrix.mat',preprocDir,fileBase);
badEpochIdxName = sprintf('%s/%s_%s_badEpochIdx.mat',preprocDir,fileBase,analStr);
badEpochs       = [];

% remember, these channel numbers use zero indexing
hl_loadMEGInfo;

loaddataMatrix  = 1;
saveEpochedFile = 0;
savedataMatrix  = 0;
getsatMatrix    = 1;
%% get epoch from continuous data
if exist(ft_datafileName,'file') == 0  %Check whether this sqd file has been epoched before and saved already
    fprintf('generating epoched file\n')
    
    tstart = -500;
    tend   = 3000;
    t      = tstart:tend;
    [trl,triggerNumber] = hl_gettrlinfo(fileName, trigChan, tstart, tend);
    ntrial = size(trl,1);
    
    prep_data = ft_preprocessing(struct('dataset',fileName,...
        'channel','MEG','continuous','yes','trl',trl));
    if saveEpochedFile == 1
        fprintf('saving new epoched file in ft structure\n')
        save(ft_datafileName, 'prep_data','-v7.3');
    end
    if savedataMatrix == 1;
        fprintf('saving dataMatrix in mat file\n')
        dataMatrix = cell2mat(prep_data.trial);
        dataMatrix = reshape(dataMatrix,[length(megChan), length(t), ntrial]);
        dataMatrix = permute(dataMatrix,[2 1 3]) * 10^15; %dataMatrix: time x chan x epoch
        save(dataMatrixName,'dataMatrix','tstart','tend','triggerNumber','Fs','t','-v7.3');
    end
else
    %load epoched data
    fprintf('loading previous epoched ft file\n')
    load(ft_datafileName)
    if loaddataMatrix == 1;
        fprintf('loading previous epoched dataMatrix\n')
        load(dataMatrixName)
    end
    load(satInfoName);
end
try
    logfileName = sprintf('%s/%s/%s/log/%s_log.mat',exptDir,subjid,fileBase,subjid);
    load(logfileName);
    fprintf('log file loaded \n')
catch
    fprintf('no log fie \n')
end

load data_hdr
nepoch = size(dataMatrix,3);
artfMat = [];
bepoch.nbad = zeros(1,nepoch);
bepoch.auto = zeros(1,nepoch);
bepoch.var = zeros(1,nepoch);
bepoch.kur = zeros(1,nepoch);
bepoch.skew = zeros(1,nepoch);
bepoch.jump = zeros(1,nepoch);
bepoch.muscle = zeros(1,nepoch);
bepoch.slow = zeros(1,nepoch);
bepoch.man_ver = zeros(1,nepoch);
bepoch.man_bf = zeros(1,nepoch);
%% Compare trigger
cpsFigure(1,.5);
subplot(3,1,1)
plot(triggerNumber,'o')
title('MEG triggerFile')
subplot(3,1,2)
plot(trl.trigNumber,'o')
title('Log record')
subplot(3,1,3)
plot(triggerNumber,'o'); hold on; plot(trl.trigNumber,'ko'); legend('MEG','logfile')
fprintf(1,'There are %d inconsistent trial \n',sum(triggerNumber~=trl.trigNumber));
disp(find(triggerNumber~=trl.trigNumber))
%% Get saturation matrix
%eegplot(permute(dataMatrix,[2 1 3]),'srate',Fs,'winlength',1,'dispchans',80);
%eegplot(dataMatrix,'srate',Fs,'winlength',20,'dispchans',80,'position',windowSize);

% windowSize  = 20;
% plotFig     = 1;
% rawfileName = sprintf('%s/%s.sqd',dataDir,fileBase);
% [rawdataMatrix,trigger,Fs] = hl_getData(rawfileName, trigChan, megChan+1, tstart, tend);
% satMatrix   = hl_find_saturation(rawdataMatrix, windowSize, plotFig);
% save(satMatrixName,'satMatrix');
% clear rawdataMatrix

%% ICA
% cfg     = [];
% badChan = [21 65 41 120 153];
% chan_to_run = megChan+1;
% chan_to_run(badChan) = [];
% cfg.channel = megChan+1;
% cfg.method  = 'runica';
% cfg.numcomponent = 50;
% ica_data_set = ft_componentanalysis(cfg,prep_data);
%% Browse data first to select badh channel that has not interpolated (across trials): grand mode
cfg            = [];
cfg.continuous = 'no';
cfg.channel    = 1:50;
cfg.ylim       = [-1500 1500]*1e-15;
cfg.viewmode   = 'butterfly';
ft_databrowser(cfg,prep_data);

%% Browse data first to select badh channel that has not interpolated (across trials): vertical mode
cfg             = [];
cfg.continuous  = 'no';
cfg.plotlabels  = 'some';
cfg.channel     = 1:80; %1:80/ 81:157
cfg.axisfontsize = 30;
cfg.fontsize    = 30;
cfg.ylim        = [-200 200]*1e-15;
cfg.viewmode    = 'vertical';
ft_databrowser(cfg,prep_data);

%%%%% do hl_ibadchannel at this point. %%%%%

%% Amp Spectrum of each channel
% [fre,pds_tr,~,resolution,~] = getPowerDensity(dataMatrix,Fs);
% pds_ave = squeeze(mean(pds_tr,3));
% semilogx(fre(fre>2 & fre<60),pds_ave(fre>2 & fre<60,:));
% xlim([1 60]);

%% Check bad epoch using variance of channel and number of bad channel withn an epoch
nbad_thres = 10;
bepoch.nbad = badEpoch_nbc>=nbad_thres; %badEpoch_nbc is from the satMatrix in epoch stage
disp(find(bepoch.nbad)')

var_thresh = [.1 10]; 
nbadchannel_thresh = 10;

%Do this separately for neutral and saccade condition
%[temp, ~, ~] = hl_find_bad_epoch(permute(dataMatrix,[1 3 2]), var_thresh, nbadchannel_thresh, 1);

%Neutral condition
condIdx = trl.trigNumber<=6;
trlLUT  = find(condIdx);
tempMatrix = dataMatrix(:,:,condIdx);
[temp_n, ~, ~] = hl_find_bad_epoch(permute(tempMatrix,[1 3 2]), var_thresh, nbadchannel_thresh, 1);
temp_n = trlLUT(temp_n);

%Saccade condition
condIdx = trl.trigNumber>6;
trlLUT  = find(condIdx);
tempMatrix = dataMatrix(:,:,condIdx);
[temp_s, ~, ~] = hl_find_bad_epoch(permute(tempMatrix,[1 3 2]), var_thresh, nbadchannel_thresh, 1);
temp_s = trlLUT(temp_s);

bepoch.auto([temp_n;temp_s]) = 1;
disp(find(bepoch.auto))

%% Check variance and kurtosis for each trial
var_ub = 2; 
kur_ub = 2;
skew_b = 3;
[bepoch.var, bepoch.kur, bepoch.skew] = hl_trialvariance(dataMatrix, var_ub, kur_ub, skew_b);
figure;
plot(1:size(dataMatrix,3),bepoch.var,'o',1:size(dataMatrix,3),bepoch.kur*2,'o',1:size(dataMatrix,3),bepoch.skew*3,'o')
title('bad epochs VarKurSkew','FontSize',18); colormap(gray); hold on;
%% ft_rejectvisual (summary mode)
% cfg           = [];
% cfg.ylim      = 1e-12;  % scaling (10 fT/cm)
% cfg.megscale  = 1;
% cfg.channel   = 'MEG';
% cfg.keeptrial = 'nan';
% dummy         = ft_rejectvisual(cfg,prep_data);
% 
% bepoch.summary = zeros(1, length(dummy.trial));
% for ievent = 1:length(dummy.trial)
%     bepoch.summary(ievent) = isnan(dummy.trial{ievent}(1));
%     if bepoch.summary(ievent) == 1;
%         fprintf('Trial %d selected as a bad trial\n', ievent)
%     end
% end
% fprintf('There are %d bad trials selected in this dataset\n',sum(bepoch.summary))
% cpsFigure(.5,1.5);
% imagesc(bepoch.summary'); title('bad epochs summary','FontSize',18); colormap(gray); hold on;
% tempIdx = bepoch.auto' | bepoch.summary;
% disp(find(tempIdx))

%% jump detection
cfg = [];
cfg.continuous = 'no';
 
% channel selection, cutoff and padding
cfg.artfctdef.zvalue.channel    = 'MEG';
cfg.artfctdef.zvalue.cutoff     = 40;
cfg.artfctdef.zvalue.trlpadding = 0;
cfg.artfctdef.zvalue.artpadding = 0;
cfg.artfctdef.zvalue.fltpadding = 0;
 
% algorithmic parameters
cfg.artfctdef.zvalue.cumulative    = 'yes';
cfg.artfctdef.zvalue.medianfilter  = 'yes';
cfg.artfctdef.zvalue.medianfiltord = 9;
cfg.artfctdef.zvalue.absdiff       = 'yes';
 
% make the process interactive
cfg.artfctdef.zvalue.interactive = 'yes';
 
[~, artifact_jump] = ft_artifact_zvalue(cfg,prep_data);
bepoch.jump(hl_sample_to_epoch(artifact_jump,prep_data.sampleinfo))=1;

% Check the epochs detected
cfg             = [];
cfg.continuous  = 'no';
cfg.plotlabels  = 'some';
cfg.channel     = 81:157; %1:80;  81:157
cfg.ylim        = [-200 200]*1e-15;
cfg.viewmode    = 'vertical';
cfg.artfctdef.visual.artifact = [artifact_jump(:,1)-10 artifact_jump(:,1)+10];
ft_databrowser(cfg,prep_data);

%% muscle detection
cfg = [];
cfg.continuous = 'no';
 
% channel selection, cutoff and padding
cfg.artfctdef.zvalue.channel    = 'MEG';
cfg.artfctdef.zvalue.cutoff     = 25;
cfg.artfctdef.zvalue.trlpadding = 0;
cfg.artfctdef.zvalue.artpadding = 0;
cfg.artfctdef.zvalue.fltpadding = 0;
 
% algorithmic parameters
cfg.artfctdef.zvalue.bpfilter    = 'yes';
cfg.artfctdef.zvalue.bpfreq      = [110 140];
cfg.artfctdef.zvalue.bpfiltord   = 9;
cfg.artfctdef.zvalue.bpfilttype  = 'but';
cfg.artfctdef.zvalue.hilbert     = 'yes';
cfg.artfctdef.zvalue.boxcar      = 0.2;

% make the process interactive
cfg.artfctdef.zvalue.interactive = 'yes';
 
[~, artifact_muscle] = ft_artifact_zvalue(cfg,prep_data);
bepoch.muscle(hl_sample_to_epoch(artifact_muscle,prep_data.sampleinfo))=1;

% Check the epochs detected
cfg             = [];
cfg.continuous  = 'no';
cfg.plotlabels  = 'some';
cfg.channel     = 1:2:157; %1:80;  81:157
cfg.ylim        = [-200 200]*1e-15;
cfg.viewmode    = 'vertical';
cfg.artfctdef.visual.artifact = artifact_muscle;
ft_databrowser(cfg,prep_data);

%% Slow stuff
cfg = [];
cfg.continuous = 'no';
 
% channel selection, cutoff and padding
cfg.artfctdef.zvalue.channel    = 'MEG';
cfg.artfctdef.zvalue.cutoff     = 8;
cfg.artfctdef.zvalue.trlpadding = 0;
cfg.artfctdef.zvalue.artpadding = 0;
cfg.artfctdef.zvalue.fltpadding = 0;
 
% algorithmic parameters
cfg.artfctdef.zvalue.lpfilter    = 'yes';
cfg.artfctdef.zvalue.lpfreq      = 5;
%cfg.artfctdef.zvalue.hilbert     = 'yes';
%cfg.artfctdef.zvalue.boxcar      = 0.2;

% make the process interactive
cfg.artfctdef.zvalue.interactive = 'yes';
 
[~, artifact_slow] = ft_artifact_zvalue(cfg,prep_data);
bepoch.slow(hl_sample_to_epoch(artifact_muscle,prep_data.sampleinfo))=1;

% Check the epochs detected
cfg             = [];
cfg.continuous  = 'no';
cfg.plotlabels  = 'some';
cfg.channel     = 1:2:157; %1:80;  81:157
cfg.ylim        = [-200 200]*1e-15;
cfg.viewmode    = 'vertical';
cfg.artfctdef.visual.artifact = artifact_slow;
ft_databrowser(cfg,prep_data);

artifact_stat = hl_epoch_to_sample(find(bepoch.var|bepoch.kur|bepoch.skew|bepoch.auto|...
    bepoch.muscle|bepoch.jump|bepoch.slow),prep_data.sampleinfo);

%% ft_databrowser
cfg          = [];
cfg.continuous  = 'no';
cfg.plotlabels  = 'some';
cfg.channel     = 1:2:157;
cfg.axisfontsize = 30;
cfg.fontsize    = 30;
cfg.ylim        = [-200 200]*1e-15;
cfg.viewmode    = 'vertical';
%cfg.blocksize   = 10;
cfg.artfctdef.visual.artifact = artifact_stat;
artf            = ft_databrowser(cfg,prep_data);
artfMat_ver     = [artf.artfctdef.visual.artifact];
bepoch.man_ver(hl_sample_to_epoch(artf.artfctdef.visual.artifact, prep_data.sampleinfo))=1;

% artf.artfctdef.reject = 'nan';
% dummy = ft_rejectartifact(artf,prep_data);
% 
% bepoch.man_ver = zeros(1, length(dummy.trial));
% for ievent = 1:length(dummy.trial)
%     tempIdx = sum(isnan(dummy.trial{ievent}(:)));
%     if tempIdx ~= 0;
%         bepoch.man_ver(ievent) = 1;
%         fprintf('Trial %d marked with artifact \n', ievent)
%     elseif tempIdx == 0
%         bepoch.man_ver(ievent) = 0;
%     end
% end

cpsFigure(.5,1.5);
imagesc(bepoch.man_ver'); title('bepoch.man_ver','FontSize',18); colormap(gray); hold on;

%% ft_databrowser: Butterfly: Grand
disp(find(bepoch.auto|bepoch.var|bepoch.kur|bepoch.skew|bepoch.jump|bepoch.muscle|bepoch.slow|bepoch.man_ver))
cfg            = [];
cfg.continuous = 'no';
cfg.channel    = 1:2:157;
cfg.ylim       = [-2000 2000]*1e-15;
cfg.viewmode   = 'butterfly';
cfg.artfctdef.visual.artifact = artfMat_ver;
artf           = ft_databrowser(cfg,prep_data);
artfMat_bf     = [artf.artfctdef.visual.artifact];
bepoch.man_bf(hl_sample_to_epoch(artf.artfctdef.visual.artifact, prep_data.sampleinfo))=1;

% artf.artfctdef.reject = 'nan';
% dummy = ft_rejectartifact(artf,prep_data);
% 
% bepoch.man_bf = zeros(1, length(dummy.trial));
% for ievent = 1:length(dummy.trial)
%     tempIdx = sum(isnan(dummy.trial{ievent}(:)));
%     if tempIdx ~= 0;
%         bepoch.man_bf(ievent) = 1;
%         fprintf('Trial %d marked with artifact \n', ievent)
%     elseif tempIdx == 0
%         bepoch.man_bf(ievent) = 0;
%     end
% end

cpsFigure(.5,1.5);
imagesc(bepoch.man_bf'); title('bepoch.man_bf','FontSize',18); colormap(gray); hold on;

%% ft_databrowser: Butterfly: Eye
% cfg          = [];
% cfg.continuous = 'no';
% %cfg.channel    = [151,156,92,136,125,127,154,123,89,142,128,117,116,99,85,83,150,152,143,8,10,11,148,147,48,39,37]; %This is not zero Indexing!!
% cfg.channel     = [...
%     142 153 152 143 8 10 11 88 78 77 95 94 73 74 72 ...
%     150 149 148 147 48 39 37 66 68 32 36 52 51 ...
%     82 55 123 154 108 127 125 136 128 117 116 118 99 85]+1;
% hl_ShowChannel(cfg.channel,data_hdr)
% cfg.ylim       = [-3 3] * 1e-12;
% cfg.viewmode   = 'butterfly';
% cfg.artfctdef.visual.artifact = artfMat;
% artf           = ft_databrowser(cfg,prep_data);
% artfMat        = [artfMat; artf.artfctdef.visual.artifact];
% 
% artf.artfctdef.reject = 'nan';
% dummy = ft_rejectartifact(artf,prep_data);
% 
% bepoch.man_eye = zeros(1, length(dummy.trial));
% for ievent = 1:length(dummy.trial)
%     tempIdx = sum(isnan(dummy.trial{ievent}(:)));
%     if tempIdx ~= 0;
%         bepoch.man_eye(ievent) = 1;
%         fprintf('Trial %d marked with artifact \n', ievent)
%     elseif tempIdx == 0
%         bepoch.man_eye(ievent) = 0;
%     end
% end
%%
badEpochIdx_stat = bepoch.var|bepoch.kur|bepoch.skew|bepoch.auto|bepoch.muscle|bepoch.jump|bepoch.slow;
badEpochIdx_man  = bepoch.man_bf;
badEpochIdx_all  = badEpochIdx_stat | badEpochIdx_man;
cpsFigure(1,1.2);
subplot(1,2,1)
imagesc(badEpochIdx_all'); title('badEpochIdx all','FontSize',18); colormap(gray);
subplot(1,2,2)
imagesc(badEpochIdx_stat'); title('badEpochIdx stat','FontSize',18); colormap(gray);
%save(badEpochIdxName,'badEpochIdx_all','badEpochIdx_stat','badEpochIdx_man','bepoch.auto','bepoch.man_bf','bepoch.man_ver','bepoch.summary');
save(badEpochIdxName,'badEpochIdx_stat','badEpochIdx_man','badEpochIdx_all');
fprintf('%2.2f percentage of epochs marked as bad by stat \n',mean(badEpochIdx_stat)*100);
fprintf('%2.2f percentage of epochs marked as bad by all \n',mean(badEpochIdx_all)*100);