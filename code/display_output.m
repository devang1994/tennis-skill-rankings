function display_output(theta, ll, epsilon, title, gaussian)

if gaussian:
	RESCALE_EFFECTIVE_SIGMA = 1
else
	% The Gaussian we use during probit has variance 10 since it is assumed to be the sum of 10 independent unit gaussian player performances.
	% A logit with the same variance would require rescaling the theta values by: sigma^2 = pi^2 s^2 / 3 ==> s = sqrt(3) sigma / pi
	RESCALE_EFFECTIVE_SIGMA = (1 / (sqrt(3*10)/pi));
end

theta_scaled = theta * RESCALE_EFFECTIVE_SIGMA;

% print in descending order (most scoring at the top, least scoring at the bottom)
[skill2_offense skill2_offense_order] = sort(theta_scaled(1:length(names_offense),2));
[skill2_defense skill2_defense_order] = sort(theta_scaled(length(names_offense)+(1:length(names_defense)),2));


disp('');
disp('');
disp('===========================================================');
disp(title)
epsilon,
disp('');
disp('1pt			3pt		OFFENSIVE PLAYER');
for indx_offense=1:length(names_offense)
	n = skill2_offense_order(indx_offense);
	disp([num2str(theta_scaled(n,:)) '		' names_offense{n}]);
end
disp('');
disp('1pt			3pt		DEFENSIVE PLAYER');
for indx_defense=1:length(names_defense)
	n = skill2_defense_order(indx_defense);
	disp([num2str(theta_scaled(length(names_offense)+n,:)) '		' names_defense{n}]);
end

EFFECTIVE_SIGMA,
