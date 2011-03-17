function y = randsample_fromweights(v,w)
%Modified version of RANDSAMPLE Random sample
%   http://www.mathworks.com/help/toolbox/stats/randsample.html

sumw = sum(w);
p = w(:)' / sumw;

edges = min([0 cumsum(p)],1); % protect against accumulated round-off
edges(end) = 1; % get the upper edge exact

[frequencies, list_of_bin_numbers] = histc(rand,edges);

y = v(list_of_bin_numbers);
