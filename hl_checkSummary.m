function hl_checkSummary(filename, plot_databrowser)
%For quick check
filename = '/Volumes/DRIVE1/DATA/hsin/MEG/SL/HK/R0978_SLDC_3.9.17/preproc/R0978_SLDC_3.9.17_run03_dht.sqd';

if exist('plot_databrowser','var')==0
    plot_databrowser=0;
end
%keyboard;
%% load and view data
if plot_databrowser==1
    cfg = [];
    cfg.dataset = filename;
    data_raw    = ft_preprocessing(cfg);
    
    cfg = [];
    cfg.plotlabels  = 'some';
    cfg.channel     = 1:55; %1:80/ 81:157
    cfg.axisfontsize = 12;
    cfg.fontsize    = 12;
    cfg.ylim        = [-200 200]*1e-15;
    cfg.viewmode    = 'vertical';
    ft_databrowser(cfg,data_raw);
    
    dataMat      = hl_ft2mat(data_raw);
    Fs = data_raw.fsample;
else
    [dataMat,info] = sqdread(filename);
    Fs = info.SampleRate;
end
%%
seg_duration = 1;
seg_nt       = seg_duration * Fs;
nseg         = floor(size(dataMat,1)/seg_nt);
tempMat      = dataMat(1:(nseg*seg_nt),:);
tempMat      = reshape(tempMat, seg_nt, nseg, size(tempMat,2));
tempMat      = permute(tempMat, [1 3 2]); %rearrange to time x chan x trial
satMatrix    = hl_find_saturation(tempMat(:,1:157,:), 20, 1); %chan x epoch
exMatrix     = hl_find_extreme(tempMat(:,1:157,:), 20000, 1); %chan x epoch

%% Do PDS on RAW Data
seg_duration = 5;
seg_nt       = seg_duration * Fs;
nseg         = floor(size(dataMat,1)/seg_nt);
tempMat      = dataMat(1:(nseg*seg_nt),:);
tempMat      = reshape(tempMat, seg_nt, nseg, size(tempMat,2));
tempMat      = permute(tempMat, [1 3 2]); %rearrange to time x chan x trial
[fre,pds,~,~,~,~] = getPowerDensity(tempMat,1000); %pds_tr,phs_tr,fc_tr: fre x chan x trl
pds = mean(pds(:,1:160,:).^2,3);
bl  = sqrt(circshift(pds,1) .* circshift(pds,-1));
SNR = pds./bl;

%% Plot raw data pds
cpsFigure(1,1); %Plot power spectrum for all channels
loglog(fre,pds(:,1:157)); xlim([.5 200]); ylim([10^-2 10^8]); hold on;
yl = ylim+1e-3;
loglog([60 60],[yl(1) yl(2)],'k');
loglog([30 30],[yl(1) yl(2)],'k--');
loglog([10 10],[yl(1) yl(2)],'k--');
title('PDS for all channel')
%savefig(gcf,sprintf('%s/%s_%s_allPDS_before.fig',figDir,fileBase,tag));

cpsFigure(1,1);
loglog(fre,mean(pds(:,1:157),2)); xlim([.5 200]); hold on;
title('Mean PDS over all channel')
%savefig(gcf,sprintf('%s/%s_%s_meanPDS_before.fig',figDir,fileBase,tag));

%cpsFigure(1,1) %Plot SNR for all channels
%loglog(fre,SNR(:,1:157)); xlim([.5 250]);

cpsFigure(1,1);
l=loglog(fre,nanmean(SNR(:,1:157),2),'k');%fre,nanmedian(SNR(:,1:157),2),'--b'); 
xlim([.5 250]); 
set(l,'LineWidth',2);hold on;
title('Mean SNR over all channel')
%savefig(gcf,sprintf('%s/%s_%s_SNR_before.fig',figDir,fileBase,tag));

cpsFigure(1,1); %Plot power spectrum for ref channels
loglog(fre,pds(:,158:160)); xlim([.5 250]); hold on;
yl = ylim+1e-3;
%loglog([60 60],[yl(1) yl(2)],'k');
loglog([30 30],[yl(1) yl(2)],'k--');
loglog([10 10],[yl(1) yl(2)],'k--');
title('PDS Reference Chan')
