
SIGMA = sqrt(10),

% PRINT OUTPUT
M_count = sum(bsxfun(@eq,dataset(:,1),0:3))',

M = sum(M_count);
logistic_average = (log(M_count(2:4)) - log(M-M_count(2:4)))/10 * (1 / (sqrt(3) * SIGMA/pi));
gaussian_average = norminv(M_count(2:4)/M,0,SIGMA)/10;

disp('League averages:')
disp(['  LOGISTIC  ' num2str(logistic_average')])
disp(['  GAUSSIAN  ' num2str(gaussian_average')])


players = struct('M', M, 'possessions', sum(dataset(:,2:end))');
players.names = player_names;

disp('Table of Contents')
disp('  LOGISTIC/logit')
disp('    Choose E_D soft-assignment, start with E-step  ll = @@@@@@@@@@, epsilon = @@@@@@@@@@')
disp('    Choose parameter values, start with M-step     ll = @@@@@@@@@@, epsilon = @@@@@@@@@@')
disp('  GAUSSIAN/probit')
disp('    Choose E_D soft-assignment, start with E-step  ll = @@@@@@@@@@, epsilon = @@@@@@@@@@')
disp('    Choose parameter values, start with M-step     ll = @@@@@@@@@@, epsilon = @@@@@@@@@@')


if exist('BradleyTerry_softassignments','var')
	display_output(players, BradleyTerry_softassignments, 'Bradley-Terry (logit) soft-assignment initialization:', false);
end
if exist('BradleyTerry_parameters','var')
	display_output(players, BradleyTerry_parameters, 'Bradley-Terry (logit) parameter initialization:', false);
end

if exist('ThurstoneCaseV_softassignments','var')
	display_output(players, ThurstoneCaseV_softassignments, 'Thurstone Case V (probit) soft-assignment initialization:', true);
end
if exist('ThurstoneCaseV_parameters','var')
	display_output(players, ThurstoneCaseV_parameters, 'Thurstone Case V (probit) parameter initialization:', true);
end



