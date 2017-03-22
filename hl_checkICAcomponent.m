cd /Local/Users/purpadmin/Hsin/meg_xana_SL
addpath(genpath('/users2/purpadmin/Hsin/rca-master'))
addpath(genpath('/users2/purpadmin/Hsin/fieldtrip-new'));
addpath(genpath('/users2/purpadmin/Hsin/meg_utils'));
addpath(genpath('/users2/purpadmin/Hsin/myFunc'))
addpath(genpath('/users2/purpadmin/Hsin/hl_megtoolbox'))

%% %Set data to analyze
subjid    = 'HK';
exptDir   = '/Volumes/DRIVE1/DATA/hsin/MEG/SL';
fileBase  = 'R0978_SLDC_3.9.17';
%--CP-- R1109_SL_11.8.16 --HK-- R0978_SL_11.3.16 --HL-- R0959_SL_10.31.16/R0959_SL_10.24.16/R0959_SL_10.11.16
%--ID--R0947_SL_11.29.16/R0947_SL_11.18.16 --RD-- R0817_SL_8.5.16
load data_hdr

dataDir   = sprintf('%s/%s/%s', exptDir,subjid,fileBase);
preprocDir= sprintf('%s/preproc', dataDir);
figDir    = sprintf('%s/%s', preprocDir, 'figures');
analStr   = 'dhti';

ft_datafileName = sprintf('%s/%s_%s_ft.mat',dataDir,fileBase,analStr); %This is the epoched file in ft format
icaName         =  sprintf('%s/%s_%s_ica.mat',preprocDir,fileBase,analStr);
badEpochIdxName = sprintf('%s/%s_%s_badEpochIdx.mat',preprocDir,fileBase,analStr);
logfileName     = sprintf('%s/%s/%s/log/%s_log.mat',exptDir,subjid,fileBase,subjid);

fprintf('------loading EpochInfo mat file------\n')
load(badEpochIdxName);

try
    load(logfileName);
    fprintf('------loading log file------\n')
catch
    fprintf('------no log file------\n')
end
%% Load ICA results
fprintf('------loading FT data mat file------\n')
load(ft_datafileName);
fprintf('------loading ICA comp file------\n')
load(icaName);
if isfield(ica,'badcomp')
    fprintf('!!!!!------Already have badcomp information stored-----\n')
end

%Use the ica topo to project the raw data to component time course
fprintf('------Unmixing------\n')
cfg = [];
cfg.unmixing  = comp.unmixing;
cfg.topolabel = comp.topolabel;
prep_data_com = ft_componentanalysis(cfg, prep_data);

ntrial = length(prep_data.trial);
t      = prep_data.time{1};
comMat = hl_ft2mat(prep_data_com);
clear prep_data_*

%cueTime = 600;
%condIdx  = trl.trigNumber;
%goodIdx  = trl.blockNumber>0 & badEpochIdx_stat'==0 & sac.sacgoodtrial==1 &...
%    (condIdx<=3 | (sac.sacOnset-cueTime >200  & sac.sacOnset-cueTime <=500));
condIdx = triggerNumber;
goodIdx  = badEpochIdx_all'==0;

% %% ICA-plot components
% load data_hdr.mat
% for round = 1
%     cfg = [];
%     cfg.component = (30*(round-1)+1):(30*(round-1)+30);
%     cfg.layout    = ft_prepare_layout(cfg, data_hdr);
%     cfg.comment   = 'no';
%     cpsFigure(2,2);
%     ft_topoplotIC(cfg,comp);drawnow;tightfig;
%     temp = sprintf('%s/%s_%s_ICAtopo_Fig%s',figDir,subjid,analStr,num2str(round));
%     %saveas(gcf,temp,'png'); fprintf(1,'saving %s\n',temp);
% end

%% Plot singletrial time series for component
cfg = [];
cfg.colormap = jet;
cfg.layout    = ft_prepare_layout(cfg, data_hdr);
cfg.viewmode = 'component';
ft_databrowser(cfg,comp);

%% ICA-do fft on each component
[fre,epds,~,resolution,leakageIdx,~] = getPowerDensity(comMat,1000); %pds_tr,phs_tr,fc_tr: fre x chan x trl

%% compute saccade-related statistics
count  = 0;
varMat = [];
for i = 1:ntrial
    if condIdx(i) == 6 && goodIdx(i) == 1;
        count = count+1;
        temp_init(count) = (sac.sacOnset(i)-10)/1000;
        temp_end(count)  = (sac.sacOffset(i)+10)/1000;
        temp      = comMat(t>=temp_init(count) & t<=temp_end(count),:,i);
        varMat(count,:) = var(temp);
    end
end
sac_var  = mean(varMat); %mean variance during the saccade period for each component
sac_stat = [temp_init temp_init; temp_end temp_end];

count  = 0;
varMat = [];
for i = 1:ntrial
    if condIdx(i) == 3 && goodIdx(i) == 1;
        count = count+1;
        temp_init = sac_stat(1,count);
        temp_end  = sac_stat(2,count);
        temp      = comMat(t>=temp_init & t<=temp_end,:,i);
        varMat(count,:) = var(temp);
    end
end
fix_var  = mean(varMat); %mean variance during the saccade period for each component
ratiovar = sac_var./fix_var;
[sort_var,sortcom] = sort(ratiovar,'descend');
cpsFigure(1,1); hist(ratiovar(ratiovar<4),30); title('ratio variance');
disp(['high ratio component ' num2str(sortcom(1:10))])
%% Display information for 6 components
ratiovar = nan(1,157);
round = 6;

cpsFigure(2.4,1.8)
count=0;
hshift=0;
cfg=[];
cfg.holdon    = 1;
cfg.colormap = parula;
cfg.colorbar ='no';
for c = (1:6) + 6*(round-1)
    
    subplot(3,8,count*8+1+hshift); hold on;
    temptitle = sprintf('comp %d ratio %2.2f',c,ratiovar(c));
    hl_topoplot_2d(comp.topo(:,c),[],cfg,[],temptitle); drawnow;
    
    subplot(3,8,count*8+2+hshift)
    temp = sq(comMat(:,c,goodIdx))';
    temp = [condIdx(goodIdx) reshape(zscore(temp(:)),size(temp,1),size(temp,2))];
    temp = sortrows(temp);
    temp(:,1) = [];
    imagesc(t,1:ntrial,temp,[-3 3]);
    set(gca,'YTickLabel','');
    xlabel('time');
    ylabel('trial');
    title(sprintf('comp %d',c))
    
    subplot(3,8,count*8+3+hshift)
    plot(fre,mean(epds(:,c,:),3),'LineWidth',1.5); xlim([2 80])
    %loglog(fre,mean(epds(:,comp,:).^2,3),'LineWidth',1.5); xlim([8 100])
    xlabel('fre (Hz)')
    ylabel('Amplitude');
    set(gca,'YTickLabel','');
    
    subplot(3,8,count*8+4+hshift)
    plot(t,median(comMat(:,c,goodIdx),3),'b','LineWidth',1); xlim([min(t) max(t)]);
    %plot(t,median(comMat(:,c,goodIdx & condIdx<=3),3),'b','LineWidth',1); xlim([min(t) max(t)]); hold on;
    %plot(t,median(comMat(:,c,goodIdx & condIdx>3),3),'r--','LineWidth',1); xlim([min(t) max(t)]);
    %xlabel('Time')
    %ylabel('Amplitude')
    if rem(c,2)==0
        count = count+1;
        hshift=0;
    else
        hshift=4;
    end
end
tightfig;

%% Profile for single component
c = 28;

cpsFigure(1,2)
cfg=[];
cfg.holdon    = 1;
cfg.colormap = parula;
cfg.colorbar ='no';

subplot(4,2,1); hold on;
temptitle = sprintf('comp %d ratio %2.2f',c,ratiovar(c)); 
hl_topoplot_2d(comp.topo(:,c),[],cfg,[],temptitle); drawnow;

subplot(4,2,2)
for cond = 1:6
%plot(fre,mean(epds(:,c,condIdx(goodIdx)==cond),3),'LineWidth',1); xlim([10 60]); hold on;
%loglog(fre,mean(epds(:,c,condIdx(goodIdx)==cond).^2,3),'LineWidth',1.5); xlim([8 100]); hold on;
loglog(fre,mean(epds(:,c,goodIdx==1).^2,3),'LineWidth',1.5); xlim([8 100]); hold on;
end
legend({'1','2','3','4','5','6'})
xlabel('fre (Hz)')
ylabel('Power');
set(gca,'YTickLabel','');

subplot(4,2,3:6)
temp = sq(comMat(:,c,goodIdx))';
temp = [condIdx(goodIdx) reshape(zscore(temp(:)),size(temp,1),size(temp,2))];
temp = sortrows(temp);
temp(:,1) = [];
imagesc(t,find(goodIdx),temp,[-4 4]);
set(gca,'YTickLabel','');
xlabel('time');
ylabel('trial');
title(sprintf('comp %d',c))

subplot(4,2,7:8)
%plot(t,median(comMat(:,c,goodIdx & condIdx<=3),3),'b','LineWidth',1.5); xlim([min(t) max(t)]); hold on;
%plot(t,median(comMat(:,c,goodIdx & condIdx>3),3),'r','LineWidth',1.5); xlim([min(t) max(t)]);
plot(t,median(comMat(:,c,goodIdx==1),3),'r','LineWidth',1.5); xlim([min(t) max(t)]);
xlabel('Time')
%ylabel('Amplitude')
%%
% for t = 1:2
%     cpsFigure(1.5,1.5)
%     count=0;
%     for c = (t-1)*30+1:(t-1)*30+30
%         count=count+1;
%         subplot(5,6,count)
%         %plot(fre,mean(epds(:,c,:),3),'LineWidth',1.5); xlim([10 100])
%         loglog(fre,mean(epds(:,c,:),3),'LineWidth',1.5); xlim([10 100])
%         title(['Chan ' num2str(c)]);drawnow;
%     end
%     tightfig;
%     temp = sprintf('%s/%s_%s_ICAEAS_Fig%s',figDir,subjid,analStr,num2str(t));
%     %saveas(gcf,temp,'fig'); fprintf(1,'saving %s\n',temp);
% end

%%
ica.badcomp = [];
ica.badcomp.rmweird  = [16 17 26 28];
ica.badcomp.car      = [7 8];
ica.badcomp.eye      = [1 15 18];
ica.badcomp.thirtyH  = [];
ica.badcomp.other    = [3];
ica.eyethres = 1.2;
%33   41   21   13   56  127   35  106   30    4
ica.badcomp.eyethres = find(ratiovar>=ica.eyethres);
ica.badcomp.eyethres=[];
disp(ica.badcomp)
dummy = input('proceed to save ica information and badcomp? [y\n]','s');
if strcmp(dummy,'y')
    save(icaName,'comp','ica');
    fprintf('------ICA Saved------\n')
end