function [Theta ll] = basketball_network_EM(dataset, MAX_ITER, gaussian)

% dataset is MxL, where M is number of possessions,
% and L is 12*2*num_teams (for O and D). Note that if we
% just have one set of O and D teams, ie DET O and CLE D,
% we only need 24 elements, not 48, since our dataset
% doesn't deal with CLE O and DET D
% gaussian is true if we use MLE_Gaussian, false for logistic

M = size(dataset,1);
L = size(dataset,2); % (1+24*num_teams)
W = zeros(M,3);
Theta = size(3, L);
%set initial values for W
M_count = zeros(4);
for m = 1:M
	M_count(dataset(m,1)+1) = M_count(dataset(m,1)+1) + 1;
end
W(:,3) = M_count(4)/M * ones(M,1);
W(:,2) = M_count(3)/M * ones(M,1) ./ (ones(M,1) - W(:,3));
W(:,1) = M_count(2)/M * ones(M,1) ./ (ones(M,1) - W(:,2));
M_r = zeros(4);
epsilon = .02; %arbitrary initialization
M_r(4) = (1-3*epsilon) * sum(W(:,3));
M_r(3) = (1-3*epsilon) * sum(W(:,2) .* (ones(M,1)-W(:,3)));
M_r(2) = (1-3*epsilon) * sum(W(:,1) .* (ones(M,1)-W(:,3)) .* (ones(M,1)-W(:,2)))
M_r(1) = (1-3*epsilon) * sum((ones(M,1)-W(:,1)) .* (ones(M,1)-W(:,3)) .* (ones(M,1)-W(:,2)));
M_noise = M - sum(M_r);

OldProb = W;
if gaussian
	s = zeros(3,1);

for j = 1:MAX_ITER

	% Parameter estimation for W_i
	for i = 1:3
		if gaussian
			[theta s(i)] = MLE_Gaussian(W(:,i),dataset(2:L,:));
		else
			[theta, ll] = mle_logistic (dataset(2:L,:),W(:,i));
		end	
		Theta(i,:) = theta';
	end

	% Parameter estimation for epsilon (that was easy)
	epsilon = M_noise / (3*M);

	% Probability calculations for each datapoint
	for m=1:M
		if gaussian
			W(m,1) = normpdf(0,Theta(1,:)*[1; dataset(m,:)],s(1));
			W(m,2) = normpdf(0,Theta(2,:)*[1; dataset(m,:)],s(2));
			W(m,3) = normpdf(0,Theta(3,:)*[1; dataset(m,:)],s(3));
		else
			W(m,1) = sigmoid(Theta(1,:)*[1; dataset(m,:)]);
			W(m,2) = sigmoid(Theta(2,:)*[1; dataset(m,:)]);
			W(m,3) = sigmoid(Theta(3,:)*[1; dataset(m,:)]);
		end
	end

	% Collection of significant statistics for epsilon / R-evaluation
	% note that we might need to check for numeric underflow
	M_r(4) = (1-3*epsilon) * sum(W(:,3));
	M_r(3) = (1-3*epsilon) * sum(W(:,2) .* (ones(M,1)-W(:,3)));
	M_r(2) = (1-3*epsilon) * sum(W(:,1) .* (ones(M,1)-W(:,3)) .* (ones(M,1)-W(:,2)))
	M_r(1) = (1-3*epsilon) * sum((ones(M,1)-W(:,1)) .* (ones(M,1)-W(:,3)) .* (ones(M,1)-W(:,2)));
	M_noise = M - sum(M_r);

	% Calculation of log-likelihood
	log_likelihood(j) = 0;
	log_likelihood(j) = log_likelihood(j) + sum(log(W(:,1))) + sum(log(W(:,2))) + sum(log(W(:,3)));
	log_likelihood(j) = log_likelihood(j) + sum(M_r)*log(1-3*epsilon) + M_noise*log(epsilon)

	if norm(W-OldProb,'fro') < 10e-6
		break;

	OldProb = W;

end
