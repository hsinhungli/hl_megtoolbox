function tag= hl_getTag(filename,delimiter)

%filename = '/Volumes/DRIVE1/DATA/hsin/MEG/BR/LH/R0959_BR_6.2.15/preproc/R0959_BR_6.2.15_run04_elbi.sqd';

if nargin <2
    delimiter = '_';
end

tempidx = find(filename=='.');
endIdx  = max(tempidx) - 1;
tempidx = find(filename==delimiter);
iniIdx  = max(tempidx) + 1;

tag = filename(iniIdx:endIdx);