function display_output(roster, converged, title, isgaussian)

P = length(roster.names);
assert(size(converged.Theta,2) == P*2)

if isgaussian
	RESCALE_EFFECTIVE_SIGMA = 1;
else
	% The Gaussian we use during probit has variance 10 since it is assumed to be the sum of 10 independent unit gaussian player performances.
	% A logit with the same variance would require rescaling the theta values by: sigma^2 = pi^2 s^2 / 3 ==> s = sqrt(3) sigma / pi
	RESCALE_EFFECTIVE_SIGMA = (1 / (sqrt(3*10)/pi));
end

theta_scaled = converged.Theta * RESCALE_EFFECTIVE_SIGMA;


% For sorting purposes only: Your total skill is "amount of scoring on offense" minus "amount of scoring on defense"
skill2_totals = theta_scaled(2,1:P) - theta_scaled(2,(P+1):end);

% print in descending order (best differential at the top, worst player at the bottom)
[skill2 skill2_order] = sort(skill2_totals,'descend');


disp('');
disp('');
disp('===========================================================');
disp(title)
disp(['after ' num2str(length(converged.log_likelihood)) ' EM iterations log-likelihood = ' num2str(converged.log_likelihood(end))])
disp(['          i.e. E[Prb{Datapoint}] = ' num2str(exp(converged.log_likelihood(end)/roster.M)) ])
disp(['epsilon = ' num2str(converged.epsilon)])
disp('');
disp('          offense                    defense             player name');
disp('   1pt      2pt      3pt      1pt      2pt      3pt          (num. possessions)');
for player_rank=1:P
	n = skill2_order(player_rank);
	matrix_str = num2str([0;theta_scaled(:,n);theta_scaled(:,P+n)]','% 7.3f  ');
	disp([matrix_str(:,7:end) '    ' roster.names{n} '(' num2str(roster.possessions(n)) ')']);
end

RESCALE_EFFECTIVE_SIGMA,
