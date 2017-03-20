function ndata = hl_nmax(data,Idx)
if nargin<2
    ndata = data/max(data(:));
else
    tempdata = data(Idx);
    ndata = data/max(tempdata(:));
end