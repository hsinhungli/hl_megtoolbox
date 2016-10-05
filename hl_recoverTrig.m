function trigMat = hl_recoverTrig
filename = '/Volumes/DRIVE1/DATA/hsin/MEG/BR/RD/R0817_BR_8.14.15/R0817_BR_8.14.15.sqd';
load RD_EXP_1508141549.mat
[data,info] = sqdread(filename,'Channels',191);
data = data>10000;

trigMat = [];
count = 0;
for block = 1:15
    for trial = 1:32
        count = count+1;
        trigMat(count,1) = timing(block).timeStamp{trial}(1);
        trigMat(count,2) = timing(block).trigRecord{trial}(1);
    end
end
trigMat(:,1) = trigMat(:,1)*1000; %make it in unit of msec
trigMat(:,1) = trigMat(:,1) - trigMat(1);

trigMat(:,1) = round(trigMat(:,1) + 105400);

for trial = 1:32*15
    t0 = trigMat(trial,1);
    refdata = data(t0-500 : t0+10000);
    diff = min(find(refdata))-500;
    trigMat(trial,1) = trigMat(trial,1)+diff;
end

%megtime_t0 = 105400;
%time = 1:3585000;
%trig = zeros(3585000,1);

