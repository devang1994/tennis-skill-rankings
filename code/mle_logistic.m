function [theta,ll] = log_regression(X,Y)
% rows of Y are estimated probabilities for W_i(x)
% with H = hessian, grad = gradient

X = [ones(size(X,1),1) X];
n = size(X,2);

for i=1:max_iters
	ll(i)=0;
	H = zeros(n,n);
	for j=1:m
		grad = grad + X(j,:)’*(Y(j) - hxj);
		H = H - hxj*(1-hxj)*X(j,:)’*X(j,:);
		ll(i) = ll(i) + Y(j)*log(hxj) + (1-Y(j))*log(1-hxj);
end
end;

function a = sigmoid(x)
end