
% PRINT OUTPUT
M_count = sum(bsxfun(@eq,dataset(:,1),0:3))',

if exist('Theta_BradleyTerry','var')
	display_output(player_names, Theta_BradleyTerry, loglikelihood_BradleyTerry, epsilon_BradleyTerry, 'Bradley-Terry (logit):', sum(M_count), false)
end

if exist('Theta_ThurstoneCaseV','var')
	display_output(player_names, Theta_ThurstoneCaseV, loglikelihood_ThurstoneCaseV, epsilon_ThurstoneCaseV, 'Thurstone Case V (Hessian probit):', sum(M_count), true)
end
