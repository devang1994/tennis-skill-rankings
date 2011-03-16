
M_count = sum(bsxfun(@eq,dataset(:,1),0:3))',

if exist('Theta_BradleyTerry','var')
	% The Gaussian we use during probit has variance 10 since it is assumed to be the sum of 10 independent unit gaussian player performances.
	% A logit with the same variance would require rescaling the theta values by: sigma^2 = pi^2 s^2 / 3 ==> s = sqrt(3) sigma / pi
	EFFECTIVE_SIGMA = (1 / (sqrt(3*10)/pi));

	% For readability, we'll shift the theta values so that they are centered at zero.
	readable_Theta_BradleyTerry = bsxfun(@minus,Theta_BradleyTerry,median(Theta_BradleyTerry,2))' .* EFFECTIVE_SIGMA;

	disp('');
	disp('');
	disp('===========================================================');
	disp('Bradley-Terry (logit):')
	epsilon_BradleyTerry,
	disp('');
	disp('1pt			3pt		OFFENSIVE PLAYER');
	for n=1:length(names_offense)
		disp([num2str(readable_Theta_BradleyTerry(n,:)) '		' names_offense{n}]);
	end
	disp('');
	disp('1pt			3pt		DEFENSIVE PLAYER');
	for n=1:length(names_defense)
		disp([num2str(readable_Theta_BradleyTerry(length(names_offense)+n,:)) '		' names_defense{n}]);
	end
	
	EFFECTIVE_SIGMA,
end


if exist('Theta_ThurstoneCaseV','var')
	% For readability, we'll shift the theta values so that they are centered at zero.
	readable_Theta_ThurstoneCaseV = bsxfun(@minus,Theta_ThurstoneCaseV,median(Theta_ThurstoneCaseV,2))';

	disp('');
	disp('');
	disp('===========================================================');
	disp('Thurstone Case V (probit):')
	epsilon_ThurstoneCaseV,
	disp('');
	disp('1pt			3pt		OFFENSIVE PLAYER');
	for n=1:length(names_offense)
		disp([num2str(readable_Theta_BradleyTerry(n,:)) '		' names_offense{n}]);
	end
	disp('');
	disp('1pt			3pt		DEFENSIVE PLAYER');
	for n=1:length(names_defense)
		disp([num2str(readable_Theta_BradleyTerry(length(names_offense)+n,:)) '		' names_defense{n}]);
	end
end

