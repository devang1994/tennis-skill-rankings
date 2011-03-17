% After running:
%   $python ../data/build_dataset.py ../data/raw/20070204.DETCLE.csv
disp('loading data...')
clear all; loaddata; MAX_ITER = 500
disp('Done!')

[Theta_BradleyTerry_parameters loglikelihood_BradleyTerry_parameters epsilon_BradleyTerry_parameters] = basketball_network_EM(dataset, MAX_ITER, false, 'M');
[Theta_ThurstoneCaseV_parameters loglikelihood_ThurstoneCaseV_parameters epsilon_ThurstoneCaseV_parameters] = basketball_network_EM(dataset, MAX_ITER, true, 'M');
[Theta_BradleyTerry_softassignments loglikelihood_BradleyTerry_softassignments epsilon_BradleyTerry_softassignments] = basketball_network_EM(dataset, MAX_ITER, false, 'E');
[Theta_ThurstoneCaseV_softassignments loglikelihood_ThurstoneCaseV_softassignments epsilon_ThurstoneCaseV_softassignments] = basketball_network_EM(dataset, MAX_ITER, true, 'E');

display_output_all
