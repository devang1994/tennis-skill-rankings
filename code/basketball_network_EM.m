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
E_D_schedule = logical([
	0 0 0; % k=1 --> Lose1, Lose2, Lose3
        0 0 1; % k=2 --> Lose1, Lose2, Win3
        0 1 0; % k=3 --> Lose1, Win2 , Lose3
        0 1 1; %  .
        1 0 0; %  .
        1 0 1; %  .
        1 1 0; % k=7 --> Win1, Win2, Lose3
        1 1 1;])%k=8 --> Win1, Win2, Win3

%We have L=1 thetas because there is one theta for every player.
%L is the number of columns in the dataset, but one of the columns is R
Theta = nan(3, L-1); % This will be immediately overwritten, so we can catch errors by initializating to NaN

%========================
%   Begin EM Algorithm
%========================

% Set initial values for E_D
M_count = zeros(4,1);
for m = 1:M
	M_count(dataset(m,1)+1) = M_count(dataset(m,1)+1) + 1;
end
W3_init = M_count(4)/M;
W2_init = M_count(3)/M ./ W3_init;
W1_init = M_count(2)/M ./ W2_init;

% For each of the possible combinations of W, it has a joint probability
W_init = [W3_init, W2_init, W1_init];
for k=1:8
	wins   = W_init( E_D_schedule(k,:))     ;
	losses = 1 - W_init(~E_D_schedule(k,:)) ;
	joint_probability = prod([wins, losses]);

	% Initialize all datapoints at once for this combination of W assignments
        E_D(:,k) = joint_probability;
end

% Normalize E_D. Each row should sum to 1.0
E_D = bsxfun(@rdivide,E_D,sum(E_D,2));

OldProb = W;

for j = 1:MAX_ITER

	%============
	%   M-Step
	%============

	dbstop if naninf
	E_D,

	% Collection of sufficient statistics for epsilon
	% We need four counts.
	% M[r^3,w_3^1]:
	%   dataset(:,1) == 3
	%   E_D_schedule(:,3) == true
	M_r3_w3 = sum(E_D(dataset(:,1) == 3, E_D_schedule(:,2)'));
	% M[r^2,w_3^0,w_2^1]:
	%   dataset(:,1) == 2
	%   E_D_schedule(:,3) == false
	%   E_D_schedule(:,2) == true
	M_r2_l3_w2 = sum(E_D(dataset(:,1) == 2, E_D_schedule(:,2)' & ~E_D_schedule(:,3)'));
	% M[r^1,w_3^0,w_2^0,w_1^1]:
	%   dataset(:,1) == 1
	%   E_D_schedule(:,3) == false
	%   E_D_schedule(:,2) == false
	%   E_D_schedule(:,1) == true
	M_r2_l3_l2_w1 = sum(E_D(dataset(:,1) == 1, E_D_schedule(:,1)' & ~E_D_schedule(:,2)' & ~E_D_schedule(:,3)'));
	% M[r^1,w_3^0,w_2^0,w_1^0]:
	%   dataset(:,1) == 1
	%   E_D_schedule(:,3) == false
	%   E_D_schedule(:,2) == false
	%   E_D_schedule(:,1) == false
	M_r2_l3_l2_l1 = sum(E_D(dataset(:,1) == 0, ~E_D_schedule(:,1)' & ~E_D_schedule(:,2)' & ~E_D_schedule(:,3)'));

	M_modelled = M_r3_w3 + M_r2_l3_w2 + M_r2_l3_l2_w1 + M_r2_l3_l2_l1;
	M_noise = M - M_modelled;

	%============
	%   E-Step
	%============

	for i = 1:3
		% For each datapoint (each row), compute:
		%   How many of the eight soft-datapoints have W_i == false?
		pr_wi_false = sum(E_D(:,~E_D_schedule(:,i)'),2);
		%   How many of the eight soft-datapoints have W_i == true?
		pr_wi_true  = sum(E_D(:, E_D_schedule(:,i)'),2);

		% Do weighted parameter estimation for W_i, go!
		if gaussian
			% TODO: We don't need sigma in the same way we don't need an intercept term
			%       What changes need to be made to MLE_Gaussian so that it uses a constant sigma?
			% TODO: Reformulate the Gaussian to accept weighted datapoints
			theta_w_i = MLE_Gaussian(W(:,i),dataset(:,2:end));
		else
			X = [dataset(:,2:end); dataset(:,2:end)];
			y = [zeros(M,1); ones(M,1)];
			weights = [pr_wi_false; pr_wi_true];
			theta_w_i = mle_logistic (dataset(:,2:end),y,W(:,i));
		end	
		% theta_w_i is returned as a column vector
		Theta(i,:) = theta_w_i';
	end

	% Parameter estimation for epsilon (that was easy)
	epsilon = M_noise / (3*M);

	%=====================
	%   Soft-Assignment
	%=====================

	% Probability calculations for each unique datapoint
	% We need, for each possible datapoint,
        %   Pr{D_r, C, W_1, W_2, W_3 | theta, epsilon}
	%   = Pr{D_r|W_1, W_2, W_3,epsilon} * Pr{W_1|theta, C} * Pr{W_2|theta, C} * Pr{W_3|theta, C} * Pr{C}
	for m=1:M
		% Each datapoint has different C values (dataset(m,2:end)) so they will have different W1 W2 and W3
		if gaussian
			W1 = normpdf(0,Theta(1,:)*dataset(m,2:end)',1.0);
			W2 = normpdf(0,Theta(2,:)*dataset(m,2:end)',1.0);
			W3 = normpdf(0,Theta(3,:)*dataset(m,2:end)',1.0);
		else
			W1 = sigmoid(Theta(1,:)*dataset(m,2:end)');
			W2 = sigmoid(Theta(2,:)*dataset(m,2:end)');
			W3 = sigmoid(Theta(3,:)*dataset(m,2:end)');
		end

		W_soft = [W3 W2 W1];
		% Make the assignments
		soft_assignments = nan(1,8); % initialize to NaN in order to catch typos
		for k=1:8
			wins   = W_soft( E_D_schedule(k,:))     ;
			losses = 1 - W_soft(~E_D_schedule(k,:)) ;
			soft_assignments(k) = prod([wins, losses]);

		end
		% Normalize
		E_D(m,:) = soft_assignments' / sum(soft_assignments);
	end

	%========================
	%   Stopping Criterion
	%========================

	% Calculation of log-likelihood
	log_likelihood(j) = 0;
	log_likelihood(j) = log_likelihood(j) + sum(log(W(:,1))) + sum(log(W(:,2))) + sum(log(W(:,3)));
	log_likelihood(j) = log_likelihood(j) + sum(M_r)*log(1-3*epsilon) + M_noise*log(epsilon)

	if norm(W-OldProb,'fro') < 10e-6
		break;
	end

	OldProb = W;


end
