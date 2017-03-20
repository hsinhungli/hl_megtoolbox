function cpsFigure_meg(tlist,fre,singletrial,amp,plv)
%single trial: time x trial
%amp: fre x time
%plv: fre x time

cpsFigure(2,1.5); hold on; colormap(jet);
subplot(3,2,[1 3])
imagesc(tlist,1:size(singletrial,2),singletrial'); hold on;
ylabel('Trial')
subplot(3,2,5)
plot(tlist,mean(singletrial,2));
set(gca,'XTick',[tlist(1):100:tlist(end)]);
xlim([min(tlist) max(tlist)]);
ylabel('fT')
xlabel('Time')

subplot(4,2,[2 4])
imagesc(tlist,fre,amp,[-1.3 1.3]);
set(gca,'YDir','normal'); colorbar;
title('Power')
subplot(4,2,[6 8])
imagesc(tlist,fre,plv,[0 1]);
set(gca,'XTick',[tlist(1):100:tlist(end)]); colorbar;
xlabel('Time')
ylabel('Frequency')
title('Phase Locking Value')
set(gca,'YDir','normal');
tightfig;
