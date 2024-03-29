function [result_struct] = basketball_network_EM(dataset, MAX_ITER, gaussian, first_step)
%
% Returns struct with fields:
%   result_struct.Theta (converged)
%   result_struct.epsilon (converged)
%   result_struct.log_likelihood
%
% dataset is MxL, where M is number of possessions,
% and L is P*2 (for O and D, where P is the number of players).
% Note that if we just have one set of O and D teams, ie DET O and CLE D,
% we only need 24 elements, not 48, since our dataset
% doesn't deal with CLE O and DET D
% gaussian is true if we use MLE_Gaussian, false for logistic
% first_step is either 'e', 'm', 'E' or 'M', indicating whether to:
%   E: assume an initial (heuristic) soft assignment and run E-Step first (this is the default)
%   M: assume initial parameters (all skills are equal) and run M-Step first
%   e: assume a random soft assignment and run E-Step first
%   m: assume initial parameters randomly and run M-Step first
assert(first_step == 'E' || first_step == 'M')


if gaussian
	SIGMA = sqrt(10),
end

% http://steelandsilicon.wordpress.com/2010/07/17/a-few-matlaboctave-notes/
if size(ver('Octave'),1)
    OctaveMode = 1;
    more off
else
    OctaveMode = 0;
end

%======================
%   Set up variables
%======================

M = size(dataset,1);
L = size(dataset,2); % (1+24*num_teams)
% Each of the datapoints receives partial assignments to the 8 possible combinations of W_1, W_2, and W_3
% We will use the following legend.
% E_D(m,k): The m-th datapoint's probability of being assigned combination k, where
E_D = nan(M,8);
E_D_schedule = logical([
	0 0 0; % k=1 --> Lose1, Lose2, Lose3 ==> R=0
        1 0 0; % k=2 --> Win1 , Lose2, Lose3 ==> R=1
        0 1 0; % k=3 --> Lose1, Win2 , Lose3 ==> R=2
        1 1 0; %  .                          ==> R=2
        0 0 1; %  .                          ==> R=3
        1 0 1; %  .                          ==> R=3
        0 1 1; % k=7 --> Lose1, Win2 , Win3  ==> R=3
        1 1 1;])%k=8 --> Win1 , Win2 , Win3  ==> R=3

%We have L-1 thetas because there is one theta for every player.
%L is the number of columns in the dataset, but one of the columns is R
Theta = zeros(3, L-1); % With no prior information, initialize to zeros (we used to start at all zeroes on every call to mle_logistic anyway)
% If skills are all even (Pr{Win} == 0.5), this would be epsilon:
epsilon = (sum(dataset(:,1) == 0)/8 + sum(dataset(:,1) == 1)/8 + sum(dataset(:,1) == 2)/4 + sum(dataset(:,1) == 2)/2)/M/3;
% If first_step == 'M', these initialization values will determine which local optima we reach.
% If first_step == 'E', presumably these will both be overwritten during the first E-step.

%========================
%   Begin EM Algorithm
%========================

% Set initial values for E_D
M_count = zeros(4,1);
for m = 1:M
	M_count(dataset(m,1)+1) = M_count(dataset(m,1)+1) + 1;
end
W3_init = M_count(4)/M;
W2_init = M_count(3)/M ./ (1 - W3_init);
W1_init = M_count(2)/M ./ (1 - W2_init);

% For each of the possible combinations of W, it has a joint probability
W_init = [W1_init, W2_init, W3_init];
for k=1:8
	wins   = W_init( E_D_schedule(k,:))     ;
	losses = 1 - W_init(~E_D_schedule(k,:)) ;
	joint_probability = prod([wins, losses]);

	% Initialize all datapoints at once for this combination of W assignments
        E_D(:,k) = joint_probability;
end

W_init,
M_count,
M,


%======================================
%   Random initialization strategies
%======================================
if first_step == 'm'
	epsilon = rand / 3; %epsilon can't be greater than 1/3
	Theta = (rand(size(theta)) - 0.5)*sqrt(12); % mle_logistic and MLE_Gaussian assume unit variance, the width of a unit-variance uniform distribution is sqrt(12)
	first_step = 'M';
elseif first_step == 'e'
	E_D = rand(size(E_D)); % This is unnormalized, but we'll normalize it just before starting the EM loop.
	first_step = 'E';
end


% Normalize E_D. Each row should sum to 1.0
% CAUTION: If first_step was 'e', we rely on this normalization being here rather than earlier!
E_D = bsxfun(@rdivide,E_D,sum(E_D,2));
OldProb = E_D;

if first_step == 'M'
	disp('Initialization:')
	epsilon,
	Theta,
elseif first_step == 'E'
	disp('Initialization:')
	E_D,
else
	assert(false)
end

for j = 1:MAX_ITER

	% At this point in the loop, we have soft assignments
	% E_D,

	if ~(first_step == 'M' && j == 1) % skip first E-step if we prefer to initialize parameters
		
		%============
		%   E-Step (epsilon)
		%============

		% Collection of sufficient statistics for epsilon
		% We need four counts.
		% M[r^3,w_3^1]:
		%   dataset(:,1) == 3
		%   E_D_schedule(:,3) == true
		M_r3_w3 = sum(sum(E_D(dataset(:,1) == 3, E_D_schedule(:,3)')));
		% M[r^2,w_3^0,w_2^1]:
		%   dataset(:,1) == 2
		%   E_D_schedule(:,3) == false
		%   E_D_schedule(:,2) == true
		M_r2_l3_w2 = sum(sum(E_D(dataset(:,1) == 2, E_D_schedule(:,2)' & ~E_D_schedule(:,3)')));
		% M[r^1,w_3^0,w_2^0,w_1^1]:
		%   dataset(:,1) == 1
		%   E_D_schedule(:,3) == false
		%   E_D_schedule(:,2) == false
		%   E_D_schedule(:,1) == true
		M_r1_l3_l2_w1 = sum(sum(E_D(dataset(:,1) == 1, E_D_schedule(:,1)' & ~E_D_schedule(:,2)' & ~E_D_schedule(:,3)')));
		% M[r^1,w_3^0,w_2^0,w_1^0]:
		%   dataset(:,1) == 1
		%   E_D_schedule(:,3) == false
		%   E_D_schedule(:,2) == false
		%   E_D_schedule(:,1) == false
		M_r0_l3_l2_l1 = sum(sum(E_D(dataset(:,1) == 0, ~E_D_schedule(:,1)' & ~E_D_schedule(:,2)' & ~E_D_schedule(:,3)')));

		M_modelled = M_r3_w3 + M_r2_l3_w2 + M_r1_l3_l2_w1 + M_r0_l3_l2_l1;
		M_noise = M - M_modelled;
		
		% Parameter estimation for epsilon (that was easy)
		epsilon = M_noise / (3*M);
		
		%============
		%   E-Step (theta)
		%============
		
		% For a unique soft-assignment, there is a unique global optimum for MLE_Gaussian (or mle_logistic) to converge to.
		% Although we carry over a previous Theta to improve runtime, it does not influence the final result of MLE_Gaussian (or mle_logistic)
		
		for i = 1:3
			% theta_init is a column vector
			theta_init = Theta(i,:)';

			% There are two soft-datapoints for each actual datapoint.
			% i.e. one with W_i == true and one with W_i == false
			X = [dataset(:,2:end); dataset(:,2:end)];
			y = [zeros(M,1); ones(M,1)];
			
			% For each datapoint (each row), compute:
			%   How many of the eight soft-datapoints have W_i == false?
			pr_wi_false = sum(E_D(:,~E_D_schedule(:,i)'),2);
			%   How many of the eight soft-datapoints have W_i == true?
			pr_wi_true  = sum(E_D(:, E_D_schedule(:,i)'),2);

			% Do weighted parameter estimation for W_i, go!
			weights = [pr_wi_false; pr_wi_true];
			
			if gaussian
				% We don't need sigma in the same way we don't need an intercept term
				[theta_w_i itersneeded] = MLE_Gaussian_vectorized(X,y,weights,SIGMA,theta_init);
			else
				[theta_w_i itersneeded] = mle_logistic_vectorized(X,y,weights,theta_init);
			end
			
			disp(['    MLE iterations: ' num2str(itersneeded)]);
			if any(isnan(theta_w_i))
				keyboard
			end
			
			% recenter theta_w_i (for stability and readability)
			theta_w_i((length(theta_w_i)/2+1):end) = theta_w_i((length(theta_w_i)/2+1):end)*-1;
			theta_w_i = theta_w_i - median(theta_w_i);
			theta_w_i((length(theta_w_i)/2+1):end) = theta_w_i((length(theta_w_i)/2+1):end)*-1;
			% theta_w_i is returned as a column vector
			Theta(i,:) = theta_w_i';
		end
	end

	% At this point in the loop, we have new parameters
	
	%=====================
	%   Soft-Assignment (M-Step and calculation of log_likelihood)
	%=====================
	log_likelihood(j) = 0;

	% Probability calculations for each unique datapoint
	% We need, for each possible datapoint,
        %   Pr{D_r, C, W_1, W_2, W_3 | theta, epsilon}
	%   = Pr{D_r|W_1, W_2, W_3,epsilon} * Pr{W_1|theta, C} * Pr{W_2|theta, C} * Pr{W_3|theta, C} * Pr{C}
	
	% Each datapoint has different R values (dataset(m,1)) so they will have different Pr{r}
	R_schedule = [
		(1-3*epsilon) epsilon epsilon epsilon;
		epsilon (1-3*epsilon) epsilon epsilon;
		epsilon epsilon (1-3*epsilon) epsilon;
		epsilon epsilon (1-3*epsilon) epsilon;
		epsilon epsilon epsilon (1-3*epsilon);
		epsilon epsilon epsilon (1-3*epsilon);
		epsilon epsilon epsilon (1-3*epsilon);
		epsilon epsilon epsilon (1-3*epsilon)];

	for m=1:M
		
		% Compute Pr{r|w}
		pr_r_w = R_schedule(:,dataset(m,1) + 1); 
	
		% Each datapoint has different C values (dataset(m,2:end)) so they will have different W1 W2 and W3
		if gaussian
			W1 = normcdf(Theta(1,:)*dataset(m,2:end)',0,SIGMA);
			W2 = normcdf(Theta(2,:)*dataset(m,2:end)',0,SIGMA);
			W3 = normcdf(Theta(3,:)*dataset(m,2:end)',0,SIGMA);
		else
			W1 = sigmoid(Theta(1,:)*dataset(m,2:end)');
			W2 = sigmoid(Theta(2,:)*dataset(m,2:end)');
			W3 = sigmoid(Theta(3,:)*dataset(m,2:end)');
		end

		W_soft = [W1 W2 W3];
		% Compute Pr{w|c}
		pr_w_c = nan(1,8); % initialize to NaN in order to catch typos
		for k=1:8
			wins   = W_soft( E_D_schedule(k,:))     ;
			losses = 1 - W_soft(~E_D_schedule(k,:)) ;
			%I like this assertion but it eats up runtime %assert(numel([wins, losses]) == 3)
			pr_w_c(k) = prod([wins, losses]);

		end
		
		%Make the assignments
		% soft_assignments unnormalized represents Pr{r|w}Pr{w|c}Pr{c} (but Pr{c} is uniform so we ignore it)
		soft_assignments = pr_r_w' .* pr_w_c;
		% Normalize (divide out Pr{r,c} = \sum_w Pr{r,w,c})
		E_D(m,:) = soft_assignments' / sum(soft_assignments);

		% The expected log-likelihood of this datapoint is Proposition 19.1 (page 860) in the text
		% and together with O -- H -- C and Pr{C} uniform,
		%   Pr{c,o,h) = Pr{o|h} Pr{h|c}
		% we know log-likelihood of the datapoint
		
		% have pr_o_h(k) be 1-d vector of length 8 that contains the probability of R in each soft-assignment 
		log_likelihood(j) = log_likelihood(j) + log(sum(soft_assignments));
	end

	% At this point in the loop, we have new soft assignments we can compare with the old soft assignments
	
	%======================
	%   Stopping Critera
	%======================

	E_D_update_magnitude = max(max(abs(E_D - OldProb)));
	
	disp(['EM Iteration #' num2str(j) ' completed:  ll = ' num2str(log_likelihood(j),'%.8g') ' ,  E_D changed by ' num2str(E_D_update_magnitude, '%.8g')]);
	if OctaveMode
		fflush(stdout);
	end
	
	if (j > 1) && (abs(log_likelihood(j) - log_likelihood(j-1))/M < 10e-6)
		if (E_D_update_magnitude < 10e-6)
			break;
		end
	end

	OldProb = E_D;

end


result_struct = struct('Theta', Theta, 'epsilon', epsilon, 'log_likelihood', log_likelihood);
