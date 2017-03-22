function [badEpochIdx_var, badEpochIdx_kur, badEpochIdx_skew] = hl_trialvariance(dataMatrix, var_b, kur_b, skew_b)
%keyboard;
%% Check required inputs
if size(dataMatrix,2) ~= 157
    error('check data matrix dimension: time x channels x epoch')
end
if exist('var_b','var') == 0
    var_b = 2;
end
if exist('kur_b','var') == 0
    kur_b = 2;
end
if exist('skew_b','var') == 0
    skew_b = 2;
end

nt     = size(dataMatrix,1);
nepoch = size(dataMatrix,3);

fprintf('Computing variace \n')
trial_dataMatrix = reshape(dataMatrix, nt*157, nepoch);
tempMat          = trial_dataMatrix;
trial_var        = nanvar(tempMat,1);
var_ub           = nanmean(trial_var) + nanstd(trial_var)*var_b;
var_lb           = nanmean(trial_var) - nanstd(trial_var)*var_b;
badEpochIdx_var_1round  = trial_var >= var_ub | trial_var <= var_lb;
tempMat(:,badEpochIdx_var_1round) = nan;
trial_var        = nanvar(tempMat,1);
var_ub           = nanmean(trial_var) + nanstd(trial_var)*var_b;
var_lb           = nanmean(trial_var) - nanstd(trial_var)*var_b;
badEpochIdx_var_2round  = trial_var >= var_ub | trial_var <= var_lb;
badEpochIdx_var = badEpochIdx_var_1round | badEpochIdx_var_2round;

fprintf('Computing kurtosis \n')
tempMat       = trial_dataMatrix;
trial_kur     = kurtosis(tempMat,1);
kur_ub        = nanmean(trial_kur) + nanstd(trial_kur)*kur_b;
kur_lb        = nanmean(trial_kur) - nanstd(trial_kur)*kur_b;
badEpochIdx_kur_1round  = trial_kur >= kur_ub | trial_kur <= kur_lb;
tempMat(:,badEpochIdx_kur_1round) = nan;
trial_kur        = kurtosis(tempMat,1);
kur_ub           = nanmean(trial_kur) + nanstd(trial_kur)*kur_b;
kur_lb           = nanmean(trial_kur) - nanstd(trial_kur)*kur_b;
badEpochIdx_kur_2round  = trial_kur >= kur_ub | trial_kur <= kur_lb;
badEpochIdx_kur = badEpochIdx_kur_1round | badEpochIdx_kur_2round;

fprintf('Computing skewness \n')
tempMat       = trial_dataMatrix;
trial_skew       = skewness(tempMat,1);
skew_ub          = nanmean(trial_skew) + nanstd(trial_skew)*skew_b;
skew_lb          = nanmean(trial_skew) - nanstd(trial_skew)*skew_b;
badEpochIdx_skew_1round = trial_skew >= skew_ub | trial_skew <= skew_lb;
tempMat(:,badEpochIdx_skew_1round) = nan;
trial_skew        = skewness(tempMat,1);
skew_ub           = nanmean(trial_skew) + nanstd(trial_skew)*skew_b;
skew_lb           = nanmean(trial_skew) - nanstd(trial_skew)*skew_b;
badEpochIdx_skew_2round  = trial_skew >= skew_ub | trial_skew <= skew_lb;
badEpochIdx_skew = badEpochIdx_skew_1round | badEpochIdx_skew_2round;

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
