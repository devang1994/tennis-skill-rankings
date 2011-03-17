
% PRINT OUTPUT
M_count = sum(bsxfun(@eq,dataset(:,1),0:3))',

if exist('BradleyTerry_parameters','var')
	display_output(player_names, BradleyTerry_parameters, 'Bradley-Terry (logit) parameter initialization:', sum(M_count), false);
end

if exist('ThurstoneCaseV_parameters','var')
	display_output(player_names, ThurstoneCaseV_parameters, 'Thurstone Case V (probit) parameter initialization:', sum(M_count), true);
end

if exist('BradleyTerry_softassignments','var')
	display_output(player_names, BradleyTerry_softassignments, 'Bradley-Terry (logit) soft-assignment initialization:', sum(M_count), false);
end

if exist('ThurstoneCaseV_softassignments','var')
	display_output(player_names, ThurstoneCaseV_softassignments, 'Thurstone Case V (probit) soft-assignment initialization:', sum(M_count), true);
end

