function [IdxMat,pct_extime,pct_exchan] = hl_find_extreme(dataMat,threshold,plotFig)
%This function take epoched datamatrix as input. The function scans the
%matrix and then generate a matrix indicating the trial and channel where
%the meg signal saturated.
%Out put:
%Idx: 
%dataMat    : This should be time x channel x epoch
%threshold: threshold defining time points that exceed a normal range In unit of femto.
%IdxMat      : a channel X epoch matrix. Indicating whether any epoch-and-channel
%have extremem value
%pct_extime : a channel x 1 vector, indicating the percentage of time a
%channel exceed extreme value
%pcy_exchan : a 1 x epoch vector, indicating the percentage chan that had
%exceed the threshold in each epoch


if ~exist('plotFig','var')
    plotFig = 1;
end

nepoch = size(dataMat,3);
nchan  = size(dataMat,2);

IdxMat     = abs(dataMat)>threshold;
IdxMat     = sq(sum(IdxMat,1))~=0;
pct_extime = mean(IdxMat,2);
pct_exchan = mean(IdxMat,1);
%keyboard;
if plotFig==1
    cpsFigure(1.5,1.2);
    imagesc(IdxMat)
    xlabel('epoch')
    ylabel('channel')
    title('Extreme value')
    drawnow;
    cpsFigure(1.2,1);
    subplot(1,2,1)
    hist(pct_extime,30);
    title('pct_extime')
    subplot(1,2,2)
    hist(pct_exchan,30);
    title('pct_exchan')
end