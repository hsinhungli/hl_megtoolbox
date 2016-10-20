addpath(genpath('/users2/purpadmin/Hsin/eeglab13_4_4b'));
addpath(genpath('/users2/purpadmin/Hsin/fieldtrip'));
addpath(genpath('/users2/purpadmin/Hsin/denoise'));
addpath(genpath('/users2/purpadmin/Hsin/meg_utils'));
addpath(genpath('/users2/purpadmin/Hsin/myFunc'));

ft_defaults
%%
subjid    = 'MR';
exptDir   = '/Volumes/DRIVE1/DATA/hsin/MEG/BR';
fileBase  = 'R0983_BR_10.14.15';

dataDir     = sprintf('%s/%s/%s', exptDir,subjid,fileBase);
outFileName = sprintf('%s/%s.sqd', dataDir,fileBase);
sqdToCombine = {'R0983_BR1_10.14.15.sqd','R0983_BR2_10.14.15.sqd'};

%% make combined sqd file
sourceFile = sprintf('%s/%s', dataDir, sqdToCombine{1});
for iFile = 1:numel(sqdToCombine)
    sqdNow = sprintf('%s/%s', dataDir, sqdToCombine{iFile});
    data = sqdread(sqdNow);
    sqdwrite(sourceFile, outFileName, 'action', 'append', 'data', data);
end