function [Theta log_likelihood epsilon] = basketball_network_EM(dataset, MAX_ITER, gaussian)

% dataset is MxL, where M is number of possessions,
% and L is 12*2*num_teams (for O and D). Note that if we
% just have one set of O and D teams, ie DET O and CLE D,
% we only need 24 elements, not 48, since our dataset
% doesn't deal with CLE O and DET D
% gaussian is true if we use MLE_Gaussian, false for logistic

M = size(dataset,1);
L = size(dataset,2); % (1+24*num_teams)
% Each of the datapoints receives partial assignments to the 8 possible combinations of W_1, W_2, and W_3
% We will use the following legend.
% E_D(m,k): The m-th datapoint's probability of being assigned combination k, where
E_D = nan(M,8);
E_D_schedule = [0 0 0; % k=1 --> Lose1, Lose2, Lose3
                0 0 1; % k=2 --> Lose1, Lose2, Win3
                0 1 0; % k=3 --> Lose1, Win2 , Lose3
                0 1 1; %  .
                1 0 0; %  .
                1 0 1; %  .
                1 1 0; % k=7 --> Win1, Win2, Lose3
                1 1 1;]% k=8 --> Win1, Win2, Win3

%We have L=1 thetas because there is one theta for every player.
%L is the number of columns in the dataset, but one of the columns is R
Theta = nan(3, L-1); % This will be immediately overwritten, so we can catch errors by initializating to NaN

%Get initial values for E_D
M_count = zeros(4,1);
for m = 1:M
	M_count(dataset(m,1)+1) = M_count(dataset(m,1)+1) + 1;
end
W3_init = M_count(4)/M * ones(M,1);
W2_init = M_count(3)/M * ones(M,1) ./ (ones(M,1) - W(:,3));
W1_init = M_count(2)/M * ones(M,1) ./ (ones(M,1) - W(:,2));
W0_init = 1 - W3_init - W2_init - W1_init;



OldProb = W;
if gaussian
	s = zeros(3,1);
end

for j = 1:MAX_ITER

	%============
	%   E-Step
	%============

	% Parameter estimation for W_i
	for i = 1:3
		if gaussian
			theta = MLE_Gaussian(W(:,i),dataset(:,2:end));
		else
			theta = mle_logistic (dataset(:,2:end),W(:,i));
		end	
		% theta is a column vector to start
		Theta(i,:) = theta';
	end

	% Parameter estimation for epsilon (that was easy)
	epsilon = %M_noise / (3*M);

	%=====================
	%   Soft-Assignment
	%=====================

	% Probability calculations for each unique datapoint
	% We need, for each possible datapoint,
        %   Pr{D_r, C, W_1, W_2, W_3 | theta, epsilon}
	%   = Pr{D_r|W_1, W_2, W_3,epsilon} * Pr{W_1|theta, C} * Pr{W_2|theta, C} * Pr{W_3|theta, C} * Pr{C}
	for m=1:M
		for k=1:8
			if gaussian
				W1_true = normpdf(0,Theta(1,:)*dataset(m,2:end)',1.0);
				W2_true = normpdf(0,Theta(2,:)*dataset(m,2:end)',1.0);
				W3_true = normpdf(0,Theta(3,:)*dataset(m,2:end)',1.0);
			else
				W1_true = sigmoid(Theta(1,:)*dataset(m,2:end)');
				W2_true = sigmoid(Theta(2,:)*dataset(m,2:end)');
				W3_true = sigmoid(Theta(3,:)*dataset(m,2:end)');
			end
			E_D(m)
		end
	end

	%============
	%   M-Step
	%============

	dbstop if naninf
	W,
	M_r,

	% Collection of sufficient statistics for epsilon / R-evaluation
	% note that we might need to check for numeric underflow
	M_r(4) = (1-3*epsilon) * sum(W(:,3));
	M_r(3) = (1-3*epsilon) * sum(W(:,2) .* (ones(M,1)-W(:,3)));
	M_r(2) = (1-3*epsilon) * sum(W(:,1) .* (ones(M,1)-W(:,3)) .* (ones(M,1)-W(:,2)));
	M_r(1) = (1-3*epsilon) * sum((ones(M,1)-W(:,1)) .* (ones(M,1)-W(:,3)) .* (ones(M,1)-W(:,2)));

	M_r,
	epsilon,

	M_noise = M - sum(M_r);

	% Calculation of log-likelihood
	log_likelihood(j) = 0;
	log_likelihood(j) = log_likelihood(j) + sum(log(W(:,1))) + sum(log(W(:,2))) + sum(log(W(:,3)));
	log_likelihood(j) = log_likelihood(j) + sum(M_r)*log(1-3*epsilon) + M_noise*log(epsilon)

	if norm(W-OldProb,'fro') < 10e-6
		break;
	end

	OldProb = W;

end
