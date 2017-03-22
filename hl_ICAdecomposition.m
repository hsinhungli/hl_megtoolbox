% Run ICA decomposition after preprocessing and visual inspection
cd /Local/Users/purpadmin/Hsin/meg_xana_SL
addpath(genpath('/users2/purpadmin/Hsin/fieldtrip-new'));
addpath(genpath('/users2/purpadmin/Hsin/meg_utils-master'));
addpath(genpath('/users2/purpadmin/Hsin/myFunc'));
addpath(genpath('/users2/purpadmin/Hsin/denoise'));
addpath(genpath('/users2/purpadmin/Hsin/hl_megtoolbox'));

ft_defaults

%%
subjid    = 'HK';
exptDir   = '/Volumes/DRIVE1/DATA/hsin/MEG/SL';
fileBase  = 'R0978_SLDC_3.9.17';

dataDir   = sprintf('%s/%s/%s', exptDir,subjid,fileBase);
preprocDir= sprintf('%s/preproc', dataDir);
figDir    = sprintf('%s/%s', preprocDir, 'figures');
analStr   = 'dhti';

ft_datafileName = sprintf('%s/%s_%s_ft.mat',dataDir,fileBase,analStr); %This is the epoched file in ft format
badEpochIdxName = sprintf('%s/%s_%s_badEpochIdx.mat',preprocDir,fileBase,analStr);
icaName =  sprintf('%s/%s_%s_ica.mat',preprocDir,fileBase,analStr);
badEpochs       = [];

% remember, these channel numbers use zero indexing
hl_loadMEGInfo;
%%
%load epoched data
fprintf('loading previous epoched ft file\n')
load(ft_datafileName);
try
    logfileName = sprintf('%s/%s/%s/log/%s_log.mat',exptDir,subjid,fileBase,subjid);
    load(logfileName);
    fprintf('log file loaded \n')
catch
    fprintf('no log fie \n')
end
load data_hdr
fprintf('loading badEpoch Information\n')
load(badEpochIdxName);

%% ICA-Preprocessing
% for tr = 1:length(prep_data.time)
%     prep_data.time{tr} = prep_data.time{tr} - prep_data.time{tr}(1);
% end
%ica.excludeIdx = bepoch.jump | bepoch.muscle;
ica.excludeIdx = badEpochIdx_all;
ica.trlno = find(ica.excludeIdx==0);
trialToKeep = 1:length(prep_data.time);
trialToKeep(ica.excludeIdx)=[]; %Exculde these trials from ICA training;
cfg=[];
cfg.trials = trialToKeep;
train_data = ft_selectdata(prep_data,'rpt',trialToKeep);
cfg=[];
cfg.resamplefs = 200;
cfg.detrend = 'no';
train_data = ft_resampledata(cfg,train_data);

%% ICA-Run ICA on Training set
cfg = [];
cfg.method = 'runica';
nrank = rank(squeeze(prep_data.trial{end}*prep_data.trial{end}'));
fprintf(1,'nRank  %s\n', num2str(nrank));
cfg.runica.pca = nrank-1;
tic;
go = input('proceed to ICA? [y/n]','s');
if go == 'y'
    comp = ft_componentanalysis(cfg, train_data);
    icatime = toc;
    save(icaName,'comp','ica');
    fprintf(1,'ICA DONE and SAVED!!');
end
%% ICA-plot components
load data_hdr.mat
for t = 1:3
    cfg = [];
    cfg.component = (30*(t-1)+1):(30*(t-1)+30);
    cfg.layout    = ft_prepare_layout(cfg, data_hdr);
    cfg.comment   = 'no';
    cpsFigure(2,2);
    ft_topoplotIC(cfg,comp);drawnow;tightfig;
    temp = sprintf('%s/%s_%s_ICAtopo_Fig%s',figDir,subjid,analStr,num2str(t));
    saveas(gcf,temp,'png'); 
    fprintf(1,'------saving %s------ \n',temp);
end

cfg = [];
cfg.colormap = jet;
cfg.layout    = ft_prepare_layout(cfg, data_hdr);
cfg.viewmode = 'component';
ft_databrowser(cfg,comp);