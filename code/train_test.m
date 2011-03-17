% After running:
%   $python ../data/build_dataset.py ../data/raw/20070204.DETCLE.csv
clear all; loaddata; MAX_ITER = 500

M = size(dataset,1);
gaussian = false;

if gaussian
	[Theta_ThurstoneCaseV loglikelihood_ThurstoneCaseV epsilon_ThurstoneCaseV] = basketball_network_EM(dataset([mod(1:M,4) ~= 0],:), MAX_ITER, true);
else
	[Theta_BradleyTerry loglikelihood_BradleyTerry epsilon_BradleyTerry] = basketball_network_EM(dataset([mod(1:M,4) ~= 0],:), MAX_ITER, false);

%display_output_all

test_data = dataset([mod(1:M,4) == 0],:);

if gaussian
	SIGMA = sqrt(10),
end

if gaussian
	Theta = Theta_ThurstoneCaseV;
	epsilon = epsilon_ThurstoneCaseV;
else
	Theta = Theta_BradleyTerry;
	epsilon = epsilon_BradleyTerry;
end

E_D = nan(size(test_data,1),8);
E_D_schedule = logical([
	0 0 0; % k=1 --> Lose1, Lose2, Lose3 ==> R=0
        1 0 0; % k=2 --> Win1 , Lose2, Lose3 ==> R=1
        0 1 0; % k=3 --> Lose1, Win2 , Lose3 ==> R=2
        1 1 0; %  .                          ==> R=2
        0 0 1; %  .                          ==> R=3
        1 0 1; %  .                          ==> R=3
        0 1 1; % k=7 --> Lose1, Win2 , Win3  ==> R=3
        1 1 1;])%k=8 --> Win1 , Win2 , Win3  ==> R=3

	R_schedule = [
		(1-3*epsilon) epsilon epsilon epsilon;
		epsilon (1-3*epsilon) epsilon epsilon;
		epsilon epsilon (1-3*epsilon) epsilon;
		epsilon epsilon (1-3*epsilon) epsilon;
		epsilon epsilon epsilon (1-3*epsilon);
		epsilon epsilon epsilon (1-3*epsilon);
		epsilon epsilon epsilon (1-3*epsilon);
		epsilon epsilon epsilon (1-3*epsilon)];

for q = 1:1000
for m = 1:size(test_data,1)
		% Each datapoint has different C values (dataset(m,2:end)) so they will have different W1 W2 and W3
		if gaussian
			W1 = normcdf(Theta(1,:)*test_data(m,2:end)',0,SIGMA);
			W2 = normcdf(Theta(2,:)*test_data(m,2:end)',0,SIGMA);
			W3 = normcdf(Theta(3,:)*test_data(m,2:end)',0,SIGMA);
		else
			W1 = sigmoid(Theta(1,:)*test_data(m,2:end)');
			W2 = sigmoid(Theta(2,:)*test_data(m,2:end)');
			W3 = sigmoid(Theta(3,:)*test_data(m,2:end)');
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
		
		%Make the assignments
		% soft_assignments unnormalized represents Pr{r|w}Pr{w|c}Pr{c} (but Pr{c} is uniform so we ignore it)
		soft_assignments = R_schedule' .* pr_w_c;
		sample = rand;
		p = sum(soft_assignments,2);
		if sample > p(1)
			sample = sample - p(1);
			if sample > p(2)
				sample = sample - p(2);
				if sample > p(3)
					b = 4;
				else
					b = 3;
				end
			else
				b = 2;
			end
		else
			b = 1;
		end
		% Normalize (divide out Pr{r,c} = \sum_w Pr{r,w,c})
		E_D(m,:) = soft_assignments(b,:)' / sum(soft_assignments(b,:));
		R(m,1) = b-1;
		%keyboard;
end

E(q) = norm(R);
E2(q) = sum(R);
end
mean(E)
norm(test_data(:,1))
std(E)
mean(E2)
sum(test_data(:,1))
std(E2)
