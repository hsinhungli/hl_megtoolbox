function [dataMatrix,trigger,Fs] =  hl_getData(filename, trigChan, channels, tstart, tend)
% tstart: pretrigger duration
% tend: posttrigger duration
% channels to select
% trigChan: trigger Channel
% filename: sqd file name
% THe output is 3D dataMatrix: time x channel x nepoch

% testing parameter
% filename = '/Volumes/DRIVE1/DATA/hsin/MEG/BR/LH/R0959_BR_6.2.15/preproc/R0959_BR_6.2.15_elbi.sqd';
% tstart   = -500;
% tstop    = 3500;
% channels = 0:156;
%%
info     = sqdread(filename,'Info');
trigger  = all_trigger(filename, trigChan);
nchan    = length(channels);
Fs       = info.SampleRate;
tstart   = tstart * info.SampleRate / 1000;
tend     = tend * info.SampleRate / 1000;

dataMatrix = nan(tend-tstart+1,nchan,size(trigger,1));

fprintf('Epoching')
for i = 1:length(trigger(:,1))
    trigTime = trigger(i,1);
    epoch    = sqdread(filename,'Channels',channels,'Samples',[trigTime+tstart trigTime+tend]);
    
    dataMatrix(:,:,i) = epoch;
    counterdisp(i);
end
end