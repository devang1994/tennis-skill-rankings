% After running:
%   $python ../data/build_dataset.py ../data/raw/20070204.DETCLE.csv
loaddata

MAX_ITER = 500
gaussian = false

[Theta ll] = basketball_network_EM(dataset, MAX_ITER, gaussian)
