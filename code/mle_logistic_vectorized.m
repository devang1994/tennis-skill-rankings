function [theta,i] = mle_logistic_vectorized(X,y,w,theta_init)
% Weighted linear regression
%
% http://www.stanford.edu/class/cs229/notes/cs229-notes1.pdf
%
% This function maximizes the likelihood of:
%  \prod_{{x,y}} (1 - logistic(theta' * X))^M[y^0,X] * (logistic(theta' * X))^M[y^1,X]
%
% rows of X are training samples - in this case, binary inputs activated by OnCourt
%    Each row of X should contain 5 ones in the first half and 5 ones in the second half corresponding to the two five-man units that are on the court. Every other element of X should be zero.
%
% Each element of the 1-d vector y are the observed values of Win_i (for each soft-datapoint)
%
% Let w be a 1-d vector of "how many of these training points are there?"
% For example, if w(8) = 5.0, then we will treat the training data as if there were 5 copies of X(8,:) and y(8).
% The reason this is important is because during EM we will have soft-assignments of datapoints, so most elements of w will actually be less than 1.0
%
% http://www.stat.psu.edu/~jiali/course/stat597e/notes2/logit.pdf but with no intercept
%
% newton raphson: theta = theta - inv(H)* grad;
% with H = hessian, grad = gradient
% returns theta as a column vector
MAX_ITERS = 500;
EFFECTIVE_SIGMA = (sqrt(3*10)/pi);
SIGMA_EPS_STOP = 1e-10;
STOPPING_EPS = 1e-6;
PRUNING_EPS = STOPPING_EPS * STOPPING_EPS;

assert(0.5.^MAX_ITERS < STOPPING_EPS)

% X = [ones(size(X,1),1) X]; %no need to add an intercept, just take X as passed in to the function
p = size(X,1);
n = size(X,2);
theta = theta_init;

step_size = 1.0;
theta_prev = nan(size(theta));
ll_prev = -inf(size(y));

for i=1:MAX_ITERS
	
	%==============================
	%   Precompute useful values
	%==============================
	
	xjtheta_all = X*theta;
	hxj_all = sigmoid(X*theta); 
	neg_hxj_all = 1 - hxj_all;
	
	%========================================
	%   Remove points that cause underflow
	%========================================
	
	% For numerical stability we will prune datapoints that have such a bad functional margin that changes to theta no longer affect their likelihoods
	%   1 - hxj_all(y==0)  -->  0   ==>   log(1 - hxj_all(y==0))  -->  -Inf
	% or
	%   hxj_all(y==1)  -->  0       ==>   log(hxj_all(y==1))  -->  -Inf
	% i.e. these are the points that have been declared "outliers" by the sigmoid
	% Similarly, once can also prune datapoints that have such a good functional margin that they will be satisfied no matter what happens to theta
	% These are also points that would have no influence on the gradient anyway:
	%   hxj_all(y==0)  -->  0
	% or
	%   hxj_all(y==1)  -->  1
	prune_training_points = ~(neg_hxj_all <= PRUNING_EPS) & ~(hxj_all <= PRUNING_EPS);
	
	%=======================================================
	%   Check log-likelihood for overshoot or convergence
	%=======================================================
	
	% We have to check for overshoot here...
	ll_new = nan(size(y));
	ll_new(y==1) = w(y==1) .* log(hxj_all(y==1));
	ll_new(y==0) = w(y==0) .* log(neg_hxj_all(y==0));
	
	% Now, use ll_new_total and ll_prev_total to detect:
	%  1. Stop criterion
	%  2. Overshoot
	% New LL = \prod_{{x,y}} (1 - logistic(theta' * X))^M[y^0,X] * (logistic(theta' * X))^M[y^1,X]
	ll_new_total = sum(ll_new(prune_training_points));
	ll_prev_total = sum(ll_prev(prune_training_points));

	if abs(ll_new_total - ll_prev_total)/p < SIGMA_EPS_STOP
		break
	elseif ll_new_total < ll_prev_total
		disp(['Overshoot on iteration ' num2str(i) '!'])
		disp(ll_prev_total)
		disp(ll_new_total)
		ll_prev = -inf(size(y)); % reset this. When you go back through ll_prev will be set to ll_new which should be the same ll_prev you had when you did the overshoot in the first place.
		theta = theta_prev;
		step_size = step_size * 0.5;
		disp(['step size reduced to ' num2str(step_size)]);
		%keyboard
		continue;
	end
	ll_prev = ll_new;
	theta_prev = theta;
	
	%=================================
	%   Compute Newton-Raphson step
	%=================================
	
	% grad = grad + w(j) * X(j,:)'*(y(j) - hxj);
	% grad = grad + w(j) * X(j,:)'*(y(j) - hxj_all(j));
	% grad = grad +        X(j,:)'*   [w*(y - hxj_all)](j);
	%                     row of X
	%                          multiplies
	%                              each element of a column vector
	% Then, transpose to return a column vector at the end
	X_pruned = X(prune_training_points,:);
	grad = X_pruned' * ((y(prune_training_points) - hxj_all(prune_training_points)) .* w(prune_training_points));
	
	% H = H - w(j) * hxj*(1-hxj)*X(j,:)'*X(j,:);
	% H = H - w(j) * hxj*(1-hxj)*  (  X(j,:)'*X(j,:)  );
	% H = H - w(j) * hxj*(1-hxj)*  (  X(j,:)'*X(j,:)  );
	H_inside_coeff = w(prune_training_points) .* hxj_all(prune_training_points) .* (neg_hxj_all(prune_training_points));
	% Identity: A * B = \sum col_a * row_b
	%	So: \sum X(j,:)'*X(j,:) = X' * X
	%	    \sum X(j,:)'*w(j)*X(j,:) = X' * (w .* X)
	%	                                     bsxfun
	H = - X_pruned' * bsxfun(@times,X_pruned,H_inside_coeff);

	update_step = - pinv(H) * grad;
	
	%===========================
	%   Check for convergence
	%===========================
	
	if max(abs(step_size*update_step))/EFFECTIVE_SIGMA < STOPPING_EPS
		break
	end
	
	theta = theta + step_size*update_step;
end

