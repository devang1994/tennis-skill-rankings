% After running:
%   $python ../data/build_dataset.py ../data/raw/20070204.DETCLE.csv
clear all

loaddata

MAX_ITER = 500

%dbclear all
[Theta_BradleyTerry loglikelihood_BradleyTerry epsilon_BradleyTerry] = basketball_network_EM(dataset, MAX_ITER, false);
%dbclear all
%  I don't think this is exactly what we want, I'll look over the math in a bit. -- Joseph
%[Theta_ThurstoneCaseV loglikelihood_ThurstoneCaseV epsilon] = basketball_network_EM(dataset, MAX_ITER, true)

% For readability, we'll shift the theta values so that they are centered at zero.
readable_Theta_BradleyTerry = bsxfun(@minus,Theta_BradleyTerry,median(Theta_BradleyTerry,2))';

disp('');
disp('');
disp('===========================================================');
disp('Bradley-Terry:')
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
