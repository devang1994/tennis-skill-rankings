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

% X = [ones(size(X,1),1) X]; %no need to add an intercept, just take X as passed in to the function
p = size(X,1);
n = size(X,2);
theta = theta_init;

for i=1:MAX_ITERS
	
	xjtheta_all = X*theta;
	hxj_all = sigmoid(X*theta); 
	
	% We have to check for overshoot here...	
	% New LL = \prod_{{x,y}} (1 - logistic(theta' * X))^M[y^0,X] * (logistic(theta' * X))^M[y^1,X]
	ll_new = sum(w(y==1) .* log(hxj_all(y==1))) + sum(w(y==0) .* log(1 - hxj_all(y==0)));
	disp(ll_new)
	
	
	% grad = grad + w(j) * X(j,:)'*(y(j) - hxj);
	% grad = grad + w(j) * X(j,:)'*(y(j) - hxj_all(j));
	% grad = grad +        X(j,:)'*   [w*(y - hxj_all)](j);
	%                     row of X
	%                          multiplies
	%                              each element of a column vector
	% Then, transpose to return a column vector at the end
	grad = X' * ((y - hxj_all) .* w);
	
	% H = H - w(j) * hxj*(1-hxj)*X(j,:)'*X(j,:);
	% H = H - w(j) * hxj*(1-hxj)*  (  X(j,:)'*X(j,:)  );
	% H = H - w(j) * hxj*(1-hxj)*  (  X(j,:)'*X(j,:)  );
	H_inside_coeff = w .* hxj_all .* (1 - hxj_all);
	% Identity: A * B = \sum col_a * row_b
	%	So: \sum X(j,:)'*X(j,:) = X' * X
	%	    \sum X(j,:)'*w(j)*X(j,:) = X' * (w .* X)
	%	                                     bsxfun
	H = - X' * bsxfun(@times,X,H_inside_coeff);


	update_step = - pinv(H) * grad;
	theta = theta + update_step;
	
	if max(abs(update_step))/EFFECTIVE_SIGMA < 10e-6
		break
	end
end

