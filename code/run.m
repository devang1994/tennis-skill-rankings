% After running:
%   $python ../data/build_dataset.py ../data/raw/20070204.DETCLE.csv
clear all; loaddata; MAX_ITER = 500

%dbclear all
[Theta_BradleyTerry loglikelihood_BradleyTerry epsilon_BradleyTerry] = basketball_network_EM(dataset, MAX_ITER, false);
%dbclear all
[Theta_ThurstoneCaseV loglikelihood_ThurstoneCaseV epsilon_ThurstoneCaseV] = basketball_network_EM(dataset, MAX_ITER, true)


% PRINT OUTPUT
M_count = sum(bsxfun(@eq,dataset(:,1),0:3))',

if exist('Theta_BradleyTerry','var')
	display_output(Theta_BradleyTerry, loglikelihood_BradleyTerry, epsilon_BradleyTerry, 'Bradley-Terry (logit):', false)
end

if exist('Theta_ThurstoneCaseV','var')
	display_output(Theta_ThurstoneCaseV, loglikelihood_ThurstoneCaseV, epsilon_ThurstoneCaseV, 'Thurstone Case V (Hessian probit):', true)
end
