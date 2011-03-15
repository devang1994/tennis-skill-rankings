% CS228 Final Project
% Ryan Thompson, Joseph Huang, Leland Chen
% thompsor@stanford.edu
% Adapted from:
%   CS228 PA3 Winter 2011
%   Copyright (C) 2011, Stanford University
%   contact: Huayan Wang, huayanw@cs.stanford.edu

function [Theta sigma] = MLE_Gaussian(X, U)

% Note that Matlab index from 1, we can't write Theta(0). So Theta(K+1) is
% essentially Theta(0) in PA3 description (and the text book).

% X: (N x 1), W_i values, one for each of N data points
% U: (N x K), K on-court parameters. 1 means offense, -1 defense, 0 off-court

N = size(U,1);
K = size(U,2);

Theta = zeros(K+1,1);
sigma = 1;

% collect expectations and solve the linear system
% A = [ E[U(1)],      E[U(2)],      ... , E[U(K)],      1     ; 
%       E[U(1)*U(1)], E[U(2)*U(1)], ... , E[U(K)*U(1)], E[U(1);
%       ...         , ...         , ... , ...         , ...   ;
%       E[U(1)*U(K)], E[U(2)*U(K)], ... , E[U(K)*U(K)], E[U(K)] ]

% B = [ E[X]; E[X*U(1)]; ... ; E[X*U(K)] ]

% solve A*Theta = B
% then compute sigma according to eq. (17) in CS228-PA3 description

A = zeros(K+1,K+1);
B = zeros(K+1,1);
A(1,K+1) = 1;
for i = 1:N
	for j = 2:K+1
		for k = 1:K
			A(j,k) = A(j,k) + U(i,j-1)*U(i,k);
		end
	end
	B(1) = B(1) + X(i);
	for j = 1:K
		A(1,j) = A(1,j) + U(i,j);
		A(j+1,K+1) = A(1,j);
		B(j+1) = B(j+1) + X(i)*U(i,j);
	end
end

Theta = pinv(A)*B;

mu = sum(X);
var = X'*X;
sX = sqrt(var - mu*mu);

covU = 0;
for i = 1:K
	for j = 1:K
		covU = covU + Theta(i)*Theta(j)*(A(j+1,i)-A(1,i)*A(1,j));
	end
end

sigma = sqrt(sX*sX-covU);
Theta = [Theta(K+1); Theta(1:K)];
