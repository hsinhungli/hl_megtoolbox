function hl_saveallfig(figDir, figNames)

if nargin < 1
    error('Please give figure directory')
end
if nargin < 2
    fprintf('Using default figure name')
    use_default = 1;
end
if ~exist(figDir,'dir')
    mkdir(figDir)
end

f = sort(findobj('Type','figure'));
nfig = numel(f);
if exist('figNames','var')
    if numel(figNames) ~= nfig
        error('number of figure and number of figure name do not matched')
    end
end
for iF = 1:nfig
    if use_default == 1
        figNames{iF} = num2str(iF);
    end
    temp_filename = sprintf('%s/%s',figDir,figNames{iF});
    figure(f(iF))
    saveas(gcf,temp_filename,'eps')
end
close all
drawnow;