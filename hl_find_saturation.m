function Mat = hl_find_saturation(dataMat,windowsize, plotFig)
%This function take epoched datamatrix as input. The function scans the
%matrix and then generate a matrix indicating the trial and channel where
%the meg signal saturated.
%input: 
%dataMat: This should be time x channel x epoch
%windowsize: In unit of sampleing rate. If the signal didn't change in this
%length of time point, the data will be marked as saturate.

if ~exist('plotFig','var')
    plotFig = 1;
end

nepoch = size(dataMat,3);
nchan  = size(dataMat,2);
Mat    = nan(nchan,nepoch);

diffMat = diff(dataMat, 1, 1) == 0;
filter  = ones(windowsize,1)/windowsize;
for epoch = 1:nepoch
    tempMat  = double(squeeze(diffMat(:,:,epoch)));
    diffmva  = conv2(filter,1, tempMat,'valid');
    satpoint = diffmva >= 1;
    satchan  = sum(satpoint,1) ~= 0;
    Mat(:,epoch) = satchan';
end

cpsFigure(1.5,1.2)
imagesc(Mat)
xlabel('epoch')
ylabel('channel')
title('Saturation')
drawnow;
