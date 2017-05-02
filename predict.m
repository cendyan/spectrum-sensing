%% Setup

Pfa_target = 5e-3:5e-3:1;
Pd_priori_ind = zeros(length(Pfa_target),length(meanSNR));
Pd_post_ind = zeros(length(Pfa_target),length(meanSNR));
Pd_post_or = zeros(length(Pfa_target),1);
Pd_post_and = zeros(length(Pfa_target),1);
Pd_post_bayes = zeros(length(Pfa_target),1);
Pd_post_gmm = zeros(length(Pfa_target),1);
Pfa_post_ind = zeros(length(Pfa_target),length(meanSNR));
Pfa_post_or = zeros(length(Pfa_target),1);
Pfa_post_and = zeros(length(Pfa_target),1);
Pfa_post_bayes = zeros(length(Pfa_target),1);
Pfa_post_gmm = zeros(length(Pfa_target),1);

%% Analytical Estimators

% Weighted Bayes 
e = 1e-3;
shape = N/2;
scale = 2*ones(size(X,1),1).*(1+meanSNR)';
P_X0_H1 = gamcdf(N*(X+e),shape,scale) - gamcdf(N*(X-e),shape,scale);
P_X0_H0 = chi2cdf((X+e)*N,N) - chi2cdf((X-e)*N,N);
P_H1 = scenario.Pr;
P_H0 = 1-P_H1;
P_H1_X0 = P_X0_H1*P_H1./(P_X0_H0*P_H0 + P_X0_H1*P_H1);
P_H0_X0 = 1-P_H1_X0;
w = meanSNR';

% GMM
mu = [ones(1,length(meanSNR)); ones(1,length(meanSNR)).*(1+meanSNR)'];
sigma = [ones(1,length(meanSNR))*(2*N/N^2) ; ones(1,length(meanSNR)).*(2*N*((1+meanSNR)'.^2)/N^2)];
Sigma(:,:,1) = sigma(1,:);
Sigma(:,:,2) = sigma(2,:);
mixing = [1-scenario.Pr scenario.Pr];
startObj = struct('mu',mu,'Sigma',Sigma,'ComponentProportion',mixing);
options = statset('Display','final');
GM = gmdistribution(mu,Sigma,mixing);
[~,~,P_gmm] = cluster(GM,X);

%% Metrics

for i=1:length(Pfa_target)
    
    alpha = 1-Pfa_target(i); % Regulates the WB Pfa
    beta = alpha; % Regulates the GMM Pfa
    lambda = 2*gammaincinv(Pfa_target(i),N/2,'upper')/N;
    
    % SS Ind
    A_ind = X>=lambda;
    detected_ind = A & A_ind;
    misdetected_ind = logical(A - detected_ind);
    falseAlarm_ind = logical(A_ind - detected_ind);
    available_ind = ~A & ~A_ind;
    
    % SS Coop OR
    A_or = sum(X >= lambda,2) > 0; % SU predictions on channel occupancy (OR rule)
    detected_or = A & A_or;
    misdetected_or = logical(A - detected_or);
    falseAlarm_or = logical(A_or - detected_or);
    available_or = ~A & ~A_or;
    
    % SS Coop AND
    A_and = sum(X >= lambda,2) == size(X,2); % SU predictions on channel occupancy (AND rule)
    detected_and = A & A_and;
    misdetected_and = logical(A - detected_and);
    falseAlarm_and = logical(A_and - detected_and);
    available_and = ~A & ~A_and;
    
    % SS Coop Bayesian
    A_bayes = (sum(P_H1_X0.*w,2)/sum(w))>=alpha;
    detected_bayes = A & A_bayes;
    misdetected_bayes = logical(A - detected_bayes);
    falseAlarm_bayes = logical(A_bayes - detected_bayes);
    available_bayes = ~A & ~A_bayes;
    
    % SS Coop GMM
    A_gmm = P_gmm(:,2)>=beta;
    detected_gmm = A & A_gmm;
    misdetected_gmm = logical(A - detected_gmm);
    falseAlarm_gmm = logical(A_gmm - detected_gmm);
    available_gmm = ~A & ~A_gmm;
    
    % Pd and Pfa to build the ROC curve
    Pd_priori_ind(i,:) = gammainc(N*lambda./(2*(1+meanSNR)), N/2, 'upper');
    Pd_post_ind(i,:) = sum(detected_ind)/sum(A);
    Pd_post_or(i) = sum(detected_or)/sum(A);
    Pd_post_and(i) = sum(detected_and)/sum(A);
    Pd_post_bayes(i) = sum(detected_bayes)/sum(A);
    Pd_post_gmm(i) = sum(detected_gmm)/sum(A);
    Pfa_post_ind(i,:) = sum(falseAlarm_ind)/(length(A)-sum(A));
    Pfa_post_or(i) = sum(falseAlarm_or)/(length(A)-sum(A));
    Pfa_post_and(i) = sum(falseAlarm_and)/(length(A)-sum(A));
    Pfa_post_bayes(i) = sum(falseAlarm_bayes)/(length(A)-sum(A));
    Pfa_post_gmm(i) = sum(falseAlarm_gmm)/(length(A)-sum(A));
    
end
