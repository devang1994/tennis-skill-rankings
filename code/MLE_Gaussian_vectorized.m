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
STOPPING_EPS = 1e-6; % For stopping criteria
PRUNING_EPS = STOPPING_EPS *STOPPING_EPS; % To avoid dividing by zero

% X = [ones(size(X,1),1) X]; %no need to add an intercept, just take X as passed in to the function
p = size(X,1);
n = size(X,2);
theta = theta_init;

for i=1:MAX_ITERS
	
	xjtheta_all = X*theta;
	assert(size(xjtheta_all,1) == p)
	assert(size(xjtheta_all,2) == 1)
	
	cdf_all = normcdf(xjtheta_all,0,SIGMA);
	negcdf_all = normcdf(-xjtheta_all,0,SIGMA);
	
	% Pruned datapoints will be fine.
	% They have so much functional margin we don't realistically need to worry about them.
	
	prune_training_points = ~((cdf_all <= PRUNING_EPS*negcdf_all) | (negcdf_all <= PRUNING_EPS*cdf_all));
	
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
	grad = X(prune_training_points,:)' * ((y_pdf_cdf_j - yneg_pdf_negcdf_j) .* w(prune_training_points)); % grad = grad + w(j) * X(j,:)'*(y_pdf_cdf(j) - yneg_pdf_negcdf(j)); 
	
	
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

	H = - X(prune_training_points,:)' * bsxfun(@times,X(prune_training_points,:),H_inside_coeff); % H = H - w(j) * (y_pdf_cdf(j)*(1 + pdf_cdf_j(j)) + yneg_pdf_negcdf(j)*(1 + pdf_negcdf_j(j))) * (X(j,:)'*X(j,:)); 
	
	
	if i > 1
		% In general, Hessian is the optimal step size
		update_step = - pinv(H) * grad;
	else
		% No Hessian for initial step
		update_step = - pinv(X'*X)*grad;
	end
	theta = theta + update_step;
	
	if max(abs(update_step))/SIGMA < STOPPING_EPS
		break
	end
end

