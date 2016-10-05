function [badEpochIdx_var, badEpochIdx_kur, badEpochIdx_skew] = hl_trialvariance(dataMatrix, var_b, kur_b, skew_b)

%% Check required inputs
if size(dataMatrix,2) ~= 157
    error('check data matrix dimension: time x channels x epoch')
end
if exist('var_ub','var') == 0
    var_b = 2;
end
if exist('kur_ub','var') == 0
    kur_b = 2;
end
if exist('skew_b','var') == 0
    skew_b = 2;
end

nt     = size(dataMatrix,1);
nepoch = size(dataMatrix,3);

fprintf('Computing variace \n')
trial_dataMatrix = reshape(dataMatrix, nt*157, nepoch);
trial_var        = nanvar(trial_dataMatrix,1);
var_ub           = mean(trial_var) + std(trial_var)*var_b;
var_lb           = mean(trial_var) - std(trial_var)*var_b;
badEpochIdx_var  = trial_var >= var_ub | trial_var <= var_lb;

fprintf('Computing kurtosis \n')
trial_kur        = kurtosis(trial_dataMatrix,1);
kur_ub        = mean(trial_kur) + std(trial_kur)*kur_b;
kur_lb        = mean(trial_kur) - std(trial_kur)*kur_b;
badEpochIdx_kur  = trial_kur >= kur_ub | trial_kur <= kur_lb;

fprintf('Computing skewness \n')
trial_skew       = skewness(trial_dataMatrix,1);
skew_ub          = mean(trial_skew) + std(trial_skew)*skew_b;
skew_lb          = mean(trial_skew) - std(trial_skew)*skew_b;
badEpochIdx_skew = trial_skew >= skew_ub | trial_skew <= skew_lb;

cpsFigure(1,.8); set(gca, 'FontSize', 20); hold on;
plot(trial_var,'bo');
plot(find(badEpochIdx_var), trial_var(badEpochIdx_var),'ro')
plot([1 nepoch], [var_ub var_ub], 'k--',[1 nepoch], [var_lb var_lb], 'k--');
xlim([1 nepoch])
xlabel('Epochs')
ylabel('Variance')
badpercentage = sum(badEpochIdx_var) / nepoch*100;
disp(['bad epochs ',num2str(find(badEpochIdx_var))]);
fprintf('%2.2f percentage of epochs marked as bad by variance \n',badpercentage);

cpsFigure(1,.8); set(gca, 'FontSize', 20); hold on;
plot(trial_kur,'bo');
plot(find(badEpochIdx_kur), trial_kur(badEpochIdx_kur),'ro')
plot([1 nepoch], [kur_ub kur_ub], 'k--',[1 nepoch], [kur_lb kur_lb], 'k--');
xlim([1 nepoch])
xlabel('Epochs')
ylabel('Kurtosis')
badpercentage = sum(badEpochIdx_kur) / nepoch*100;
disp(['bad epochs ',num2str(find(badEpochIdx_kur))]);
fprintf('%2.2f percentage of epochs marked as bad by kurtosis \n',badpercentage);

cpsFigure(1,.8); set(gca, 'FontSize', 20); hold on;
plot(trial_skew,'bo');
plot(find(badEpochIdx_skew), trial_skew(badEpochIdx_skew),'ro')
plot([1 nepoch], [skew_ub skew_ub], 'k--', [1 nepoch], [skew_lb skew_lb], 'k--');
xlim([1 nepoch])
xlabel('Epochs')
ylabel('Skewness')
badpercentage = sum(badEpochIdx_skew) / nepoch*100;
disp(['bad epochs ',num2str(find(badEpochIdx_skew))]);
fprintf('%2.2f percentage of epochs marked as bad by skewness \n',badpercentage);
