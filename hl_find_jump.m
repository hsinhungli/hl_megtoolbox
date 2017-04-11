function [Mat, satchan, satpoint] = hl_find_jump(dataMat, dt, windowsize, pad, criterion, plotFig)
%This function take epoched datamatrix as input. The function scans the
%matrix and then generate a matrix indicating the trial and channel where
%the meg signal exhibit rapid jump
%keyboard;
%Input:
%dataMat    : This should be time x channel x epoch OR time x channel
%dt         : Timestep used in this data Matrix
%windowsize : The length of difference filter ([-1 1]) will be determined by windowsize
%pad        : padding some time points not to analuze
%criterion  : The criterion for scaning jumping point: in unit of std within a trial & chan, or withn whole exp if input is 2D)

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

if nargin<3
    error('Need at least 3 inputs: data, dt, windowsize');
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
if ~exist('criterion','var') || isempty(criterion)
    criterion = 5;
end
if ~exist('plotFig','var')
    plotFig = 1;
end

dataMat     = dataMat(initIdx:end-endIdx,:,:);
windowsize  = windowsize/dt;
filter      = ones(windowsize,1)/windowsize;
temp = round(windowsize/3);
filter(1:temp)       = -filter(1:temp)/2;
filter(end-temp:end) = -filter(end-temp:end)/2;
disp(filter);

if ndims(dataMat) == 3
    [nt,nchan,nepoch] = size(dataMat);
    
    %Filter once and take absolute value
    tempMat = reshape(dataMat,nt,nchan*nepoch);
    diffmva = abs(conv2(filter,1, tempMat,'same'));
    diffmva = diffmva(windowsize:end-windowsize,:); %Cut out the begining and end
    
    %Filter second time
    diffmva = conv2(filter,1, diffmva,'same');
    diffmva = diffmva(windowsize:end-windowsize,:,:); %Cut out the begining and end
    
    nt      = size(diffmva,1);
    diffmva = reshape(diffmva,[nt,nchan,nepoch]);
    diffmva = permute(diffmva,[2 1 3]); %change to chan x total_time_point
    diffmva = reshape(diffmva,[nchan, nt*nepoch]);
    diffmva_n = bsxfun(@rdivide,diffmva,std(diffmva,[],2));    %Normalized by std across all time point
    
    diffmva = reshape(diffmva,[nchan, nt, nepoch]);
    diffmva = permute(diffmva,[2 1 3]);
    diffmva_n = reshape(diffmva_n,[nchan, nt, nepoch]);
    diffmva_n = permute(diffmva_n,[2 1 3]);
    
    Mat_1     = nan(nchan,nepoch);
    for epoch = 1:nepoch
        temp     = abs(sq(diffmva_n(:,:,epoch)));
        satpoint = temp >= criterion;
        satchan  = sum(satpoint,1) ~= 0;
        Mat_1(:,epoch) = satchan';
    end;
    
elseif ismatrix(dataMat)
    %     [nt,nchan] = size(dataMat);
    %     if nchan>nt
    %         error('nchan cant be larger than nt, wrong matrix?');
    %     end
    
    %     diffMat  = diff(dataMat,1,1) == 0;
    %     diffMat  = [zeros(1,nchan); diffMat];
    %     filter   = ones(windowsize,1)/windowsize;
    %     diffmva  = conv2(filter,1, double(diffMat),'same');
    %     satpoint = diffmva >= .9;
    %     satchan  = mean(satpoint,1) >criterion;
    %     Mat = sum(satpoint,2);
end

[Mat_sat] = hl_find_saturation(dataMat, 5, [],1);
Mat = Mat_1 & Mat_sat;

if plotFig==1
    if ismatrix(dataMat)
        %         cpsFigure(1.5,1.2);
        %         title('Saturating points on Continuous data')
        %         imagesc(satpoint');
        %         xlabel('time')
        %         ylabel('channel')
    else
        
    end
end

return
%%
%imagesc(Mat);
chan = 19;
trl = find(Mat(chan,:));
disp(trl);
%figure;
% for c = 1:min(length(trl),6);
%     subplot(min(length(trl),6),1,c);
%     %plot(sq(dataMat(:,chan,trl(c))));
%     plot(sq(diffmva_n(:,chan,trl(c))));
%     xlim([1 nt]);
% end
figure;
for c = 1:min(length(trl),8);
    subplot(min(length(trl),8),1,c);
    plot(sq(dataMat(:,chan,trl(c))));
    title(num2str(trl(c)))
    xlim([1 nt]);
end