function [theta,ll] = log_regression(X,Y)
% rows of X are training samples - 24 element vectors of {-1, 0, 1}
% rows of Y are estimated probabilities for W_i(x)
% newton raphson: theta = theta - inv(H)* grad;
% with H = hessian, grad = gradient
% returns theta as a column vector

% X = [ones(size(X,1),1) X]; %no intercept
m = size(X,1);
n = size(X,2);
theta = zeros(n,1);
max_iters = 50;

for i=1:max_iters
	grad = zeros(n,1);
	ll(i)=0;
	H = zeros(n,n);
	for j=1:m
		hxj = sigmoid(X(j,:)*theta);
		grad = grad + X(j,:)'*(Y(j) - hxj);
		H = H - hxj*(1-hxj)*X(j,:)'*X(j,:);
		ll(i) = ll(i) + Y(j)*log(hxj) + (1-Y(j))*log(1-hxj);
	end
	theta = theta - H\grad;
end

end

function a = sigmoid(x)
a = 1./(1+exp(-x));
end
