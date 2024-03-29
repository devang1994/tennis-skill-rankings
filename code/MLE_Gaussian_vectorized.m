function [theta,i] = MLE_Gaussian_vectorized(X,y,w,SIGMA,theta_init)
% This function maximizes the likelihood of:
%  \prod_{{x,y}} (1 - probit(theta' * X))^M[y^0,X] * (probit(theta' * X))^M[y^1,X]
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
% newton-raphson on the probit function
% returns theta as a column vector
MAX_ITERS = 100;
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
update_step = zeros(size(theta));

for i=1:MAX_ITERS
	theta = theta + step_size*update_step;
	
	%==============================
	%   Precompute useful values
	%==============================
	
	xjtheta_all = X*theta;
	assert(size(xjtheta_all,1) == p)
	assert(size(xjtheta_all,2) == 1)
	
	cdf_all = normcdf(xjtheta_all,0,SIGMA);
	negcdf_all = normcdf(-xjtheta_all,0,SIGMA);
	
	%========================================
	%   Remove points that cause underflow
	%========================================
	
	% For numerical stability we prune datapoints that have such a bad functional margin that they probably can't be satisfied
	% e.g. y == 0 and probit(theta*x) --> 1
	%        or
	%      y == 1 and probit(theta*x) --> 0
	%
	% Also, we don't need datapoints with so much functional margin that they leave no influence on the gradient
	% e.g. y == 0 and probit(theta*x) --> 0
	%        or
	%      y == 1 and probit(theta*x) --> 1
	% Especially because of the way MLE_Gaussian is computed, this avoids divide-by-zeros later on.
	
	prune_training_points = ~(negcdf_all <= PRUNING_EPS) & ~(cdf_all <= PRUNING_EPS);
	
	%=======================================================
	%   Check log-likelihood for overshoot or convergence
	%=======================================================
	
	% We have to check for overshoot here.
	% Remember to avoid underflow when doing this! Use prune_training_points
	% New LL = \prod_{{x,y}} (1 - probit(theta' * X))^M[y^0,X] * (probit(theta' * X))^M[y^1,X]
	ll_new = nan(size(y));
	ll_new(y==1) = w(y==1) .* log(cdf_all(y==1));
	ll_new(y==0) = w(y==0) .* log(negcdf_all(y==0));
	
	% Now, use ll_new_total and ll_prev_total to detect:
	%  1. Stop criterion
	%  2. Overshoot
	ll_new_total = sum(ll_new(prune_training_points));
	ll_prev_total = sum(ll_prev(prune_training_points));
	
	if abs(ll_new_total - ll_prev_total)/p < SIGMA_EPS_STOP
		break
	elseif ll_new_total < ll_prev_total
		disp(['Overshoot on iteration ' num2str(i) '!'])
		disp(ll_prev_total)
		disp(ll_new_total)
		step_size = step_size * 0.5;
		disp(['step size reduced to ' num2str(step_size)]);
		
		
		% reset this. When you go back through ll_prev will be set to ll_new which should be the same ll_prev you had when you did the overshoot in the first place.
		theta = theta_prev;
		ll_prev = -inf(size(y)); 
		update_step = zeros(size(theta));
		
		
		%keyboard
		continue;
	end
	ll_prev = ll_new;
	theta_prev = theta;
	
	
	%=================================
	%   Compute Newton-Raphson step
	%=================================
	
	
	% Compute in parallel
	pdf_j = normpdf(xjtheta_all(prune_training_points),0,SIGMA);
	
	pdf_cdf_j = pdf_j./cdf_all(prune_training_points);
	y_pdf_cdf_j = y(prune_training_points).*pdf_cdf_j;
	
	pdf_negcdf_j = pdf_j./negcdf_all(prune_training_points);
	yneg_pdf_negcdf_j = (1-y(prune_training_points)).*pdf_negcdf_j;
	
	%grad = grad + w(j) * X(j,:)'*(y(j)*pdf/cdf - (1-y(j))*pdf/negcdf);
	%                     X(j,:)'
	%                      is a
	%                  column vector
	%
	% (y_pdf_cdf_j - yneg_pdf_negcdf_j) is a column vector
	%
	% Rows of the original X are multiplied by each element of (y_pdf_cdf_j - yneg_pdf_negcdf_j).
	% Then, transpose to return a column vector at the end
	X_pruned = X(prune_training_points,:);
	grad = X_pruned' * ((y_pdf_cdf_j - yneg_pdf_negcdf_j) .* w(prune_training_points)); % grad = grad + w(j) * X(j,:)'*(y_pdf_cdf(j) - yneg_pdf_negcdf(j)); 
	

	% In general, Hessian is the optimal step size
	H_inside_coeff = w(prune_training_points) .* (y_pdf_cdf_j.*(1 + pdf_cdf_j) + yneg_pdf_negcdf_j.*(1 + pdf_negcdf_j));
	% H = H - w(j).* (y(j)*(pdf/cdf + pdf^2/cdf^2)         + (1-y(j))*(pdf^2/negcdf^2 + pdf/negcdf)      ) * X(j,:)'*X(j,:);
	% H = H - w(j).* (  y(j)*(1 + pdf/cdf)*pdf/cdf         + (1-y(j))*(1 + pdf/negcdf)*pdf/negcdf        ) * X(j,:)'*X(j,:);
	% H = H - w(j).* (  y(j)*pdf/cdf*(1 + pdf/cdf)         + (1-y(j))*pdf/negcdf*(1 + pdf/negcdf)        ) * X(j,:)'*X(j,:);
	% H = H - w(j).* (  y_pdf_cdf_j(j).*(1 + pdf_cdf_j(j)) + yneg_pdf_negcdf_j(j).*(1 + pdf_negcdf_j(j))  ) * X(j,:)'*X(j,:);
	% H = H - w(j).* (  y_pdf_cdf_j(j).*(1 + pdf_cdf_j(j)) + yneg_pdf_negcdf_j(j).*(1 + pdf_negcdf_j(j))  ) * X(j,:)'*X(j,:);
	% Identity: A * B = \sum col_a * row_b
	%	So: \sum X(j,:)'*X(j,:) = X' * X
	%	    \sum X(j,:)'*w(j)*X(j,:) = X' * (w .* X)
	%	                                     bsxfun
	H = - X_pruned' * bsxfun(@times,X_pruned,H_inside_coeff); % H = H - w(j) * (y_pdf_cdf(j)*(1 + pdf_cdf_j(j)) + yneg_pdf_negcdf(j)*(1 + pdf_negcdf_j(j))) * (X(j,:)'*X(j,:)); 
	update_step = - pinv(H) * grad;
	
	if any(isnan(update_step))
		keyboard
	end
	
	%===========================
	%   Check for convergence
	%===========================
	
	if max(abs(step_size*update_step))/SIGMA < STOPPING_EPS
		break
	end
end
