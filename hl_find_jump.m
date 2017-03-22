function [Mat, satchan, satpoint] = hl_find_jump(dataMat, dt, windowsize, pad, criterion, plotFig)
%This function take epoched datamatrix as input. The function scans the
%matrix and then generate a matrix indicating the trial and channel where
%the meg signal exhibit rapid jump
%keyboard;
%Input:
%dataMat:    This should be time x channel x epoch OR time x channel
%dt:         Timestep used in this data Matrix
%windowsize: The length of difference filter ([-1 1]) will be determined by windowsize

%Output
%For epoched input data:
%Mat: this is a 2D (chan X epoch), indicating the chan that as saturation exceed the windowsize in
%each epoch. 
%Don't use the other two outputs
%For 2D input (not epoched data):
%Mat: a time series, indicating the number of saturated channel at each time point.
%satchan: a vector 1xnchan, indicating the channel of which saturation time exceeding the criterion
%satpoint: the time x channle indicating the time points in which saturation occured
keyboard;

if nargin<3
    error('Need at least 4 inputs: data, dt, windowsize');
end
if exist('pad','var')
    if numel(pad)==1
        pad=[pad pad];
    elseif numel(pad)>2
        error('pad should be 1x2 or 2x1 value')
    end
    initIdx = pad(1)/dt+1;
    endIdx  = pad(2)/dt+1;
end
% if ~exist('criterion','var') || isempty(criterion)
%     criterion = .05;
% end
% if ~exist('plotFig','var')
%     plotFig = 1;
% end

dataMat     = dataMat(initIdx:end-endIdx,:,:);
windowsize  = windowsize/dt;
filter      = ones(windowsize,1)/windowsize;
filter(1:windowsize/2) = filter(1:windowsize/2)*-1;

if ndims(dataMat) == 3
    [nt,nchan,nepoch] = size(dataMat);
    Mat     = nan(nchan,nepoch);
    tempMat = reshape(dataMat,nt,nchan*nepoch);
    diffmva = conv2(filter,1, tempMat,'same');
    diffmva = reshape(diffmva,size(dataMat)); %Output of the filter
    diffmva = diffmva(ceil(windowsize/2):end-ceil(windowsize/2),:,:);
    %diffmva_n = diffmva

    for epoch = 1:nepoch
        temp = sq(diffmva(:,:,epoch));
        satpoint = bsxfun(@rdivide,temp,std(temp)) >= 5;
        satchan  = sum(satpoint,1) ~= 0;
        Mat(:,epoch) = satchan';
    end; keyboard;
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
