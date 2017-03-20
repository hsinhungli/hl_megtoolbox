function hl_ShowChannel(chan,data_hdr,cfg)

if ~isrow(chan)
    chan = chan';
end
temp = zeros(1,157);
temp(chan) = 1;

cfg.colorbar  = 'no';
cfg.electrodes = 'on';
cfg.interpolation = 'nearest';
cfg.maplimits = [0 1];
if ~isfield(cfg,'holdon')
    cfg.holdon = 0;
end
if ~isfield(cfg,'colormap')
    cfg.colormap  = [1 1 1; .5 .5 1];
end


hl_topoplot_2d(temp,[],cfg,[.4 .4],sprintf('#: %s',num2str(chan)))