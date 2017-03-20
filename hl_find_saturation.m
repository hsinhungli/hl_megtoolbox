function [Mat, satchan, satpoint] = hl_find_saturation(dataMat, windowsize, criterion, plotFig)
%This function take epoched datamatrix as input. The function scans the
%matrix and then generate a matrix indicating the trial and channel where
%the meg signal saturated.
%keyboard;
%Input:
%dataMat:    This should be time x channel x epoch OR time x channel
%windowsize: In unit of delta t (inverse of sampling rate). If the signal didn't change in this
%length of time point, the data will be marked as saturate.

%Output
%For epoched input data:
%Mat: this is a 2D (chan X epoch), indicating the chan that as saturation exceed the windowsize in
%each epoch. 
%Don't use the other two outputs
%For 2D input (not epoched data):
%Mat: a time series, indicating the number of saturated channel at each time point.
%satchan: a vector 1xnchan, indicating the channel of which saturation time exceeding the criterion
%satpoint: the time x channle indicating the time points in which saturation occured
%keyboard;

if ~exist('criterion','var') || isempty(criterion)
    criterion = .05;
end
if ~exist('plotFig','var')
    plotFig = 1;
end
%dataMat(dataMat>10000)=0;
if ndims(dataMat) == 3
    nepoch = size(dataMat,3);
    nchan  = size(dataMat,2);
    Mat    = nan(nchan,nepoch);
    
    diffMat = diff(dataMat, 1, 1) == 0;
    filter  = ones(windowsize,1)/windowsize;
    for epoch = 1:nepoch
        tempMat  = double(squeeze(diffMat(:,:,epoch)));
        diffmva  = conv2(filter,1, tempMat,'valid');
        satpoint = diffmva >= .99;
        satchan  = sum(satpoint,1) ~= 0;
        Mat(:,epoch) = satchan';
    end
elseif ismatrix(dataMat)
    [nt,nchan] = size(dataMat);
    if nchan>nt
        error('nchan cant be larger than nt, wrong matrix?');
    end
    
    diffMat  = diff(dataMat,1,1) == 0;
    diffMat  = [zeros(1,nchan); diffMat];
    filter   = ones(windowsize,1)/windowsize;
    diffmva  = conv2(filter,1, double(diffMat),'same');
    satpoint = diffmva >= .9;
    satchan  = mean(satpoint,1) >criterion;
    Mat = sum(satpoint,2);
end

if plotFig==1
    if ismatrix(dataMat)
        cpsFigure(1.5,1.2);
        title('Saturating points on Continuous data')
        imagesc(satpoint');
        xlabel('time')
        ylabel('channel')
    else
        cpsFigure(1.5,1.2);
        imagesc(Mat)
        xlabel('epoch')
        ylabel('channel')
        title('Saturation')
        drawnow;
    end
end
