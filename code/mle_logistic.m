function [theta,ll] = log_regression(X,y,w)
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
MAX_ITERS = 50;

% X = [ones(size(X,1),1) X]; %no need to add an intercept, just take X as passed in to the function
p = size(X,1);
n = size(X,2);
theta = zeros(n,1);

for i=1:MAX_ITERS
	
	grad = zeros(n,1);
	%ll(i)=0;
	H = zeros(n,n);
	for j=1:p
		hxj = sigmoid(X(j,:)*theta);
		grad = grad + w(j) * X(j,:)'*(y(j) - hxj);
		H = H - w(j) * hxj*(1-hxj)*X(j,:)'*X(j,:);
	%	ll(i) = ll(i) + Y(j)*log(hxj) + (1-Y(j))*log(1-hxj);
	end
	
	theta = theta - H \ grad;
end

