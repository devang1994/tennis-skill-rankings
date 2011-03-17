% After running:
%   $python ../data/build_dataset.py ../data/raw/20070204.DETCLE.csv
disp('loading data...')
clear all; loaddata; MAX_ITER = 500
disp('Done!')

BradleyTerry_parameters = basketball_network_EM(dataset, MAX_ITER, false, 'M');
ThurstoneCaseV_parameters = basketball_network_EM(dataset, MAX_ITER, true, 'M');
BradleyTerry_softassignments = basketball_network_EM(dataset, MAX_ITER, false, 'E');
ThurstoneCaseV_softassignments = basketball_network_EM(dataset, MAX_ITER, true, 'E');

display_output_all
