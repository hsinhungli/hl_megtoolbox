function hl_topoplot_2d(sensor_data,data_hdr,cfg,siz,title_txt)

if notDefined('data_hdr')
    data_hdr = load('hdr'); data_hdr = data_hdr.hdr;
end

cfg.layout          = ft_prepare_layout(cfg, data_hdr);
if ~isfield(cfg,'style')
    cfg.style ='straight';
end
if ~isfield(cfg,'electrodes')
    cfg.electrodes    ='off';
end
if ~isfield(cfg,'colorbar')
    cfg.colorbar ='yes';
end
if ~isfield(cfg,'maplimits')
    cfg.maplimits ='maxmin';
end
if ~isfield(cfg,'interpolation')
    cfg.interpolation   = 'v4';
end
if ~isfield(cfg,'holdon')
    cfg.holdon = 0;
end
if notDefined('siz')
    siz = [.5 .5];
end

cfg.data            = sensor_data';


for ii = 1:length(cfg.data)
    if isnan(cfg.data(ii))
        cfg.data(ii) = nanmedian(sensor_data);
    end
end

if cfg.holdon == 1
else
    cpsFigure(siz(1),siz(2));
end
topoplot(cfg,cfg.data)

% add a title if requested
if exist('title_txt', 'var') && ~isempty(title_txt), title(title_txt,'FontSize',14); end
