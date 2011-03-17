% After running:
%    $sh createdata.threeteam.sh.bat
clear all; MAX_ITER = 500

USE_GAUSSIAN = true;
SIGMA = sqrt(10),


%===============
%   LOAD DATA
%===============


cd threeteam.training
loaddata_train; % MATLAB pre-parses scripts by name, so the two loaddata calls need to have their own name
training_data = dataset;
training_players = player_names;
clear dataset player_names;
cd ..

cd threeteam.test
loaddata_test;
test_dataset = dataset;
test_players = player_names;
clear dataset player_names;
cd ..



training_players,
test_players,

% There are only two teams in the test set. Which columns of trained.Theta are these?
in_test = false(1,length(training_players)*2);
for indxTest = 1:length(test_players)
	search_for_name = test_players(indxTest);
	found_columns = repmat(strcmp(search_for_name,training_players),[1 2]); % repmat because if the player is there we want their offense and defense
	in_test = in_test | found_columns;
	
	if nnz(found_columns) ~= 2
		search_for_name,
		keyboard
	end
end


nnz(in_test)/2,
assert(nnz(in_test) == length(test_players)*2)

%==============
%   TRAINING
%==============


trained = basketball_network_EM(training_data, MAX_ITER, USE_GAUSSIAN, 'E');




M_count = sum(bsxfun(@eq,training_data(:,1),0:3))',
players = struct('M', sum(M_count), 'possessions', sum(training_data(:,2:end))');
players.names = training_players;

display_output(players, trained, 'Training result', USE_GAUSSIAN);

%================
%   PREDICTION
%================

E_D_schedule = logical([
	0 0 0; % k=1 --> Lose1, Lose2, Lose3 ==> R=0
        1 0 0; % k=2 --> Win1 , Lose2, Lose3 ==> R=1
        0 1 0; % k=3 --> Lose1, Win2 , Lose3 ==> R=2
        1 1 0; %  .                          ==> R=2
        0 0 1; %  .                          ==> R=3
        1 0 1; %  .                          ==> R=3
        0 1 1; % k=7 --> Lose1, Win2 , Win3  ==> R=3
        1 1 1;])%k=8 --> Win1 , Win2 , Win3  ==> R=3

% E_R_schedule = [
	% 6*trained.epsilon;                        % k=1 --> R=0 ==> E[R] = 0*(1-epsilon) + (1+2+3)*epsilon
        % 1-trained.epsilon + 5*trained.epsilon;    % k=2 --> R=1 ==> E[R] = 1*(1-epsilon) + (0+2+3)*epsilon
        % 2*(1-trained.epsilon) + 4*trained.epsilon;% k=3 --> R=2 ==> E[R] = 2*(1-epsilon) + (0+1+3)*epsilon
        % 2*(1-trained.epsilon) + 4*trained.epsilon;% ...
        % 3*(1-trained.epsilon) + 3*trained.epsilon;% k=5 --> R=3 ==> E[R] = 3*(1-epsilon) + (0+1+2)*epsilon
        % 3*(1-trained.epsilon) + 3*trained.epsilon;% ...
        % 3*(1-trained.epsilon) + 3*trained.epsilon;% ...
        % 3*(1-trained.epsilon) + 3*trained.epsilon])%...

epsilon = trained.epsilon;
R_schedule = [
	(1-3*epsilon) epsilon epsilon epsilon;
	epsilon (1-3*epsilon) epsilon epsilon;
	epsilon epsilon (1-3*epsilon) epsilon;
	epsilon epsilon (1-3*epsilon) epsilon;
	epsilon epsilon epsilon (1-3*epsilon);
	epsilon epsilon epsilon (1-3*epsilon);
	epsilon epsilon epsilon (1-3*epsilon);
	epsilon epsilon epsilon (1-3*epsilon)];


% Now sample from Pr{R|c} assuming epsilon = 0
M = size(test_dataset,1);
R_softassignments = nan(M,4);
R_samples = nan(M,1);
for m=1:M
	
		% Each datapoint has different C values (dataset(m,2:end)) so they will have different W1 W2 and W3
		if USE_GAUSSIAN
			W1 = normcdf(trained.Theta(1,in_test)*test_dataset(m,2:end)',0,SIGMA);
			W2 = normcdf(trained.Theta(2,in_test)*test_dataset(m,2:end)',0,SIGMA);
			W3 = normcdf(trained.Theta(3,in_test)*test_dataset(m,2:end)',0,SIGMA);
		else
			W1 = sigmoid(trained.Theta(1,in_test)*test_dataset(m,2:end)');
			W2 = sigmoid(trained.Theta(2,in_test)*test_dataset(m,2:end)');
			W3 = sigmoid(trained.Theta(3,in_test)*test_dataset(m,2:end)');
		end

		W_soft = [W1 W2 W3];
		% Compute Pr{w|c}
		pr_w_c = nan(4,8); % initialize to NaN in order to catch typos
		for k=1:8
			wins   = W_soft( E_D_schedule(k,:))     ;
			losses = 1 - W_soft(~E_D_schedule(k,:)) ;
			%I like this assertion but it eats up runtime %assert(numel([wins, losses]) == 3)
			pr_w_c(:,k) = prod([wins, losses]);
		end
		soft_assignments = R_schedule' .* pr_w_c; %elementwise
		
		p = sum(soft_assignments,2);
		p = p / sum(p); % a column vector
		
		R_softassignments(m,:) = p;
		R_samples(m) = randsample_fromweights(0:3,R_softassignments(m,:));
	end

%================
%   COMPARISON
%================

if USE_GAUSSIAN
	disp('=== Gaussian ===')
else
	disp('=== Logistic ===')
end

prediction_histogram = sum(R_softassignments)',
prediction_ppp = (0:3) * prediction_histogram,

sample_histogram = test_histogram = sum(bsxfun(@eq,R_samples,0:3))',
sample_ppp = (0:3) * sample_histogram,

test_histogram = sum(bsxfun(@eq,test_dataset(:,1),0:3))',
test_ppp = (0:3) * test_histogram,
