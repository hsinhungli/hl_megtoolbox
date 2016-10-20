function hl_ShowChannel(chan,data_hdr,cfg)

temp = zeros(1,157);
temp(chan) = 1;

if ~isfield(cfg,'holdon')
    cfg.holdon = 0;
end
if ~isfield(cfg,'colormap')
    cfg.colormap  = [1 1 1; .5 .5 1];
end
cfg.colorbar  = 'no';
cfg.electrodes = 'on';
cfg.maplimits = [0 1];

hl_topoplot_2d(temp,data_hdr,cfg,[.4 .4],'Channel selected')