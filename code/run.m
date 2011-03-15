% After running:
%   $python ../data/build_dataset.py ../data/raw/20070204.DETCLE.csv
clear all

loaddata

MAX_ITER = 500

%dbclear all
[Theta_BradleyTerry loglikelihood_BradleyTerry epsilon_BradleyTerry] = basketball_network_EM(dataset, MAX_ITER, false)
%dbclear all
%  I don't think this is exactly what we want, I'll look over the math in a bit. -- Joseph
%[Theta_ThurstoneCaseV loglikelihood_ThurstoneCaseV epsilon] = basketball_network_EM(dataset, MAX_ITER, true)


names_offense',
Theta_BradleyTerry(:,1:end/2)',
