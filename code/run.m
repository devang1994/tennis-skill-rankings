% After running:
%   $python ../data/build_dataset.py ../data/raw/20070204.DETCLE.csv
clear all

loaddata

MAX_ITER = 500

dbclear all
[Theta_BradleyTerry loglikelihood_BradleyTerry] = basketball_network_EM(dataset, MAX_ITER, false)
dbclear all
[Theta_ThurstoneCaseV loglikelihood_ThurstoneCaseV] = basketball_network_EM(dataset, MAX_ITER, true)
