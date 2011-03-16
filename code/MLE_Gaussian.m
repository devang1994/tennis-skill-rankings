function [theta,i] = MLE_Gaussian(X,y,w,theta_init)
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
MAX_ITERS = 40;

% X = [ones(size(X,1),1) X]; %no need to add an intercept, just take X as passed in to the function
p = size(X,1);
n = size(X,2);
theta = theta_init;
theta_old = theta_init;

for i=1:MAX_ITERS
	
	grad = zeros(n,1);
	%ll(i)=0;
	H = zeros(n,n);
	for j=1:p
		cdf = normcdf(X(j,:)*theta,0,sqrt(10));
		negcdf = normcdf(-X(j,:)*theta,0,sqrt(10));
		
		if cdf < eps(negcdf) || negcdf < eps(cdf)
			% These datapoints will be fine.
			% They have so much functional margin we don't realistically need to worry about them.
			continue
		end
		
		pdf = normpdf(X(j,:)*theta,0,sqrt(10));
		grad = grad + w(j) * X(j,:)'*(y(j)*pdf/cdf - (1-y(j))*pdf/negcdf);
		H = H - w(j) * (y(j)*(pdf/cdf + pdf^2/cdf^2) + (1-y(j))*(pdf^2/negcdf^2 + pdf/negcdf)) * X(j,:)'*X(j,:);
	%	ll(i) = ll(i) + Y(j)*log(hxj) + (1-Y(j))*log(1-hxj);
	end
	
	if i > 1
		% In general, Hessian is the optimal step size
		update_step = - pinv(H) * grad;
	else
		% No Hessian for initial step
		update_step = - pinv(X'*X)*grad;
	end
	theta = theta + update_step;
	
	if norm(theta-theta_old) < 10e-8
		break
	end
	
	theta_old = theta;
end

