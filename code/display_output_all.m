
% PRINT OUTPUT
M_count = sum(bsxfun(@eq,dataset(:,1),0:3))',

if exist('Theta_BradleyTerry_parameters','var')
	display_output(player_names, Theta_BradleyTerry, loglikelihood_BradleyTerry, epsilon_BradleyTerry, 'Bradley-Terry (logit) parameter initialization:', sum(M_count), false)
end

if exist('Theta_ThurstoneCaseV_parameters','var')
	display_output(player_names, Theta_ThurstoneCaseV, loglikelihood_ThurstoneCaseV, epsilon_ThurstoneCaseV, 'Thurstone Case V (Hessian probit) parameter initialization:', sum(M_count), true)
end

if exist('Theta_BradleyTerry_softassignment','var')
	display_output(player_names, Theta_BradleyTerry, loglikelihood_BradleyTerry, epsilon_BradleyTerry, 'Bradley-Terry (logit) soft-assignment initialization:', sum(M_count), false)
end

if exist('Theta_ThurstoneCaseV_softassignment','var')
	display_output(player_names, Theta_ThurstoneCaseV, loglikelihood_ThurstoneCaseV, epsilon_ThurstoneCaseV, 'Thurstone Case V (Hessian probit) soft-assignment initialization:', sum(M_count), true)
end

