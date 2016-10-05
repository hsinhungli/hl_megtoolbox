function [trl, triggerNumber] = hl_gettrlinfo(filename, trigChan, tstart, tend)

info     = sqdread(filename,'Info');
trigger  = all_trigger(filename, trigChan);
%trigger  = hl_recoverTrig;
tstart   = tstart * info.SampleRate / 1000;
tend     = tend * info.SampleRate / 1000;
triggerNumber = trigger(:,2);

nEvent = size(trigger,1);
fprintf('%d events found\n',nEvent);

trl = nan(nEvent, 3);
for ievent = 1:nEvent
    trigTime = trigger(ievent,1);
    trl(ievent,:) = [trigTime+tstart trigTime+tend trigTime];
end


