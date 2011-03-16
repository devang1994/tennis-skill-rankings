function display_output(names, theta, ll, epsilon, title, isgaussian)

P = length(names);
assert(size(theta,2) == P*2)

if isgaussian
	RESCALE_EFFECTIVE_SIGMA = 1;
else
	% The Gaussian we use during probit has variance 10 since it is assumed to be the sum of 10 independent unit gaussian player performances.
	% A logit with the same variance would require rescaling the theta values by: sigma^2 = pi^2 s^2 / 3 ==> s = sqrt(3) sigma / pi
	RESCALE_EFFECTIVE_SIGMA = (1 / (sqrt(3*10)/pi));
end

theta_scaled = theta * RESCALE_EFFECTIVE_SIGMA;


% For sorting purposes only: Your total skill is "amount of scoring on offense" minus "amount of scoring on defense"
skill2_totals = theta_scaled(2,1:P) - theta_scaled(2,(P+1):end);

% print in descending order (best differential at the top, worst player at the bottom)
[skill2 skill2_order] = sort(skill2_totals,'descend');


disp('');
disp('');
disp('===========================================================');
disp(title)
disp(['after ' num2str(length(ll)) ' EM iterations log-likelihood = ' num2str(ll(end))])
epsilon,
disp('');
disp('1pt offense	3pt offense   1pt defense	3pt defense');
for player_rank=1:P
	n = skill2_order(player_rank);
	disp([num2str([theta_scaled(:,n);theta_scaled(:,P+n)]','%1.2f\t') '    ' names{n}]);
end

RESCALE_EFFECTIVE_SIGMA,
