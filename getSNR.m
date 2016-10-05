function [pds_snr] = getSNR(pds, shift)

pds_snr = zeros(size(pds));

temp_pds   = pds(shift+1 : end-shift,:,:);
nfre_valid = size(temp_pds,1);
noise_l    = pds(1 : nfre_valid,:,:);
noise_h    = pds(end-(nfre_valid-1) : end,:,:);
noise      = (noise_l + noise_h) /2;
snr        = temp_pds ./ noise;

pds_snr(shift+1 : end-shift,:,:) = snr;






